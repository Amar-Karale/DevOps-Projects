# Kubernetes Deployment Guide — Wanderlust

This directory contains the Kubernetes desired state for the Wanderlust application. Argo CD consumes these manifests after the CI/GitOps pipeline promotes new Docker image tags.

The manifests are designed around namespace isolation, controlled rolling updates, rollback history, non-root containers, resource limits, health probes, externalized secrets, and an AWS LoadBalancer frontend for the optional CloudFront edge layer.

## 1. Resources

```text
namespace.yaml
persistentVolume.yaml
persistentVolumeClaim.yaml
mongodb.yaml
redis.yaml
backend.yaml
frontend.yaml
secrets/
  backend-env.example.yaml
  README.md
```

| Manifest | Purpose |
|---|---|
| `namespace.yaml` | Creates the `wanderlust` namespace |
| `persistentVolume.yaml` | MongoDB persistent storage |
| `persistentVolumeClaim.yaml` | MongoDB storage claim |
| `mongodb.yaml` | MongoDB deployment/service |
| `redis.yaml` | Redis deployment/service |
| `backend.yaml` | Node.js backend deployment/service |
| `frontend.yaml` | Production frontend deployment + AWS LoadBalancer service |
| `secrets/backend-env.example.yaml` | Safe secret template only |

## 2. Service flow

```text
Browser
   │
   ├── Frontend LoadBalancer:80
   │       │
   │       └── Frontend Pods:8080
   │
   └── Backend API:31100
           │
           ├── mongo-service:27017
           └── redis-service:6379
```

The frontend is served by an unprivileged Nginx container on port `8080` internally. The Kubernetes Service exposes port `80` through an AWS LoadBalancer.

The backend remains on a NodePort (`31100`) because the frontend application makes browser-side API requests to the backend endpoint.

## 3. Runtime secrets

Real secrets are never committed to Git.

Template:

```text
kubernetes/secrets/backend-env.example.yaml
```

Create the real secret locally or through your secret-management platform:

```bash
cp kubernetes/secrets/backend-env.example.yaml kubernetes/secrets/backend-env.yaml
```

Edit the values and apply:

```bash
kubectl apply -f kubernetes/secrets/backend-env.yaml
```

Verify only the metadata:

```bash
kubectl -n wanderlust get secret backend-env
```

The live secret file is ignored by `.gitignore`.

For AWS production environments, use AWS Secrets Manager + External Secrets Operator as the preferred next step.

## 4. Backend deployment hardening

`backend.yaml` uses:

- 2 replicas
- `RollingUpdate`
- `maxUnavailable: 0`
- `maxSurge: 1`
- `revisionHistoryLimit: 5`
- non-root execution
- privilege escalation disabled
- all Linux capabilities dropped
- `seccompProfile: RuntimeDefault`
- resource requests/limits
- readiness probe
- liveness probe

This provides controlled rollouts and preserves previous ReplicaSet revisions for rollback.

## 5. Frontend deployment hardening

`frontend.yaml` uses:

- 2 replicas
- `RollingUpdate`
- `maxUnavailable: 0`
- `maxSurge: 1`
- `revisionHistoryLimit: 5`
- non-root execution
- privilege escalation disabled
- all Linux capabilities dropped
- `seccompProfile: RuntimeDefault`
- resource requests/limits
- readiness probe
- liveness probe
- AWS `LoadBalancer` service

The AWS LoadBalancer is the origin used by the optional CloudFront configuration under `aws/cloudfront/` and `terraform/cloudfront.tf`.

## 6. Image versions

CI publishes:

```text
amarkarale/wanderlust-backend-beta:<tag>
amarkarale/wanderlust-frontend-beta:<tag>
```

GitOps updates `backend.yaml` and `frontend.yaml` to the exact CI-generated tags before Argo CD reconciles the cluster.

## 7. Argo CD

The Argo CD Application definition is:

```text
../argocd/application.yaml
```

Source:

```text
Repository: https://github.com/Amar-Karale/DevOps-Projects.git
Branch: master
Path: kubernetes
Namespace: wanderlust
```

The desired behavior is:

```text
Git change
    ↓
Argo CD detects change
    ↓
Sync
    ↓
RollingUpdate
    ↓
Healthy application
```

Automated sync, prune, self-heal, and namespace creation are configured in the Argo CD Application.

## 8. Deploying the application manually

For a clean environment where the Argo CD Application is already configured:

```bash
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/persistentVolume.yaml
kubectl apply -f kubernetes/persistentVolumeClaim.yaml
kubectl apply -f kubernetes/mongodb.yaml
kubectl apply -f kubernetes/redis.yaml
kubectl apply -f kubernetes/secrets/backend-env.yaml
kubectl apply -f kubernetes/backend.yaml
kubectl apply -f kubernetes/frontend.yaml
```

For the intended GitOps workflow, let Argo CD apply these manifests instead of manually applying them on every release.

## 9. Verification

```bash
kubectl get nodes
kubectl get pods -n wanderlust
kubectl get deployments -n wanderlust
kubectl get svc -n wanderlust
kubectl get pvc -n wanderlust
```

Check the frontend load balancer:

```bash
kubectl -n wanderlust get svc frontend-service
```

Check backend rollout:

```bash
kubectl -n wanderlust rollout status deployment/backend-deployment
```

Check frontend rollout:

```bash
kubectl -n wanderlust rollout status deployment/frontend-deployment
```

Argo CD:

```bash
argocd app get wanderlust
```

## 10. Rollback

View history:

```bash
kubectl -n wanderlust rollout history deployment/backend-deployment
kubectl -n wanderlust rollout history deployment/frontend-deployment
```

Rollback one revision:

```bash
kubectl -n wanderlust rollout undo deployment/backend-deployment
```

Or use the repository helper:

```bash
./scripts/rollback.sh wanderlust backend-deployment
```

Specific revision:

```bash
./scripts/rollback.sh wanderlust backend-deployment 3
```

For GitOps, the preferred controlled rollback is a Git revert of the bad image-tag commit, followed by Argo CD reconciliation.

## 11. CloudFront integration

The frontend service intentionally uses `type: LoadBalancer`.

After deployment:

```bash
kubectl -n wanderlust get svc frontend-service
```

Copy the AWS load balancer DNS name into Terraform:

```hcl
enable_cloudfront             = true
cloudfront_origin_domain_name = "YOUR-FRONTEND-LB-DNS"
```

Then create the optional CloudFront + WAF edge layer through Terraform.

## 12. Monitoring

The application is monitored through:

- Prometheus
- Grafana
- Node Exporter
- kube-state-metrics
- Alertmanager

AWS-native monitoring is documented in:

```text
../monitoring/cloudwatch/README.md
```

That guide uses the Amazon CloudWatch Observability EKS add-on for CloudWatch Agent, Fluent Bit, and Container Insights.

## 13. Screenshots

The `assets/` directory contains implementation screenshots for:

- EKS nodes
- namespace
- Kubernetes context
- CoreDNS
- persistent storage
- MongoDB
- Redis
- Docker builds and images
- application workloads
- application output

These assets document the original implementation and are not substitutes for environment-specific configuration.
