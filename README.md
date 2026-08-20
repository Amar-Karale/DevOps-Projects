# Wanderlust — DevSecOps + GitOps on AWS EKS

A complete cloud-native deployment of the **Wanderlust** full-stack application, built around a production-style DevOps workflow:

**GitHub → Jenkins CI → Security & Quality Checks → Docker → Docker Hub → GitOps update → Argo CD → Amazon EKS → Prometheus + Grafana**

This repository is the public, cleaned-up version of my Wanderlust DevOps project. The application and deployment were built, configured, tested, and operated by me. Runtime secrets and machine-specific values are intentionally excluded from GitHub so the repository can be safely shared and used as a starting point by others.

---

## 🚀 What this project demonstrates

- Full CI/CD automation with Jenkins
- DevSecOps checks with OWASP Dependency-Check, Trivy, and SonarQube
- Containerization with Docker
- Image publishing to Docker Hub
- Kubernetes deployment on Amazon EKS
- GitOps-style manifest promotion through a dedicated Jenkins job
- Argo CD continuous delivery and automated synchronization
- MongoDB and Redis running as Kubernetes workloads for the application stack
- Persistent storage for MongoDB
- Prometheus monitoring and Grafana dashboards
- Infrastructure automation with Terraform
- Secure handling of environment files and credentials

---

## 🧭 Architecture

### High-level flow

```text
Developer
   │
   ▼
GitHub
   │
   ▼
Jenkins CI
   ├── Checkout
   ├── Trivy filesystem scan
   ├── OWASP Dependency-Check
   ├── SonarQube analysis
   ├── SonarQube Quality Gate
   ├── Docker build
   └── Docker push
           │
           ▼
       Docker Hub
           │
           ▼
      GitOps Jenkins
           │
           ├── Update Kubernetes image tags
           └── Commit + push to GitHub
                     │
                     ▼
                  Argo CD
                     │
                     ▼
                 Amazon EKS
          ┌──────────┼──────────┐
          │          │          │
       Frontend   Backend     MongoDB
          │          │          │
          │          └──── Redis
          │
          ▼
   Kubernetes Services

Monitoring:
Amazon EKS → Prometheus → Grafana
```

### Project architecture

![Wanderlust architecture](Assets/architectures.png)

### DevSecOps + GitOps flow

![DevSecOps and GitOps flow](Assets/flow.png)

### CI/CD visual overview

![DevSecOps GitOps animation](Assets/DevSecOps%2BGitOps.gif)

---

## 🧰 Technology stack

| Area | Technology |
|---|---|
| Source control | GitHub |
| CI/CD | Jenkins |
| Jenkins shared library | Jenkins Shared Library |
| Code quality | SonarQube |
| Dependency security | OWASP Dependency-Check |
| Filesystem security | Trivy |
| Containers | Docker |
| Registry | Docker Hub |
| Orchestration | Kubernetes |
| Cloud | AWS |
| Kubernetes platform | Amazon EKS |
| Continuous delivery | Argo CD |
| Application database | MongoDB |
| Cache | Redis |
| Metrics | Prometheus |
| Dashboards | Grafana |
| Infrastructure as Code | Terraform |
| Backend | Node.js / Express |
| Frontend | React / TypeScript / Vite |
| Styling | Tailwind CSS |

---

# 📁 Repository structure

```text
.
├── Assets/                         # Architecture diagrams and screenshots
├── Automations/                    # Environment/configuration helper scripts
├── GitOps/
│   └── Jenkinsfile                 # GitOps image-tag update pipeline
├── argocd/
│   └── application.yaml             # Argo CD Application definition
├── backend/                         # Node.js / Express API
│   ├── controllers/
│   ├── models/
│   ├── routes/
│   ├── services/
│   ├── tests/
│   └── Dockerfile
├── frontend/                        # React + Vite application
│   ├── src/
│   └── Dockerfile
├── kubernetes/                      # Kubernetes manifests
│   ├── namespace.yaml
│   ├── backend.yaml
│   ├── frontend.yaml
│   ├── mongodb.yaml
│   ├── redis.yaml
│   ├── persistentVolume.yaml
│   └── persistentVolumeClaim.yaml
├── terraform/                       # AWS infrastructure definitions
│   ├── ec2.tf
│   ├── terraform.tf
│   └── variables.tf
├── Jenkinsfile                      # CI pipeline
├── docker-compose.yml                # Local/container-stack definition
├── .gitignore                        # Secrets and local build exclusions
└── README.md
```

---

# 🔄 CI pipeline

The root `Jenkinsfile` is responsible for the continuous-integration side of the project.

### Pipeline stages

1. **Validate Parameters**  
   The frontend and backend Docker image tags are required before the build starts.

