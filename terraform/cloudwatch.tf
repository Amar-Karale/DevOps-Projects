resource "aws_cloudwatch_log_group" "wanderlust" {
  count             = var.enable_cloudwatch ? 1 : 0
  name              = "/wanderlust/application"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = {
    Project = "Wanderlust"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  count = var.enable_cloudwatch ? 1 : 0

  alarm_name          = "wanderlust-ec2-high-cpu"
  alarm_description   = "Alert when the Wanderlust EC2 host has sustained high CPU usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.testinstance.id
  }
}
