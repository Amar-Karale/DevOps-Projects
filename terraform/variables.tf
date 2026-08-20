variable "aws_region" {
  description = "AWS region where resources will be provisioned"
  type        = string
  default     = "us-west-1"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.large"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name"
  type        = string
}

variable "public_key" {
  description = "SSH public key material"
  type        = string
  sensitive   = true
}

variable "ssh_cidr_blocks" {
  description = "CIDR ranges allowed to SSH to the instance"
  type        = list(string)
}