2. **Workspace Cleanup**  
   Jenkins starts from a clean workspace.

3. **Git Checkout**  
   The pipeline checks out this GitHub repository from `master`.

4. **Trivy Filesystem Scan**  
   The source tree is scanned for known security problems.

5. **OWASP Dependency-Check**  
   Application dependencies are checked for known vulnerabilities.

6. **SonarQube Analysis**  
   Static analysis is performed for code quality and security visibility.

7. **SonarQube Quality Gate**  
   The pipeline stops if the configured quality gate is not satisfied.

8. **Environment Preparation**  
   The automation scripts prepare the runtime configuration used by the original deployment workflow. Secrets are not committed to this repository.

9. **Docker Build**  
   Backend and frontend container images are created.

10. **Docker Hub Push**  
    Jenkins authenticates using Jenkins-managed credentials and publishes the images.

11. **GitOps Handoff**  
    The successful CI build passes the image tags to the GitOps deployment job.

### Image names

```text
amarkarale/wanderlust-backend-beta:<tag>
amarkarale/wanderlust-frontend-beta:<tag>
```

Docker credentials are deliberately stored in Jenkins and are **not** written into the Jenkinsfile.

---

# 🔁 GitOps / CD pipeline

`GitOps/Jenkinsfile` updates the Kubernetes manifests with the exact Docker image tags generated by CI.

The GitOps job:

1. Receives the frontend and backend image tags.
2. Checks out the repository.
3. Updates `kubernetes/backend.yaml`.
4. Updates `kubernetes/frontend.yaml`.
5. Commits the manifest change.
6. Pushes the new desired state to GitHub.
7. Argo CD detects the Git change.
8. Argo CD synchronizes the application into EKS.

This keeps Git as the source of truth for the Kubernetes workload versions.

---

# ☸️ Kubernetes deployment

The `kubernetes/` directory contains the desired state for the application platform.

### Application resources

- `namespace.yaml` — creates the `wanderlust` namespace
- `persistentVolume.yaml` — MongoDB persistent storage definition
- `persistentVolumeClaim.yaml` — MongoDB storage claim
- `mongodb.yaml` — MongoDB deployment/service
- `redis.yaml` — Redis deployment/service
- `backend.yaml` — backend deployment/service
- `frontend.yaml` — frontend deployment/service

The detailed Kubernetes guide is available in [`kubernetes/README.md`](kubernetes/README.md).

---

# 🚢 Argo CD

The repository contains an Argo CD Application definition at:

```text
argocd/application.yaml
```

The application points Argo CD at the Kubernetes manifests in this repository and enables automated synchronization/self-healing behavior.

### Intended relationship

```text
GitHub
  │
  └── kubernetes/*.yaml
           │
           ▼
        Argo CD
           │
           ▼
         EKS
```

---

# 📊 Monitoring

The cluster monitoring stack used for this project is based on:

- Prometheus
- Prometheus Node Exporter
- kube-state-metrics
- Alertmanager
- Grafana

The final deployment exposed Grafana and Prometheus through AWS LoadBalancer services so the dashboards could be reached from a browser.

Monitoring is intentionally kept separate from the application manifests so it can be managed as a cluster platform component.

---

# 🏗️ Infrastructure as Code

The `terraform/` directory contains AWS infrastructure definitions.

Terraform values are parameterized instead of depending on another developer's local filesystem.

### Important

Terraform state and variable files containing environment-specific data are ignored by Git. Use a local `terraform.tfvars` file when recreating the infrastructure.

Example:

