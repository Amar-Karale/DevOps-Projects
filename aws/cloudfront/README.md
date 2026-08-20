# CloudFront + AWS WAF

The optional edge layer places Amazon CloudFront in front of the frontend AWS Load Balancer.

```text
User
  ↓ HTTPS
CloudFront
  ↓
AWS WAF
  ↓
EKS frontend Load Balancer
  ↓
Frontend Pods
```

## Why CloudFront

- Global edge caching for static frontend assets
- HTTPS at the edge
- Lower latency for geographically distributed users
- Reduced load on the EKS frontend service
- A stable public endpoint independent of pod IPs

## Why AWS WAF

The Terraform WAF resource uses the AWS Managed Rules Common Rule Set as a baseline layer against common web attacks.

## Terraform activation

CloudFront is intentionally optional because the origin must be the DNS name of the actual frontend Load Balancer in the target AWS account.

1. Deploy the Kubernetes frontend as a `LoadBalancer` service.
2. Get its AWS load balancer hostname:

```bash
kubectl -n wanderlust get svc frontend-service
```

3. Set the Terraform variables:

```hcl
enable_cloudfront            = true
cloudfront_origin_domain_name = "YOUR-FRONTEND-LOAD-BALANCER-DNS"
cloudfront_price_class       = "PriceClass_100"
```

4. Apply Terraform:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

5. Read the CloudFront hostname:

```bash
terraform output cloudfront_domain_name
```

6. Use that hostname for the public frontend URL and configure the backend `FRONTEND_URL` accordingly.

## Production DNS

For a custom domain, create/validate an ACM certificate and use Route 53 (or another DNS provider). CloudFront certificates for custom domains are managed in `us-east-1`.
