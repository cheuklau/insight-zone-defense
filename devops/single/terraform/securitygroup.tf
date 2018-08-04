/*

securitygroup.tf 

This file sets up the security groups for each subnet.
todo: Tighten up security for private subnets (not required).

*/

# Spark security group
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

/*
# Flask security group
resource "aws_security_group" "flask-security-group" {
  vpc_id = "${aws_vpc.main.id}"
  name = "flask-security-group"
  description = "Flask security group allows ssh/UI ingress and all egress traffic"
  # All egress traffic
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
  # SSH
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  } 
  # UI (default = 5000)
  ingress {
      from_port = 5000
      to_port = 5000
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  } 
tags {
    Name = "flask-security-group"
  }
}

# Postgresql security group
resource "aws_security_group" "postgresql-security-group" {
  vpc_id = "${aws_vpc.main.id}"
  name = "postgresql-security-group"
  description = "Postgresql security group allows all ingress and egress traffic"
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
    Name = "postgresql-security-group"
  }
}
*/

/*
# Spark security group
resource "aws_security_group" "spark-security-group" {
  vpc_id = "${aws_vpc.main.id}"
  name = "spark-security-group"
  description = "Spark security group allows all ingress and egress traffic"
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
    Name = "spark-security-group"
  }
}
*/