```bash
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Before using Terraform, provide your own AWS region, AMI, instance type, and SSH public-key path in the variables/configuration appropriate for your environment.

---

# 🔐 Security and secrets

This public repository intentionally **does not contain production secrets**.

The following are excluded by `.gitignore`:

- `.env` files
- Docker environment files
- Terraform state
- local Terraform variable files
- local build artifacts
- dependency folders

Safe templates are provided instead:

```text
backend/.env.example
frontend/.env.example
```

When creating a new environment, copy the example values to local/managed configuration and replace the placeholders with your own values.

### Never commit

```text
JWT_SECRET
MONGODB_URI credentials
Docker Hub passwords/tokens
AWS access keys
SSH private keys
Terraform state
```

The environment secret that was once used during the original deployment was intentionally removed from the public repository before publishing this cleaned version.

---

# 🐳 Docker

Both application services use multi-stage container builds.

### Backend

The backend image contains the Node.js API and starts the Express server on port `8080`.

### Frontend

The frontend is built from the React/Vite source and served as a production web application by Nginx.

This keeps development-only tooling out of the final frontend runtime image.

---

# 🧪 Testing

The backend contains unit and integration tests under:

```text
backend/tests/
```

The frontend contains Jest/React Testing Library tests under:

```text
frontend/src/__tests__/
```

Typical local commands:

```bash
cd backend
npm ci
npm test
```

```bash
cd frontend
npm ci
npm test
npm run build
```

---

# 🖥️ Local development

The repository also contains `docker-compose.yml` for running the application services together.

Before using Docker Compose, create local environment files from the safe examples:

```bash
cp backend/.env.example backend/.env.docker
cp frontend/.env.example frontend/.env.docker
```

Then replace the placeholders with values appropriate for your local environment.

Start the stack with:

```bash
docker compose up --build
```

Stop it with:

```bash
docker compose down
```

---

# 📸 Project visuals

The repository contains the original architecture and deployment visuals used to document the project.

## Architecture

![Architecture](Assets/architectures.png)

## CI/CD flow

![Flow](Assets/flow.png)

## Kubernetes screenshots

| Area | Reference |
|---|---|
| Cluster nodes | [`nodes.png`](kubernetes/assets/nodes.png) |
| Namespace | [`namespace create.png`](kubernetes/assets/namespace%20create.png) |
| Kubernetes context | [`context wanderlust.png`](kubernetes/assets/context%20wanderlust.png) |
| CoreDNS | [`get-coredns.png`](kubernetes/assets/get-coredns.png) |
| CoreDNS replica update | [`edit-coredns.png`](kubernetes/assets/edit-coredns.png) |
| MongoDB | [`mongo.png`](kubernetes/assets/mongo.png) |
| Redis | [`redis.png`](kubernetes/assets/redis.png) |
| Persistent volume | [`pv.png`](kubernetes/assets/pv.png) |
| Persistent volume claim | [`pvc.png`](kubernetes/assets/pvc.png) |
| Backend | [`backend.png`](kubernetes/assets/backend.png) |
| Frontend | [`frontend.png`](kubernetes/assets/frontend.png) |
| Backend environment reference | [`backend.env.docker.png`](kubernetes/assets/backend.env.docker.png) |
| Frontend environment reference | [`frontend.env.docker.png`](kubernetes/assets/frontend.env.docker.png) |
| Docker backend build | [`docker backend build.png`](kubernetes/assets/docker%20backend%20build.png) |
| Docker frontend build | [`docker frontend build.png`](kubernetes/assets/docker%20frontend%20build.png) |
| Docker images | [`docker images.png`](kubernetes/assets/docker%20images.png) |
| Docker login | [`docker login.png`](kubernetes/assets/docker%20login.png) |
| All workloads | [`all-deps.png`](kubernetes/assets/all-deps.png) |
| Application | [`app.png`](kubernetes/assets/app.png) |

These images are documentation references from the project's implementation and are kept as visual evidence of the deployment workflow.

---

# 📌 Important notes for anyone building this project

This repository is designed to be **understood and rebuilt**, not copied with hidden credentials.

Before starting a new deployment, each builder should provide their own:

- AWS account and region
- EKS cluster/infrastructure
- Jenkins installation and node/agent labels
- Jenkins credentials
- Docker Hub account and access token
- SonarQube configuration
- Argo CD installation and repository access
- Kubernetes secrets
- DNS/load-balancer endpoints

The exact environment values used in the original deployment are deliberately not published.

---

# 🛠️ Rebuild order

For someone rebuilding the project from this repository, the recommended order is:

1. Provision AWS infrastructure.
2. Create/configure the EKS cluster.
3. Install Jenkins and configure its required tools/credentials.
4. Configure SonarQube and the Jenkins quality gate.
5. Configure Docker Hub credentials in Jenkins.
6. Build and publish the backend/frontend images.
7. Configure the GitOps Jenkins job.
8. Install Argo CD in the cluster.
9. Apply/register `argocd/application.yaml`.
10. Let Argo CD synchronize the Kubernetes manifests.
11. Install Prometheus/Grafana for monitoring.
12. Verify workloads, services, logs, metrics, and application access.

---

# ✅ Final outcome

The finished architecture gives a complete DevSecOps + GitOps chain:

```text
Code
  ↓
GitHub
  ↓
Jenkins CI
  ↓
Security / Quality
  ├── Trivy
  ├── OWASP Dependency-Check
  └── SonarQube
  ↓
Docker Build
  ↓
Docker Hub
  ↓
GitOps Jenkins
  ↓
GitHub desired-state update
  ↓
Argo CD
  ↓
Amazon EKS
  ↓
Wanderlust application
  ↓
Prometheus + Grafana monitoring
```

---

## 👨‍💻 Author

**Amar Karale**

This repository is maintained as my personal DevOps / Cloud Engineering project and learning portfolio.

---

## 📄 License

MIT License — see [`LICENSE`](LICENSE).
