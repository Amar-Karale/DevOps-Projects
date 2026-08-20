# Wanderlust DevOps Project — Problems Faced and Solutions

This document records the main technical problems encountered while building, debugging, deploying, and publishing the Wanderlust DevOps project. It is written as a practical troubleshooting record so another engineer can understand not only the final architecture, but also the failures that occurred and how they were resolved.

> **Note:** This document records the problems actually encountered during the project work and the solutions used. Later improvements such as Trivy, CloudWatch, CloudFront, container hardening, and additional Terraform resources are documented separately as project enhancements rather than being presented as problems that occurred during the original deployment.

---

## 1. Docker build failed because `.env.docker` was missing

### Problem

The frontend Docker build stopped at:

```text
COPY failed: file not found in build context or excluded by .dockerignore:
stat .env.docker: file does not exist
```

The Dockerfile expected:

```dockerfile
COPY .env.docker .env.local
```

but the file did not exist inside the `frontend/` build context.

### Investigation

The following confirmed the problem:

```bash
cd frontend
ls -la .env.docker
```

which returned:

```text
ls: cannot access '.env.docker': No such file or directory
```

There was also no `.dockerignore` responsible for excluding the file.

### Solution

The environment file was created in the correct directory:

```bash
echo 'VITE_API_PATH="http://<backend-endpoint>:31100"' > .env.docker
```

The file was then verified:

```bash
cat .env.docker
```

After that, the frontend Docker build could find the file.

### Lesson

Docker `COPY` paths are relative to the build context, not the directory from which the Dockerfile was conceptually designed. Always verify the build context and required files before debugging Docker itself.

---

## 2. The automation scripts referenced a deleted/incorrect EC2 instance

### Problem

Both automation scripts initially contained an old EC2 instance ID:

```bash
INSTANCE_ID="i-03f0fa0e41822a1f3"
```

AWS returned:

```text
InvalidInstanceID.NotFound
```

### Investigation

The script used:

```bash
aws ec2 describe-instances --instance-ids "$INSTANCE_ID"
```

so a stale instance ID caused the public IP lookup to fail.

### Solution

The script was temporarily updated to the correct running EC2 instance ID used during the deployment. The scripts were then committed to GitHub.

Later, once the EC2 instance was deleted, the project was improved so the public version should not depend on a fixed EC2 instance ID. The reusable version now favors externally supplied configuration instead of embedding a machine-specific instance ID in source code.

### Lesson

Infrastructure identifiers that can change or be destroyed should not be hard-coded into application automation.

---

## 3. Frontend automation failed because the file did not exist

### Problem

Running:

```bash
bash updatefrontendnew.sh
```

produced:

```text
cat: ../frontend/.env.docker: No such file or directory
ERROR: File not found.
```

### Solution

The missing file was created explicitly in the frontend directory:

```bash
cd ../frontend
cat > .env.docker <<EOF
VITE_API_PATH="http://<backend-endpoint>:31100"
EOF
```

The script was then rerun and verified with:

```bash
cat ../frontend/.env.docker
```

### Lesson

A script that updates a configuration file should either create the file when absent or fail with a clear, intentional message. This also exposed the importance of testing automation from the exact directory Jenkins uses.

---

## 4. `COPY` was mistakenly entered as a Linux shell command

### Problem

After fixing the file, the command:

```text
COPY .env.docker .env.local
```

was entered directly into the Ubuntu shell and returned:

```text
COPY: command not found
```

### Root cause

`COPY` is a Dockerfile instruction. It is not a Linux command.

### Solution

The command was removed from the shell workflow and kept only inside the Dockerfile where it belongs.

### Lesson

Dockerfile instructions such as `FROM`, `COPY`, `RUN`, and `CMD` must be executed by Docker during an image build, not typed directly into Bash.

---

## 5. Git add failed because the repository path was wrong

### Problem

From inside the `Automations/` directory, this command was used:

