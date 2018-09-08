output "MASTER_PRIVATE_DNS" {
  value = "${aws_instance.spark-master.private_dns}"
}