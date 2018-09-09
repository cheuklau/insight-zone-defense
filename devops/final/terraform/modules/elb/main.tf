############################################################################
#
# AWS elastic load balancer
#
#
############################################################################
resource "aws_elb" "flask-elb" {
  name = "flask-elb"
  subnets = ["${var.SUBNET_1}" ,"${var.SUBNET_2}"]
  security_groups = ["${var.SECURITY_GROUP_ID}"]
 listener {
    instance_port = 5000 # Port on the instance to route to
    instance_protocol = "http"
    lb_port = 80 # Port to listen on for the load balancer
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2 # Number of checks before declared healthy
    unhealthy_threshold = 2 # Number of checks before declared unhealthy
    timeout = 10 # Length of time before check times out
    target = "HTTP:5000/"
    interval = 300 # Interval between checks
  }
  cross_zone_load_balancing = true # ELB distributes across AZs
  connection_draining = true
  connection_draining_timeout = 400
  tags {
    Name = "flask-elb"
  }
}