```bash
git add Automations/updatefrontendnew.sh
```

Git returned:

```text
fatal: pathspec 'Automations/updatefrontendnew.sh' did not match any files
```

### Root cause

The current working directory was already `Automations/`, so the path should have been relative to that directory.

### Solution

The correct command was:

```bash
git add updatefrontendnew.sh
```

Then the change was committed and pushed successfully.

### Lesson

Always run `pwd` and `git status` before using a relative Git path.

---

## 6. Docker Hub login failed with `unauthorized: incorrect username or password`

### Problem

The CI pipeline initially failed during Docker Hub login:

```text
Error response from daemon:
Get "https://registry-1.docker.io/v2/": unauthorized: incorrect username or password
```

The Jenkins log also showed a warning about passing a secret through Groovy string interpolation.

### Root cause

The Jenkins credential either contained the wrong Docker Hub username/token combination or the pipeline was using an old credential configuration. The original pipeline also used an insecure command pattern similar to:

```bash
docker login -u ... -p ...
```

### Solution

A new Docker Hub credential was created in Jenkins using the correct Docker Hub username and access token.

The pipeline was changed to use Jenkins-managed credentials and `--password-stdin` rather than putting the password on the command line.

The successful pattern was:

```bash
echo "$DOCKER_PASS" | docker login \
  --username "$DOCKER_USER" \
  --password-stdin
```

After this change the log showed:

```text
Login Succeeded
```

and both Docker images were pushed successfully.

### Lesson

Use Docker Hub access tokens instead of passwords and never place secrets directly in pipeline source code.

---

## 7. Jenkins warned about insecure Groovy secret interpolation

### Problem

Jenkins reported:

```text
Warning: A secret was passed to "sh" using Groovy String interpolation, which is insecure.
```

### Root cause

The pipeline passed a credential value into a double-quoted Groovy string. Groovy could interpolate the secret before the shell received it.

### Solution

The pipeline was changed to use `withCredentials` and a single-quoted shell block, allowing the shell environment variables to be expanded by the shell rather than Groovy.

### Lesson

Jenkins credentials should be bound through `withCredentials`, and shell blocks should avoid Groovy interpolation of secret values.

---

## 8. Docker images were pushed successfully, but the pipeline still needed consistent image naming

### Problem

Different stages of the project used different Docker Hub namespaces, including the old namespace and the final personal namespace.

### Solution

The project was standardized on:

```text
amarkarale/wanderlust-backend-beta
amarkarale/wanderlust-frontend-beta
```

The CI pipeline, GitOps pipeline, and Kubernetes manifests were aligned to the same names.

### Lesson

Container registry names are part of the deployment contract. CI, CD, Kubernetes manifests, and documentation must agree on the exact repository and tag.

---

## 9. GitHub push failed because the remote already contained commits

### Problem

After creating a local repository and making an initial commit, pushing to GitHub returned:

```text
! [rejected]        master -> master (fetch first)
error: failed to push some refs
```

### Root cause

The GitHub repository already contained commits that were not present in the newly initialized local repository.

### Solution

The repository history needed to be synchronized before replacing/pushing the local project state. The final public repository was then updated through GitHub with the cleaned project files.

### Lesson

When a GitHub repository already contains history, do not assume a newly initialized local repository can fast-forward directly into it.

---

## 10. Argo CD Application creation used a placeholder command incorrectly

### Problem

This command was entered literally:

```bash
kubectl apply -f <your-argocd-application.yaml>
```

Bash returned:

