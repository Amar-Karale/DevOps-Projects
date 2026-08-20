# Docker image hardening

The application containers are hardened using several practical controls.

## Backend image

- Multi-stage build keeps the runtime image smaller.
- Production dependencies are installed with `npm ci --omit=dev`.
- npm cache is removed after installation.
- The runtime container runs as the non-root `node` user.
- Files copied into the runtime stage are owned by the runtime user.

## Frontend image

- React/Vite assets are compiled in a builder stage.
- The runtime image uses `nginxinc/nginx-unprivileged` instead of a root Nginx process.
- Only the built static assets are copied into the final image.

## Kubernetes runtime hardening

The backend and frontend deployments also use:

- `runAsNonRoot: true`
- `allowPrivilegeEscalation: false`
- Linux capability drop: `ALL`
- `seccompProfile: RuntimeDefault`
- CPU and memory requests/limits
- readiness and liveness probes
- more than one replica for the web workloads
- `revisionHistoryLimit` for safe rollback
- controlled `RollingUpdate` strategy

## Supply-chain hardening

Trivy is used at two points in CI:

1. Filesystem scan before image creation.
2. Container image scan after image creation.

For a stricter production gate, change `TRIVY_EXIT_CODE` in the Jenkinsfile from `0` to `1` so HIGH/CRITICAL findings fail the build.

## Further production improvements

For a production environment, the next hardening steps would be:

- sign images with Cosign
- generate and publish SBOMs
- enforce image signatures with Kyverno or Gatekeeper
- use a private registry such as Amazon ECR
- use a read-only root filesystem where the application permits it
- use a non-root NetworkPolicy-isolated namespace
