############################################################################
#
# Output variables required by other modules
#
############################################################################
output "PRIVATE_DNS" {
  value = "${aws_instance.postgres.private_dns}"
}