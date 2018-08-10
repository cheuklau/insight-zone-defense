# AWS launch configuration
resource "aws_launch_configuration" "flask-launchconfig" {
  name_prefix          = "flask-launchconfig"
  image_id             = "${lookup(var.AMIS, "flask")}"
  instance_type        = "t2.micro"
  key_name             = "${aws_key_pair.mykeypair.key_name}"
  security_groups      = ["${aws_security_group.open-security-group.id}"]
  user_data = <<-EOF
            #!/bin/bash
            APPHOME='/home/ubuntu/insight_devops_airaware/AirAware'
            sed -i '/dns-postgres/c\dns = ${aws_instance.postgres.private_dns}' $${APPHOME}/setup.cfg
            sed -i '/dns-spark/c\dns = ${aws_instance.spark-master.private_dns}:7077' $${APPHOME}/setup.cfg
            cd $${APPHOME}/flask
            python app_stress.py &
            EOF
  lifecycle {
    create_before_destroy = true # Leave as true
  }
}

# AWS autoscaling group
resource "aws_autoscaling_group" "flask-autoscaling" {
  name                 = "flask-autoscaling"
  vpc_zone_identifier  = ["${aws_subnet.main-public.id}"]
  launch_configuration = "${aws_launch_configuration.flask-launchconfig.name}"
  min_size             = 1 # Minimum number of instances
  max_size             = 5 # Maximum number of instances
  health_check_grace_period = 300 # Time after instances comes into service to health check
  health_check_type = "ELB" # Health check ELB
  load_balancers = ["${aws_elb.flask-elb.name}"]
  force_delete = true
  tag {
      key = "Name"
      value = "flask"
      propagate_at_launch = true # Propagate flask name to new instances
  }
}