```text
-bash: syntax error near unexpected token `newline'
```

### Root cause

`<your-argocd-application.yaml>` was example notation, not a real filename. Bash interpreted the `<` character as shell redirection syntax.

### Solution

A real Argo CD Application manifest was created in the repository and the actual file path was used.

### Lesson

Placeholder notation in documentation must be replaced by an actual path before executing the command.

---

## 11. Argo CD initially had no Application

### Problem

`argocd app list` returned no applications:

```text
NAME  CLUSTER  NAMESPACE  PROJECT  STATUS  HEALTH ...
```

### Solution

The Wanderlust Argo CD Application was created to point to:

```text
Repository: https://github.com/Amar-Karale/DevOps-Projects.git
Path: kubernetes
Destination: EKS cluster
Namespace: wanderlust
```

The Application was subsequently added to the repository as declarative GitOps configuration.

### Lesson

Argo CD only reconciles applications that have actually been registered as Argo CD Applications.

---

## 12. Argo CD reported that another operation was already in progress

### Problem

Immediately after creating the Application, this command failed:

```bash
argocd app sync wanderlust
```

with:

```text
rpc error: code = FailedPrecondition desc = another operation is already in progress
```

### Root cause

Argo CD had already started an automated synchronization because automated sync was enabled.

### Solution

Instead of repeatedly forcing another sync operation, the Application status was inspected with:

```bash
argocd app get wanderlust
```

### Lesson

When automated synchronization is enabled, a manual sync command may race with an existing Argo CD operation. Inspect the current operation first.

---

## 13. Argo CD resources failed because the `wanderlust` namespace did not exist

### Problem

Argo CD showed errors like:

```text
namespaces "wanderlust" not found
```

for the backend, frontend, Redis, MongoDB, services, and PVC.

### Root cause

The resources declared `namespace: wanderlust`, but the namespace itself had not yet been created.

### Solution

A dedicated Kubernetes manifest was added:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: wanderlust
```

The Argo CD Application was also configured with `CreateNamespace=true`.

### Lesson

Namespaces are part of the Kubernetes desired state and should be explicitly declared or created by the Argo CD sync configuration.

---

## 14. `kubectl get pods` showed no application workloads

### Problem

After the initial Argo CD failure:

```bash
kubectl get pods
```

returned:

```text
No resources found in default namespace.
```

### Root cause

The workloads were intended for the `wanderlust` namespace, while the command queried the `default` namespace.

### Solution

The correct command was:

```bash
kubectl get pods -n wanderlust
```

### Lesson

Always include the expected namespace when diagnosing Kubernetes resources.

---

## 15. The wrong Argo CD controller resource was queried

### Problem

This command failed:

```bash
kubectl -n argocd logs deployment/argocd-application-controller
```

with:

```text
deployments.apps "argocd-application-controller" not found
```

### Root cause

The Argo CD application controller was running as a StatefulSet rather than a Deployment.

### Solution

The actual workload type was identified first:

```bash
kubectl -n argocd get pods
```

and the controller pod was used directly for logs when necessary.

### Lesson

Do not assume every Kubernetes component is a Deployment. Check the actual resource type before querying logs.

---

## 16. The EKS cluster name was confused with the Argo CD destination name

### Problem

The AWS CLI returned:

```text
clusters:
  - wanderlust
```

but an attempted lookup used:

```bash
aws eks describe-cluster --name wanderlust-eks-cluster
```

which failed with:

```text
ResourceNotFoundException
No cluster found for name: wanderlust-eks-cluster.
```

### Solution

The real EKS cluster name was obtained from:

```bash
aws eks list-clusters
```

and used consistently in AWS commands.

### Lesson

Keep the EKS cluster's real AWS name separate from friendly names, Argo CD Application names, and destination aliases.

---

## 17. The EC2 instance dependency eventually became obsolete

### Problem

The project originally used EC2 public IP addresses in automation and application configuration. The EC2 instance was later deleted.

### Impact

Any script or environment file that depended on that specific public IP or instance ID could no longer be considered reusable.

### Solution

The public repository was cleaned so runtime endpoints, credentials, and infrastructure identifiers are supplied as environment-specific configuration rather than being treated as permanent source-code values.

The final architecture was also extended to support stable AWS endpoints such as load balancers and CloudFront rather than relying on ephemeral EC2 public IPs.

