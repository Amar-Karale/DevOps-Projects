output "ec2_instance_id" {
  description = "EC2 instance ID used by the optional host layer"
  value       = aws_instance.testinstance.id
}

output "ec2_public_ip" {
  description = "Public IP of the optional EC2 host"
  value       = aws_instance.testinstance.public_ip
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group created for Wanderlust"
  value       = var.enable_cloudwatch ? aws_cloudwatch_log_group.wanderlust[0].name : null
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain when the edge layer is enabled"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.wanderlust[0].domain_name : null
}
