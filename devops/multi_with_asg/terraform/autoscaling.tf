#######
# Autoscaling configuration for subnet 1
#######

# AWS launch configuration
resource "aws_launch_configuration" "flask-launchconfig-1" {
  name_prefix          = "flask-launchconfig-1"
  image_id             = "${lookup(var.AMIS, "flask")}"
  instance_type        = "t2.micro"
  key_name             = "${aws_key_pair.mykeypair.key_name}"
  security_groups      = ["${aws_security_group.open-security-group.id}"]
  user_data = <<-EOF
            #!/bin/bash
            APPHOME='/home/ubuntu/insight_devops_airaware/AirAware'
            sed -i '/dns-postgres-1/c\dns_1 = ${aws_instance.postgres-1.private_dns}' $${APPHOME}/setup.cfg
            sed -i '/dns-postgres-2/c\dns_2 = ${aws_instance.postgres-2.private_dns}' $${APPHOME}/setup.cfg
            sed -i '/dns-spark/c\dns = ${aws_instance.spark-master-1.private_dns}:7077' $${APPHOME}/setup.cfg
            sed -i 's/dns/dns-1/g' $${APPHOME}/flask/config.py
            cd $${APPHOME}/flask
            python app_stress.py &
            EOF
  lifecycle {
    create_before_destroy = true # Leave as true
  }
}

# AWS autoscaling group
resource "aws_autoscaling_group" "flask-autoscaling-1" {
  name                 = "flask-autoscaling-1"
  vpc_zone_identifier  = ["${aws_subnet.main-public-1.id}"]
  launch_configuration = "${aws_launch_configuration.flask-launchconfig-1.name}"
  min_size             = 1 # Minimum number of instances
  max_size             = 5 # Maximum number of instances
  health_check_grace_period = 300 # Time after instances comes into service to health check
  health_check_type = "ELB" # Health check ELB
  load_balancers = ["${aws_elb.flask-elb.name}"]
  force_delete = true
  tag {
      key = "Name"
      value = "flask-1"
      propagate_at_launch = true # Propagate flask name to new instances
  }
}

#######
# Autoscaling configuration for subnet 2
#######

# AWS launch configuration
resource "aws_launch_configuration" "flask-launchconfig-2" {
  name_prefix          = "flask-launchconfig-2"
  image_id             = "${lookup(var.AMIS, "flask")}"
  instance_type        = "t2.micro"
  key_name             = "${aws_key_pair.mykeypair.key_name}"
  security_groups      = ["${aws_security_group.open-security-group.id}"]
  user_data = <<-EOF
            #!/bin/bash
            APPHOME='/home/ubuntu/insight_devops_airaware/AirAware'
            sed -i '/dns-postgres-1/c\dns_1 = ${aws_instance.postgres-1.private_dns}' $${APPHOME}/setup.cfg
            sed -i '/dns-postgres-2/c\dns_2 = ${aws_instance.postgres-2.private_dns}' $${APPHOME}/setup.cfg
            sed -i '/dns-spark/c\dns = ${aws_instance.spark-master-1.private_dns}:7077' $${APPHOME}/setup.cfg
            sed -i 's/dns/dns-2/g' $${APPHOME}/flask/config.py
            cd $${APPHOME}/flask
            python app_stress.py &
            EOF
  lifecycle {
    create_before_destroy = true # Leave as true
  }
}

# AWS autoscaling group for main-public-2 subnet
resource "aws_autoscaling_group" "flask-autoscaling-2" {
  name                 = "flask-autoscaling-2"
  vpc_zone_identifier  = ["${aws_subnet.main-public-2.id}"]
  launch_configuration = "${aws_launch_configuration.flask-launchconfig-2.name}"
  min_size             = 1 # Minimum number of instances
  max_size             = 5 # Maximum number of instances
  health_check_grace_period = 300 # Time after instances comes into service to health check
  health_check_type = "ELB" # Health check ELB
  load_balancers = ["${aws_elb.flask-elb.name}"]
  force_delete = true
  tag {
      key = "Name"
      value = "flask-2"
      propagate_at_launch = true # Propagate flask name to new instances
  }
}