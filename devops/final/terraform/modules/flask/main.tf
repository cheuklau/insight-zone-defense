# Autoscaling launch configuration
resource "aws_launch_configuration" "flask-launchconfig" {
  name_prefix          = "flask-launchconfig-${var.SUBNET_NUM}"
  image_id             = "${var.AMIS}"
  instance_type        = "t2.micro"
  key_name             = "${var.KEY_NAME}"
  security_groups      = ["${var.SECURITY_GROUP_ID}"]
  user_data = <<-EOF
            #!/bin/bash
            APPHOME='/home/ubuntu/insight_devops_airaware/AirAware'
            sed -i '/dns-postgres-1/c\dns_1 = ${var.POSTGRES_DNS_1}' $${APPHOME}/setup.cfg
            sed -i '/dns-postgres-2/c\dns_2 = ${var.POSTGRES_DNS_2}' $${APPHOME}/setup.cfg
            sed -i '/dns-spark/c\dns = ${var.SPARK_DNS}:7077' $${APPHOME}/setup.cfg
            sed -i 's/dns/dns_1/g' $${APPHOME}/flask/config.py
            cd $${APPHOME}/flask
            python app_stress.py &
            EOF
  lifecycle {
    create_before_destroy = true # Leave as true
  }
}

# AWS autoscaling group
resource "aws_autoscaling_group" "flask-autoscaling" {
  name                 = "flask-autoscaling-${var.SUBNET_NUM}"
  vpc_zone_identifier  = ["${var.SUBNET}"]
  launch_configuration = "${aws_launch_configuration.flask-launchconfig.name}"
  min_size             = 1 # Minimum number of instances
  max_size             = 5 # Maximum number of instances
  health_check_grace_period = 300 # Time after instances comes into service to health check
  health_check_type = "ELB" # Health check ELB
  load_balancers = ["${var.ELB_NAME}"]
  force_delete = true
  tag {
      key = "Name"
      value = "flask-${var.SUBNET_NUM}"
      propagate_at_launch = true # Propagate flask name to new instances
  }
}

# Auto-scaling policy
resource "aws_autoscaling_policy" "flask-cpu-policy" {
  name                   = "flask-cpu-policy-${var.SUBNET_NUM}"
  autoscaling_group_name = "${aws_autoscaling_group.flask-autoscaling.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1" # Increment by one each time
  cooldown               = "5" # Seconds after scaling before next one can start
  policy_type            = "SimpleScaling"
}

# AWS cloud watch alarm for upper CPU threshold
resource "aws_cloudwatch_metric_alarm" "flask-cpu-alarm" {
  alarm_name          = "flask-cpu-alarm-${var.SUBNET_NUM}"
  alarm_description   = "flask-cpu-alarm-${var.SUBNET_NUM}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1" # Number of periods over which data is compared to threshold
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60" # Period in seconds over which statistic is applied
  statistic           = "Average"
  threshold           = "5" # 5% max CPU utilization
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.flask-autoscaling.name}"
  }
  actions_enabled = true # Execute actions if alarm goes off
  alarm_actions   = ["${aws_autoscaling_policy.flask-cpu-policy.arn}"]
}

# AWS autoscaling policy for scaling down
resource "aws_autoscaling_policy" "flask-cpu-policy-scaledown" {
  name                   = "flask-cpu-policy-scaledown-${var.SUBNET_NUM}"
  autoscaling_group_name = "${aws_autoscaling_group.flask-autoscaling.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1" # Decrease by one each time
  cooldown               = "5" # Seconds after scaling before next one can start
  policy_type            = "SimpleScaling"
}

# AWS cloud watch alarm for minimum CPU threshold
resource "aws_cloudwatch_metric_alarm" "flask-cpu-alarm-scaledown" {
  alarm_name          = "flask-cpu-alarm-scaledown-${var.SUBNET_NUM}"
  alarm_description   = "flask-cpu-alarm-scaledown-${var.SUBNET_NUM}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "1" # Set minimum to 1% utilization
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.flask-autoscaling.name}"
  }
  actions_enabled = true
  alarm_actions = ["${aws_autoscaling_policy.flask-cpu-policy-scaledown.arn}"]
}
