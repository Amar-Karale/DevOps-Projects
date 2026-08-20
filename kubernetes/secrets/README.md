# Kubernetes secrets

The real application secrets are intentionally not committed to Git.

## Create the backend secret

1. Copy the template:

```bash
cp kubernetes/secrets/backend-env.example.yaml kubernetes/secrets/backend-env.yaml
```

2. Replace `JWT_SECRET`, `FRONTEND_URL`, and any environment-specific values.

3. Apply the secret directly to the cluster:

```bash
kubectl apply -f kubernetes/secrets/backend-env.yaml
```

4. Verify the secret exists without printing its values:

```bash
kubectl -n wanderlust get secret backend-env
```

5. Restart the backend after changing the secret:

```bash
kubectl -n wanderlust rollout restart deployment/backend-deployment
```

## Production recommendation

For a production AWS environment, use AWS Secrets Manager with External Secrets Operator instead of storing a plaintext secret manifest on a workstation.
