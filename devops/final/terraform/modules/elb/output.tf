############################################################################
#
# Output variables required by other modules
#
############################################################################
output "ELB_IP" {
  value = "${aws_elb.flask-elb.dns_name}"
}

output "ELB_NAME" {
  value = "${aws_elb.flask-elb.name}"
}