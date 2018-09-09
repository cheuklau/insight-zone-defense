############################################################################
#
# Output variables required by other modules
#
############################################################################
output "MASTER_PRIVATE_DNS" {
  value = "${aws_instance.spark-master.private_dns}"
}