# Project Assets

This directory contains the visual documentation used in the Wanderlust DevSecOps + GitOps project.

## Architecture diagram

`architectures.png` shows the major components and their relationships across the application, CI/CD platform, cloud infrastructure, Kubernetes, GitOps, and monitoring layers.

![Architecture](architectures.png)

## CI/CD and GitOps flow

`flow.png` illustrates the end-to-end delivery flow from source control through Jenkins, Docker, GitOps, Argo CD, and Kubernetes.

![CI/CD and GitOps flow](flow.png)

## DevSecOps + GitOps animation

`DevSecOps+GitOps.gif` provides a quick visual summary of how security checks and GitOps delivery fit into the project lifecycle.

![DevSecOps + GitOps](DevSecOps%2BGitOps.gif)

## Kubernetes screenshots

The Kubernetes screenshots live under `../kubernetes/assets/` and cover:

- cluster nodes and namespace setup
- Kubernetes context configuration
- CoreDNS configuration
- MongoDB and Redis
- persistent storage
- Docker builds and images
- backend and frontend deployments
- service/workload verification
- final application access

These images are retained as implementation evidence and learning references. Secrets, tokens, and machine-specific configuration are not stored in the visual assets.
