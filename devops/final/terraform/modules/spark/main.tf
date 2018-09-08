# Spark master node
resource "aws_instance" "spark-master" {
  ami = "${var.AMIS}"
  instance_type = "m4.large"
  key_name = "${var.KEY_NAME}"
  count = 1
  vpc_security_group_ids = ["${var.SECURITY_GROUP_ID}"]
  subnet_id = "${var.SUBNET}"
  associate_public_ip_address = true
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

# Spark workers
resource "aws_instance" "spark-worker" {
  ami = "${var.AMIS}"
  instance_type = "m4.large"
  key_name = "${var.KEY_NAME}"
  count = "${var.NUM_WORKERS}"
  vpc_security_group_ids = ["${var.SECURITY_GROUP_ID}"]
  subnet_id = "${var.SUBNET}"
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
    source = "${path.module}/scripts/hadoop_setup_single.sh"
    destination = "/tmp/hadoop_setup_single.sh"
  }

  # Provision the Hadoop configuration script
  provisioner "file" {
    source = "${path.module}/scripts/hadoop_config_datanode.sh"
    destination = "/tmp/hadoop_config_datanode.sh"
  }

  # Provision the Spark setup script
  provisioner "file" {
    source = "${path.module}/scripts/spark_setup_single.sh"
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
    source = "${path.module}/scripts/setup_ssh.sh"
    destination = "/tmp/setup_ssh.sh"
  }

  # Provision the Host configuration script
  provisioner "file" {
    source = "${path.module}/scripts/add_to_known_hosts.sh"
    destination = "/tmp/add_to_known_hosts.sh"
  }

  # Provision the Hadoop setup script
  provisioner "file" {
    source = "${path.module}/scripts/hadoop_setup_single.sh"
    destination = "/tmp/hadoop_setup_single.sh"
  }

  # Provision the Hadoop setup script
  provisioner "file" {
    source = "${path.module}/scripts/hadoop_config_hosts.sh"
    destination = "/tmp/hadoop_config_hosts.sh"
  }

  # Provision the Hadoop setup script
  provisioner "file" {
    source = "${path.module}/scripts/hadoop_config_namenode.sh"
    destination = "/tmp/hadoop_config_namenode.sh"
  }

  # Provision the Hadoop setup script
  provisioner "file" {
    source = "${path.module}/scripts/hadoop_format_hdfs.sh"
    destination = "/tmp/hadoop_format_hdfs.sh"
  }

  # Provision the Spark setup script
  provisioner "file" {
    source = "${path.module}/scripts/spark_setup_single.sh"
    destination = "/tmp/spark_setup_single.sh"
  }

  # Provision the Spark setup script
  provisioner "file" {
    source = "${path.module}/scripts/spark_configure_worker.sh"
    destination = "/tmp/spark_configure_worker.sh"
  }

  # Provision the Hadoop start script
  provisioner "file" {
    source = "${path.module}/scripts/hadoop_start.sh"
    destination = "/tmp/hadoop_start.sh"
  }

  # Provision the Spark start script
  provisioner "file" {
    source = "${path.module}/scripts/spark_start.sh"
    destination = "/tmp/spark_start.sh"
  }

  provisioner "file" {
    source = "${var.PATH_TO_PRIVATE_KEY}"
    destination = "/tmp/${var.KEY_NAME}"
  }

  # Provision 
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup_ssh.sh",
      "bash /tmp/setup_ssh.sh '${var.KEY_NAME}' '${join("' '", "${aws_instance.spark-worker.*.public_dns}")}'",
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
  ami = "${var.AMIS}"
  instance_type = "m4.large"
  key_name = "${var.KEY_NAME}"
  count = 1
  vpc_security_group_ids = ["${var.SECURITY_GROUP_ID}"]
  subnet_id = "${var.SUBNET}"
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
  depends_on = [ "null_resource.spark-master", "null_resource.spark-worker" ]

  # Provision the Spark setup script
  provisioner "file" {
    source = "${path.module}/scripts/spark_setup_single.sh"
    destination = "/tmp/spark_setup_single.sh"
  }

  # Provision the Spark start script
  provisioner "file" {
    source = "${path.module}/scripts/spark_start.sh"
    destination = "/tmp/spark_start.sh"
  }

  # Provision the Spark controller script
  provisioner "file" {
    source = "${path.module}/scripts/spark_setup_controller.sh"
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
      "bash /tmp/spark_setup_controller.sh '${var.POSTGRES_DNS_1}' '${var.POSTGRES_DNS_2}' '${aws_instance.spark-master.private_dns}'",
    ]
  }
}