### Lesson

Cloud infrastructure is disposable. Application code and GitOps configuration should not assume that an individual EC2 instance will exist forever.

---

## 18. Frontend environment handling needed to work both locally and in Jenkins

### Problem

The frontend requires a Vite build-time API URL. The original deployment relied on a `.env.docker` file, but that file is intentionally not stored in Git.

### Solution

The CI pipeline was changed to create the frontend environment file during the build using a Jenkins parameter/environment value:

```text
VITE_API_PATH
```

The public repository only contains a safe `.env.example`.

### Lesson

Build-time frontend configuration can be generated in CI without committing environment-specific values to source control.

---

## 19. Docker frontend production serving needed improvement

### Problem

The original frontend workflow was designed around a development-oriented runtime pattern, which is not ideal for a production deployment.

### Solution

The frontend was converted to a production-style multi-stage build:

```text
Node build stage
      ↓
Compiled dist/
      ↓
Unprivileged Nginx runtime
```

The final runtime uses `nginxinc/nginx-unprivileged` and serves the compiled Vite application on port `8080` inside the container.

### Lesson

Development servers and production web servers have different responsibilities. A production container should contain only what is required to serve the built application.

---

## 20. Kubernetes frontend and backend deployments needed stronger production defaults

### Problem

The original Kubernetes manifests were functional but lacked several production-oriented controls.

### Solution

The project was hardened with:

- two replicas
- RollingUpdate strategy
- `revisionHistoryLimit`
- readiness probes
- liveness probes
- CPU/memory requests and limits
- non-root execution
- dropped Linux capabilities
- disabled privilege escalation
- `seccompProfile: RuntimeDefault`

### Lesson

A workload that runs successfully is not automatically production-ready. Availability, health checks, resource control, and security context matter just as much as the container image itself.

---

## 21. Runtime secrets needed to be removed from Git

### Problem

A real backend environment file had been used during the original deployment. Publicly committing environment files creates a risk of exposing JWT secrets, database credentials, or other sensitive configuration.

### Solution

The live `.env` file was removed from the public repository. The project now provides:

```text
backend/.env.example
frontend/.env.example
kubernetes/secrets/backend-env.example.yaml
```

Real values must be created separately in the target environment.

### Important security action

Any credential or secret that was ever exposed in Git should be rotated even after the file is removed.

### Lesson

Secrets are configuration, not source code.

---

## 22. Docker credential warning about unencrypted local storage

### Problem

After a successful Docker login, Docker reported:

```text
Your credentials are stored unencrypted in '/home/ubuntu/.docker/config.json'.
```

### Root cause

Docker had no credential helper configured for the Jenkins agent user.

### Solution

The login itself was corrected to use `--password-stdin`. The remaining warning was recognized as a credential-helper configuration issue rather than a Docker Hub authentication failure.

### Improvement

For a long-lived Jenkins agent, configure an appropriate Docker credential helper or use a Jenkins-managed mechanism that avoids persistent plaintext credential storage in the agent's Docker config.

### Lesson

Authentication success and credential-at-rest security are separate concerns.

---

## 23. GitOps pipeline initially contained another person's repository references

### Problem

The original GitOps Jenkinsfile referenced an old repository and old Docker Hub namespace.

### Solution

The GitOps pipeline was changed to use this project repository:

```text
https://github.com/Amar-Karale/DevOps-Projects.git
```

and these image names:

```text
amarkarale/wanderlust-backend-beta
amarkarale/wanderlust-frontend-beta
```

### Lesson

When adapting a project template, every source-control URL, container registry reference, email address, credential ID, path, and infrastructure identifier must be reviewed rather than changing only the application code.

---

## 24. Terraform originally depended on machine-specific configuration

### Problem

Infrastructure code contained environment-specific assumptions that were unsuitable for a public repository.

### Solution

Terraform variables were introduced for values such as:

