############################################################################
#
# Output ELB IP to visit deployed application front-end
#
############################################################################
output "ELB_IP" {
  value = "${module.elb.ELB_IP}"
}
