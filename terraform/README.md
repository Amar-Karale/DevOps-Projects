# Terraform and AWS infrastructure

This directory contains the AWS infrastructure layer and the reusable hardening/edge resources around the Wanderlust deployment.

## What Terraform manages here

- EC2 support host
- EC2 security group
- encrypted gp3 root volume
- IAM role and instance profile for Systems Manager (SSM)
- CloudWatch log group
- CloudWatch EC2 CPU alarm
- optional CloudFront distribution
- optional AWS WAF managed-rule protection

The EKS cluster used by the application is an AWS platform dependency. The repository documents the EKS-specific integrations separately so the infrastructure can be recreated without assuming one fixed cluster name or account.

## 1. Prepare variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your own AWS values. Never commit this file.

## 2. Initialize and validate

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
```

## 3. Apply the base infrastructure

```bash
terraform apply
```

Review the plan before approving it.

## 4. CloudWatch

`enable_cloudwatch = true` creates the application log group and EC2 CPU alarm.

For EKS logs, metrics, and Container Insights, follow `../monitoring/cloudwatch/README.md` and install the Amazon CloudWatch Observability EKS add-on.

## 5. CloudFront + WAF

CloudFront is optional because the origin is environment-specific.

After the Kubernetes frontend service becomes a `LoadBalancer`, obtain the load balancer DNS name and set:

```hcl
enable_cloudfront             = true
cloudfront_origin_domain_name = "YOUR-FRONTEND-LB-DNS"
```

Then run:

```bash
terraform plan
terraform apply
terraform output cloudfront_domain_name
```

The distribution uses HTTPS for viewers, a custom HTTP origin to the frontend load balancer, and an AWS Managed Rules Common Rule Set WAF.

## 6. SSM administration

The EC2 host receives `AmazonSSMManagedInstanceCore`, allowing administrative access through AWS Systems Manager without requiring SSH for routine access.

For stronger security, keep `ssh_cidr_blocks` limited to your own trusted IP or eliminate SSH entirely after confirming SSM access.

## 7. Destroy

When the temporary lab environment is no longer needed:

```bash
terraform destroy
```

Never run destroy against a shared or production AWS account without reviewing the plan.