```text
AWS region
AMI ID
instance type
key pair
public key
SSH CIDR ranges
```

Terraform state and local variable files were excluded from Git.

### Lesson

Terraform should describe infrastructure, not one developer's workstation.

---

## 25. Monitoring services initially required manual exposure

### Problem

Prometheus and Grafana were initially installed as `ClusterIP` services, which meant they were not directly accessible from an external browser.

### Solution

The monitoring services were changed to `LoadBalancer` where browser access was required. AWS provisioned public load balancer DNS names for Prometheus and Grafana.

### Lesson

A Kubernetes monitoring stack can be healthy internally while still being inaccessible externally. Service type and network exposure must match the operational requirement.

---

## 26. Need for a stable frontend entry point

### Problem

Using NodePort and EC2 public IP addresses for application access made the endpoint dependent on infrastructure details.

### Solution

The public project was improved so the frontend uses an AWS `LoadBalancer` service, creating a stable AWS-managed endpoint. CloudFront + WAF was then added as an optional edge layer.

### Lesson

For public applications, use stable managed endpoints rather than tying browser traffic directly to individual compute nodes.

---

## 27. GitOps rollback needed to preserve Git as the source of truth

### Problem

A Kubernetes deployment can be rolled back manually, but a manual rollback can diverge the live cluster from Git.

### Solution

Two rollback approaches were documented:

### Emergency cluster rollback

```bash
kubectl rollout undo deployment/<name>
```

### Preferred GitOps rollback

Revert the bad Kubernetes image-tag commit in Git and allow Argo CD to reconcile the reverted desired state.

### Lesson

In a GitOps architecture, the long-term rollback should happen through Git whenever practical.

---

# Final troubleshooting checklist

When debugging this project, the following order proved useful:

```text
1. Check the current directory: pwd
2. Check Git state: git status
3. Check required files: ls -la
4. Check environment configuration
5. Validate Docker build context
6. Validate Docker image names/tags
7. Validate Jenkins credentials
8. Validate AWS identity and resource names
9. Validate EKS cluster and kubectl context
10. Check Kubernetes namespace
11. Check pods / deployments / services
12. Check Argo CD Application status
13. Check Argo CD operation state
14. Check application logs
15. Check rollout status
16. Check Prometheus/Grafana/CloudWatch
```

---

# Key engineering lessons from the project

## 1. Logs usually identified the problem faster than guessing

Examples included:

```text
file not found
InvalidInstanceID.NotFound
unauthorized: incorrect username or password
namespace not found
another operation is already in progress
```

Each message pointed directly toward the failing layer.

## 2. Keep configuration separate from source code

Environment files, credentials, IP addresses, EC2 IDs, and tokens should not be treated as permanent application code.

## 3. Treat Git as the source of truth for GitOps

CI creates images. GitOps updates desired state. Argo CD reconciles the cluster.

## 4. A working deployment is only the beginning

The project was later hardened with non-root containers, resource limits, probes, Trivy scanning, rollback tooling, AWS observability, CloudFront, and WAF.

## 5. Disposable infrastructure requires reproducible configuration

The EC2 instance was eventually deleted, which reinforced the importance of Terraform, environment variables, managed AWS endpoints, and declarative Kubernetes configuration.

---

# Summary

The Wanderlust project went through failures at almost every major DevOps layer:

```text
Application configuration
        ↓
Docker build context
        ↓
Automation scripts
        ↓
AWS resource discovery
        ↓
Jenkins credentials
        ↓
Docker Hub authentication
        ↓
Git repository synchronization
        ↓
Kubernetes namespace
        ↓
Argo CD synchronization
        ↓
EKS cluster naming / access
        ↓
Monitoring exposure
        ↓
Production hardening
```

The important outcome was not that the first deployment worked perfectly. The important outcome was learning how to diagnose each layer, isolate the real root cause, implement a targeted fix, verify the fix, and then turn the fix into a more reusable and secure project design.
