# Scale up policy
# Scale up by 1 instance for each scaling activity and wait 30 seconds
# before the next one can start.
resource "aws_autoscaling_policy" "flask-cpu-policy" {
  name                   = "flask-cpu-policy"
  autoscaling_group_name = "${aws_autoscaling_group.flask-autoscaling.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "30"
  policy_type            = "SimpleScaling"
}

# Scale up alarm
# Trigger alarm when CPU is >= 30% at most once every minute
resource "aws_cloudwatch_metric_alarm" "flask-cpu-alarm" {
  alarm_name          = "flask-cpu-alarm"
  alarm_description   = "flask-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.flask-autoscaling.name}"
  }

  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.flask-cpu-policy.arn}"]
}

# Scale down policy
# Scale down by 1 instance for each scaling activity and wait 10 seconds
# before the next one can start.
resource "aws_autoscaling_policy" "flask-cpu-policy-scaledown" {
  name                   = "flask-cpu-policy-scaledown"
  autoscaling_group_name = "${aws_autoscaling_group.flask-autoscaling.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "10"
  policy_type            = "SimpleScaling"
}

# Scale down alarm
# Trigger alarm when CPU is <= 5% at most once every minute
resource "aws_cloudwatch_metric_alarm" "flask-cpu-alarm-scaledown" {
  alarm_name          = "flask-cpu-alarm-scaledown"
  alarm_description   = "flask-cpu-alarm-scaledown"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.flask-autoscaling.name}"
  }

  actions_enabled = true
  alarm_actions = ["${aws_autoscaling_policy.flask-cpu-policy-scaledown.arn}"]
}