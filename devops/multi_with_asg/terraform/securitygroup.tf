/*

securitygroup.tf 

This file sets up the security groups for each subnet.
todo: tighten up security for each component of the data pipeline.

*/

# Open security group
resource "aws_security_group" "open-security-group" {
  vpc_id = "${aws_vpc.main.id}"
  name = "open-security-group"
  description = "Open security group allows all ingress and egress traffic"
  # All egress traffic
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
  # All ingress traffic
  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  } 
  tags {
    Name = "open-security-group"
  }
}