output "PRIVATE_DNS" {
  value = "${aws_instance.postgres.private_dns}"
}