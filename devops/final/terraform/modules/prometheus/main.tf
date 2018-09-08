# Prometheus instance
resource "aws_instance" "prometheus" {
  ami = "${var.AMIS}"
  instance_type = "t2.small"
  key_name = "${var.KEY_NAME}"
  count = 1
  vpc_security_group_ids = ["${var.SECURITY_GROUP_ID}"]
  subnet_id = "${var.SUBNET}"
  associate_public_ip_address = true
  tags {
    Name = "prometheus-${var.SUBNET_NUM}"
    Environment = "dev"
    Terraform = "true"
  } 
}

# Configure prometheus
resource "null_resource" "prometheus" {

  # Establish connection to worker
  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${aws_instance.prometheus.public_ip}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }

  # We need the prometheus instance first
  depends_on = [ "aws_instance.prometheus" ]

  # Provision the Prometheus configuration script
  provisioner "file" {
    source = "${path.module}/scripts/full_prometheus_setup.sh"
    destination = "/tmp/full_prometheus_setup.sh"
  }

  # Execute Prometheus configuration script remotely
  provisioner "remote-exec" {
    inline = [
      "echo \"export AWS_ACCESS_KEY_ID='${var.AWS_ACCESS_KEY}'\nexport AWS_SECRET_ACCESS_KEY='${var.AWS_SECRET_KEY}'\nexport AWS_DEFAULT_REGION='${var.AWS_REGION}'\" >> ~/.profile",
      "chmod +x /tmp/full_prometheus_setup.sh",
      "bash /tmp/full_prometheus_setup.sh '${var.AWS_ACCESS_KEY}' '${var.AWS_SECRET_KEY}' '${var.AWS_REGION}' '${var.SUBNET_NUM}'",
    ]
  }
}

# Provision Grafana
resource "null_resource" "grafana" {

  # Establish connection to worker
  connection {
    type = "ssh"
    user = "ubuntu"    
    host = "${aws_instance.prometheus.public_ip}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }

  # We need Prometheus and Grafana installed first
  depends_on = [ "null_resource.prometheus" ]

  # Provision the Grafana datasource file
  provisioner "file" {
    source = "${path.module}/scripts/datasource-prometheus.yaml"
    destination = "/tmp/datasource-prometheus.yaml"
  }

  # Provision the Grafana dashboard file
  provisioner "file" {
    source = "${path.module}/scripts/dashboards.yaml"
    destination = "/tmp/dashboards.yaml"
  }

  # Provision the Grafana dashboard JSON file
  provisioner "file" {
    source = "${path.module}/scripts/dashboards.json"
    destination = "/tmp/dashboards.json"
  }

  # Move Grafana remotely
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/datasource-prometheus.yaml /etc/grafana/provisioning/datasources/",
      "sudo mv /tmp/dashboards.yaml /etc/grafana/provisioning/dashboards/",
      "sudo mkdir /var/lib/grafana/dashboards",
      "sudo mv /tmp/dashboards.json /var/lib/grafana/dashboards/",
      "sudo systemctl restart grafana-server.service",
    ]
  }
}
