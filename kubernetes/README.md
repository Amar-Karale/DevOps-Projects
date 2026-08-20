# Wanderlust Kubernetes Deployment

This directory contains the Kubernetes manifests used by Argo CD.

## Prerequisites

- An EKS cluster registered in Argo CD as `wanderlust`.
- DockerHub images published as `amarkarale/wanderlust-backend-beta:<tag>` and `amarkarale/wanderlust-frontend-beta:<tag>`.
- `kubectl` configured for the target EKS cluster.

## 1. Create the namespace

The repository includes `namespace.yaml`:

```bash
kubectl apply -f namespace.yaml
```

## 2. Create the backend secret

Secrets are intentionally **not stored in Git**.

Create the backend secret from your secure environment:

```bash
kubectl create secret generic backend-env \
  -n wanderlust \
  --from-literal=MONGODB_URI='mongodb://mongo-service/wanderlust' \
  --from-literal=REDIS_URL='redis://redis-service:6379' \
  --from-literal=PORT='8080' \
  --from-literal=FRONTEND_URL='http://<frontend-host>:31000' \
  --from-literal=ACCESS_COOKIE_MAXAGE='120000' \
  --from-literal=ACCESS_TOKEN_EXPIRES_IN='120s' \
  --from-literal=REFRESH_COOKIE_MAXAGE='120000' \
  --from-literal=REFRESH_TOKEN_EXPIRES_IN='120s' \
  --from-literal=JWT_SECRET='<generate-a-new-random-secret>' \
  --from-literal=NODE_ENV='production'
```

Never commit the real JWT secret or `.env` files.

## 3. Deploy the manifests

```bash
kubectl apply -f persistentVolume.yaml
kubectl apply -f persistentVolumeClaim.yaml
kubectl apply -f mongodb.yaml
kubectl apply -f redis.yaml
kubectl apply -f backend.yaml
kubectl apply -f frontend.yaml
```

Or let Argo CD synchronize the `kubernetes` directory automatically.

## 4. Verify

```bash
kubectl get pods -n wanderlust
kubectl get svc -n wanderlust
kubectl get deployments -n wanderlust
```

Frontend is exposed through NodePort `31000` and backend through NodePort `31100`.

## Argo CD

The Argo CD application definition is in `../argocd/application.yaml`.

```bash
kubectl apply -f ../argocd/application.yaml
argocd app get wanderlust
argocd app sync wanderlust
```

## Docker image updates

The CI pipeline publishes images to DockerHub. The GitOps pipeline updates `backend.yaml` and `frontend.yaml` with the new image tags, after which Argo CD synchronizes the cluster.
