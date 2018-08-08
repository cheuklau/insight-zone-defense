#!/bin/bash

# Update package manager and get tree package
sudo apt-get update
sudo apt-get install -y tree

# Setup a download and installation directory
HOME_DIR='/home/ubuntu'
INSTALLATION_DIR='/usr/local'
sudo mkdir ${HOME_DIR}/Downloads

# Install Java Development Kit
sudo apt-get install -y openjdk-8-jdk

# Install Python and Boto
sudo apt-get install -y python-pip python-dev build-essential
sudo pip install boto
sudo pip install boto3

# Install Flask
sudo pip install flask

# Install dependencies
sudo pip install googlemaps
sudo pip install flask_sqlalchemy
sudo pip install configparser
sudo pip install psycopg2

# Install gunicorn
sudo pip install gunicorn

# Install Git and clone repository
sudo apt-get install git-core
git clone https://github.com/cheuklau/insight_devops_airaware.git

# Download and install Prometheus and Node Exporter
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

# if you just want to start prometheus as root
#./prometheus --config.file=prometheus.yml

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
# Download and install node exporter
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
HERE
