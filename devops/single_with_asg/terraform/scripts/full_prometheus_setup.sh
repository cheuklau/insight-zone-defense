#!/bin/bash

AWS_ACCESS_KEY=$1
AWS_SECRET_KEY=$2
AWS_REGION=$3
PROMETHEUS_VERSION="2.2.1"
NODE_EXPORTER_VERSION="0.16.0"

sudo su <<HERE

##################################################
# Download and install Prometheus
##################################################

# Download prometheus
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar -xzvf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROMETHEUS_VERSION}.linux-amd64/

# Create user
useradd --no-create-home --shell /bin/false prometheus 

# Create directories
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus

# Set ownership
chown prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /var/lib/prometheus

# Copy binaries
cp prometheus /usr/local/bin/
cp promtool /usr/local/bin/

# Set permissions
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

# Copy config
cp -r consoles /etc/prometheus
cp -r console_libraries /etc/prometheus
cp prometheus.yml /etc/prometheus/prometheus.yml

# Set permissions
chown -R prometheus:prometheus /etc/prometheus/consoles
chown -R prometheus:prometheus /etc/prometheus/console_libraries

# Setup systemd
echo '[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/prometheus.service

# Start service
systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus

##################################################
# Download and install Grafana
##################################################

# Download and install Grafana
echo 'deb https://packagecloud.io/grafana/stable/debian/ jessie main' >> /etc/apt/sources.list
curl https://packagecloud.io/gpg.key | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install grafana

# Start service
systemctl daemon-reload
systemctl start grafana-server
systemctl enable grafana-server.service

##################################################
# Download and install Node Exporter
##################################################

# Download and install Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xzvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cd node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64
cp node_exporter /usr/local/bin

# Create user
useradd --no-create-home --shell /bin/false node_exporter

# Change ownership
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Write service
echo '[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/node_exporter.service

# Enable node_exporter in systemctl
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

# Add to Prometheus config file
echo "  
  - job_name: 'node_exporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9100']" >> /etc/prometheus/prometheus.yml

echo "
  - job_name: 'ec2_nodes'
    ec2_sd_configs:
      - region: ${AWS_REGION}
        access_key: ${AWS_ACCESS_KEY}
        secret_key: ${AWS_SECRET_KEY}
        port: 9100
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        regex: flask.*
        action: keep
      - source_labels: [__meta_ec2_instance_id]
        target_label: instance "  >> /etc/prometheus/prometheus.yml

systemctl restart prometheus.service
HERE