variable "aws_region" {
  description = "AWS region where resources will be provisioned"
  type        = string
  default     = "us-west-1"
}

variable "ami_id" {
  description = "AMI ID for the optional EC2 host"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.large"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "public_key" {
  description = "SSH public key material"
  type        = string
  sensitive   = true
}

variable "ssh_cidr_blocks" {
  description = "CIDR ranges allowed to SSH to the instance. Prefer a single trusted public IP /32."
  type        = list(string)
}

variable "enable_cloudwatch" {
  description = "Create the CloudWatch log group and EC2 CPU alarm"
  type        = bool
  default     = true
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention period"
  type        = number
  default     = 30
}

variable "enable_cloudfront" {
  description = "Create the optional CloudFront + WAF edge layer"
  type        = bool
  default     = false
}

variable "cloudfront_origin_domain_name" {
  description = "DNS name of the frontend load balancer, without protocol or path"
  type        = string
  default     = ""
}

variable "cloudfront_aliases" {
  description = "Optional custom DNS names for CloudFront"
  type        = list(string)
  default     = []
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}
