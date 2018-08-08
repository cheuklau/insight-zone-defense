/*

instance.tf

This file creates our instances.
todo: tighter VPC and subnet definitions for each instance.

*/

##############################################
# Prometheus
##############################################

resource "aws_instance" "prometheus" {
  ami = "${lookup(var.AMIS, "ubuntu")}" 
  instance_type = "t2.small"
  key_name = "${aws_key_pair.mykeypair.key_name}"
  count = 1
  vpc_security_group_ids = ["${aws_security_group.open-security-group.id}"]
  subnet_id = "${aws_subnet.main-public.id}"
  associate_public_ip_address = true
  tags {
    Name = "prometheus"
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
  # We don't need other instances up first because we are using EC2 service discovery
  depends_on = [ "aws_instance.prometheus" ]

  # Provision the Prometheus configuration script
  provisioner "file" {
    source = "scripts/full_prometheus_setup.sh"
    destination = "/tmp/full_prometheus_setup.sh"
  }

  # Execute Prometheus configuration script remotely
  provisioner "remote-exec" {
    inline = [
      "echo \"export AWS_ACCESS_KEY_ID='${var.AWS_ACCESS_KEY}'\nexport AWS_SECRET_ACCESS_KEY='${var.AWS_SECRET_KEY}'\nexport AWS_DEFAULT_REGION='${var.AWS_REGION}'\" >> ~/.profile",
      "chmod +x /tmp/full_prometheus_setup.sh",
      "bash /tmp/full_prometheus_setup.sh '${var.AWS_ACCESS_KEY}' '${var.AWS_SECRET_KEY}' '${var.AWS_REGION}' ",
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
    source = "scripts/datasource-prometheus.yaml"
    destination = "/tmp/datasource-prometheus.yaml"
  }

  # Provision the Grafana dashboard file
  provisioner "file" {
    source = "scripts/dashboards.yaml"
    destination = "/tmp/dashboards.yaml"
  }

  # Provision the Grafana dashboard JSON file
  provisioner "file" {
    source = "scripts/dashboards.json"
    destination = "/tmp/dashboards.json"
  }

  # Move Grafina remotely
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

##############################################
# Postgres
##############################################

resource "aws_instance" "postgres" {
  ami = "${lookup(var.AMIS, "postgres")}"
  instance_type = "m4.large"
  key_name = "${aws_key_pair.mykeypair.key_name}"
  count = 1
  vpc_security_group_ids = ["${aws_security_group.open-security-group.id}"]
  subnet_id = "${aws_subnet.main-public.id}"
  associate_public_ip_address = true
  root_block_device {
    volume_size = 100
    volume_type = "standard"
  }
  tags {
    Name = "postgres"
    Environment = "dev"
    Terraform = "true"
  } 
}

# ##############################################
# # Spark
# ##############################################

# Master 
resource "aws_instance" "spark-master" {
  ami = "${lookup(var.AMIS, "spark")}"
  instance_type = "m4.large"
  key_name = "${aws_key_pair.mykeypair.key_name}"
  count = 1
  vpc_security_group_ids = ["${aws_security_group.open-security-group.id}"] # Change later to private
  subnet_id = "${aws_subnet.main-public.id}" # Change later to private
  associate_public_ip_address = true # Change later to false
  root_block_device {
    volume_size = 100
    volume_type = "standard"
  }
  tags {
    Name = "spark-master"
    Environment = "dev"
    Terraform = "true"
    Cluster = "spark"
    ClusterRole = "master"
  }
}

# Workers
resource "aws_instance" "spark-worker" {
  ami = "${lookup(var.AMIS, "spark")}"
  instance_type = "m4.large"
  key_name = "${aws_key_pair.mykeypair.key_name}"
  count = "${var.NUM_WORKERS}"
  vpc_security_group_ids = ["${aws_security_group.open-security-group.id}"]
  subnet_id = "${aws_subnet.main-public.id}"
  associate_public_ip_address = true
  root_block_device {
    volume_size = 100
    volume_type = "standard"
  }
  tags {
    Name = "spark-worker-${count.index}"
    Environment = "dev"
    Terraform = "true"
    Cluster = "spark"
    ClusterRole = "worker"
  }
}

# Configure workers
resource "null_resource" "spark-worker" {

  count = "${var.NUM_WORKERS}"

  # Establish connection to worker
  connection {
    type = "ssh"
    user = "ubuntu"    
    host = "${element(aws_instance.spark-worker.*.public_ip, "${count.index}")}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }

  # We need the master and slaves spun up first
  depends_on = [ "aws_instance.spark-master", "aws_instance.spark-worker" ]

  # Provision the Hadoop configuration script
  provisioner "file" {
    source = "scripts/hadoop_setup_single.sh"
    destination = "/tmp/hadoop_setup_single.sh"
  }

  # Provision the Hadoop configuration script
  provisioner "file" {
    source = "scripts/hadoop_config_datanode.sh"
    destination = "/tmp/hadoop_config_datanode.sh"
  }

  # Provision the Spark setup script
  provisioner "file" {
    source = "scripts/spark_setup_single.sh"
    destination = "/tmp/spark_setup_single.sh"
  }

  # Execute spark configuration script remotely
  provisioner "remote-exec" {
    inline = [
      "echo \"export AWS_ACCESS_KEY_ID='${var.AWS_ACCESS_KEY}'\nexport AWS_SECRET_ACCESS_KEY='${var.AWS_SECRET_KEY}'\nexport AWS_DEFAULT_REGION='${var.AWS_REGION}'\" >> ~/.profile",
      "chmod +x /tmp/hadoop_setup_single.sh",
      "bash /tmp/hadoop_setup_single.sh '${aws_instance.spark-master.public_dns}' '${var.AWS_ACCESS_KEY}' '${var.AWS_SECRET_KEY}'",
      "chmod +x /tmp/hadoop_config_datanode.sh",
      "bash /tmp/hadoop_config_datanode.sh",
      "chmod +x /tmp/spark_setup_single.sh",
      "bash /tmp/spark_setup_single.sh '${element(aws_instance.spark-worker.*.public_dns, "${count.index}")}'",
    ]
  }
}

# Configure master
resource "null_resource" "spark-master" {

  # Establish connection to master
  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${aws_instance.spark-master.public_ip}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }

  # We need the slaves configured first
  depends_on = [ "null_resource.spark-worker" ]

  # Provision the SSH configuration script
  provisioner "file" {
    source = "scripts/setup_ssh.sh"
    destination = "/tmp/setup_ssh.sh"
  }

  # Provision the Host configuration script
  provisioner "file" {
    source = "scripts/add_to_known_hosts.sh"
    destination = "/tmp/add_to_known_hosts.sh"
  }

  # Provision the Hadoop setup script
  provisioner "file" {
    source = "scripts/hadoop_setup_single.sh"
    destination = "/tmp/hadoop_setup_single.sh"
  }

  # Provision the Hadoop setup script
  provisioner "file" {
    source = "scripts/hadoop_config_hosts.sh"
    destination = "/tmp/hadoop_config_hosts.sh"
  }

  # Provision the Hadoop setup script
  provisioner "file" {
    source = "scripts/hadoop_config_namenode.sh"
    destination = "/tmp/hadoop_config_namenode.sh"
  }

  # Provision the Hadoop setup script
  provisioner "file" {
    source = "scripts/hadoop_format_hdfs.sh"
    destination = "/tmp/hadoop_format_hdfs.sh"
  }

  # Provision the Spark setup script
  provisioner "file" {
    source = "scripts/spark_setup_single.sh"
    destination = "/tmp/spark_setup_single.sh"
  }

  # Provision the Spark setup script
  provisioner "file" {
    source = "scripts/spark_configure_worker.sh"
    destination = "/tmp/spark_configure_worker.sh"
  }

  # Provision the Hadoop start script
  provisioner "file" {
    source = "scripts/hadoop_start.sh"
    destination = "/tmp/hadoop_start.sh"
  }

  # Provision the Spark start script
  provisioner "file" {
    source = "scripts/spark_start.sh"
    destination = "/tmp/spark_start.sh"
  }

  provisioner "file" {
    source = "${var.PATH_TO_PRIVATE_KEY}"
    destination = "/tmp/${aws_key_pair.mykeypair.key_name}"
  }

  # Provision 
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup_ssh.sh",
      "bash /tmp/setup_ssh.sh '${aws_key_pair.mykeypair.key_name}' '${join("' '", "${aws_instance.spark-worker.*.public_dns}")}'",
      "chmod +x /tmp/add_to_known_hosts.sh",
      "bash /tmp/add_to_known_hosts.sh '${aws_instance.spark-master.public_dns}' '${aws_instance.spark-master.private_dns}' '${join("' '", "${aws_instance.spark-worker.*.private_dns}")}'",
      "echo \"export AWS_ACCESS_KEY_ID='${var.AWS_ACCESS_KEY}'\nexport AWS_SECRET_ACCESS_KEY='${var.AWS_SECRET_KEY}'\nexport AWS_DEFAULT_REGION='${var.AWS_REGION}'\" >> ~/.profile",
      "chmod +x /tmp/hadoop_setup_single.sh",
      "bash /tmp/hadoop_setup_single.sh '${aws_instance.spark-master.public_dns}' '${var.AWS_ACCESS_KEY}' '${var.AWS_SECRET_KEY}'",
      "chmod +x /tmp/hadoop_config_hosts.sh",
      "bash /tmp/hadoop_config_hosts.sh '${aws_instance.spark-master.public_dns}' '${aws_instance.spark-master.private_dns}' '${join("' '", "${aws_instance.spark-worker.*.public_dns}")}' '${join("' '", "${aws_instance.spark-worker.*.private_dns}")}'",
      "chmod +x /tmp/hadoop_config_namenode.sh",
      "bash /tmp/hadoop_config_namenode.sh '${aws_instance.spark-master.private_dns}' '${join("' '", "${aws_instance.spark-worker.*.private_dns}")}'",
      "chmod +x /tmp/hadoop_format_hdfs.sh",
      "bash /tmp/hadoop_format_hdfs.sh",
      "chmod +x /tmp/spark_setup_single.sh",
      "bash /tmp/spark_setup_single.sh '${aws_instance.spark-master.public_dns}'",
      "chmod +x /tmp/spark_configure_worker.sh",
      "bash /tmp/spark_configure_worker.sh '${join("' '", "${aws_instance.spark-worker.*.public_dns}")}'",
      "chmod +x /tmp/hadoop_start.sh",
      "bash /tmp/hadoop_start.sh",
      "chmod +x /tmp/spark_start.sh",
      "bash /tmp/spark_start.sh",
    ]
  }
}

# Controller
resource "aws_instance" "spark-controller" {
  ami = "${lookup(var.AMIS, "spark")}"
  instance_type = "m4.large"
  key_name = "${aws_key_pair.mykeypair.key_name}"
  count = 1
  vpc_security_group_ids = ["${aws_security_group.open-security-group.id}"]
  subnet_id = "${aws_subnet.main-public.id}"
  associate_public_ip_address = true
  root_block_device {
    volume_size = 100
    volume_type = "standard"
  }
  tags {
    Name = "spark-controller"
    Environment = "dev"
    Terraform = "true"
  }
}

# Configure controller
resource "null_resource" "spark-controller" {

  # Establish connection to worker
  connection {
    type = "ssh"
    user = "ubuntu"  
    host = "${aws_instance.spark-controller.public_ip}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }

  # We need postgres and spark cluster configured first
  depends_on = [ "aws_instance.postgres", "null_resource.spark-master", "null_resource.spark-worker" ]

  # Provision the Spark setup script
  provisioner "file" {
    source = "scripts/spark_setup_single.sh"
    destination = "/tmp/spark_setup_single.sh"
  }

  # Provision the Spark start script
  provisioner "file" {
    source = "scripts/spark_start.sh"
    destination = "/tmp/spark_start.sh"
  }

  # Provision the Spark controller script
  provisioner "file" {
    source = "scripts/spark_setup_controller.sh"
    destination = "/tmp/spark_setup_controller.sh"
  }

  # Execute spark configuration commands remotely
  provisioner "remote-exec" {
    inline = [
      "echo \"export AWS_ACCESS_KEY_ID='${var.AWS_ACCESS_KEY}'\nexport AWS_SECRET_ACCESS_KEY='${var.AWS_SECRET_KEY}'\nexport AWS_DEFAULT_REGION='${var.AWS_REGION}'\" >> ~/.profile",
      "chmod +x /tmp/spark_setup_single.sh",
      "bash /tmp/spark_setup_single.sh '${aws_instance.spark-controller.public_dns}'",
      "chmod +x /tmp/spark_start.sh",
      "bash /tmp/spark_start.sh",
      "chmod +x /tmp/spark_setup_controller.sh",
      "bash /tmp/spark_setup_controller.sh '${aws_instance.postgres.private_dns}' '${aws_instance.spark-master.private_dns}'",
    ]
  }
}