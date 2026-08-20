# Amazon CloudWatch for EKS

This project uses Amazon CloudWatch as the AWS-native logging and container-observability path, alongside Prometheus and Grafana for Kubernetes metrics and dashboards.

## Recommended EKS implementation

Use the **Amazon CloudWatch Observability EKS add-on**. Current AWS guidance supports installing the add-on with EKS Pod Identity or IAM roles for service accounts (IRSA). The add-on installs the CloudWatch Agent and Fluent Bit and can provide Container Insights and Application Signals. For current versions, AWS recommends EKS Pod Identity for least-privilege permissions and credential rotation.

### 1. Verify the cluster

```bash
aws eks describe-cluster \
  --name <EKS_CLUSTER_NAME> \
  --query "cluster.status" \
  --output text
```

### 2. Create the CloudWatch IAM role

With `eksctl` and IRSA:

```bash
eksctl create iamserviceaccount \
  --name cloudwatch-agent \
  --namespace amazon-cloudwatch \
  --cluster <EKS_CLUSTER_NAME> \
  --role-name EKS-CloudWatch-Observability-Role \
  --role-only \
  --attach-policy-arn arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess \
  --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
  --approve
```

### 3. Install the EKS add-on

```bash
aws eks create-addon \
  --cluster-name <EKS_CLUSTER_NAME> \
  --addon-name amazon-cloudwatch-observability \
  --configuration-values '{"otelContainerInsights":{"enabled":true}}'
```

### 4. Verify the add-on

```bash
aws eks describe-addon \
  --cluster-name <EKS_CLUSTER_NAME> \
  --addon-name amazon-cloudwatch-observability \
  --query "addon.status" \
  --output text
```

Expected status:

```text
ACTIVE
```

Then verify the agent pods:

```bash
kubectl get pods -n amazon-cloudwatch -l app.kubernetes.io/name=cloudwatch-agent
```

### 5. What CloudWatch adds

- Container and node telemetry
- Kubernetes log collection through Fluent Bit
- CloudWatch Logs integration
- Container Insights
- Application Signals / OpenTelemetry capability in supported configurations
- Native AWS alerting and operational visibility

The Terraform layer in `terraform/cloudwatch.tf` also creates a dedicated application log group and an EC2 CPU alarm for the optional host layer.

## Relationship with Prometheus and Grafana

```text
Kubernetes workloads
       │
       ├── Prometheus → Grafana → dashboards
       │
       └── CloudWatch Agent / Fluent Bit
                │
                ├── CloudWatch Logs
                ├── Container Insights
                └── CloudWatch alarms
```

This gives the project both Kubernetes-native observability and AWS-native operational visibility.
