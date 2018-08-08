# AWS elastic load balancer
# Listener checks for connection requests
# Double check the listener ports later
# Setting cross_zone_load_balancing on allows ELB to distribute across 
# multiple availability zones
resource "aws_elb" "flask-elb" {
  name = "flask-elb"
  subnets = ["${aws_subnet.main-public.id}"]
  security_groups = ["${aws_security_group.open-security-group.id}"]
 listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:8080/"
    interval = 30
  }

  cross_zone_load_balancing = true
  connection_draining = true
  connection_draining_timeout = 400
  tags {
    Name = "flask-elb"
  }
}