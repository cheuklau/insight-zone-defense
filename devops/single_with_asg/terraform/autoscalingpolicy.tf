# AWS autoscaling policy for scaling up
resource "aws_autoscaling_policy" "flask-cpu-policy" {
  name                   = "flask-cpu-policy"
  autoscaling_group_name = "${aws_autoscaling_group.flask-autoscaling.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1" # Increment by one each time
  cooldown               = "5" # Seconds after scaling before next one can start
  policy_type            = "SimpleScaling"
}

# AWS cloud watch alarm for upper CPU threshold
resource "aws_cloudwatch_metric_alarm" "flask-cpu-alarm" {
  alarm_name          = "flask-cpu-alarm"
  alarm_description   = "flask-cpu-alarm"
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
  name                   = "flask-cpu-policy-scaledown"
  autoscaling_group_name = "${aws_autoscaling_group.flask-autoscaling.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1" # Decrease by one each time
  cooldown               = "5" # Seconds after scaling before next one can start
  policy_type            = "SimpleScaling"
}

# AWS cloud watch alarm for minimum CPU threshold
resource "aws_cloudwatch_metric_alarm" "flask-cpu-alarm-scaledown" {
  alarm_name          = "flask-cpu-alarm-scaledown"
  alarm_description   = "flask-cpu-alarm-scaledown"
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