# Challenge K3s

Local Kubernetes development environment with GitOps.

## Documentation

| Section | Description |
|---------|-------------|
| [Tutorial](docs/tutorial.md) | Step-by-step guide to deploy the stack |
| [How-to Guides](docs/howto.md) | Task-specific instructions |
| [Reference](docs/reference.md) | Configuration and architecture |
| [Explanation](docs/explanation.md) | Design decisions and concepts |

## Quick Start

```bash
make install
```

## Access

| Service | URL |
|---------|-----|
| ArgoCD | https://argocd.localtest.me |
| Grafana | https://grafana.localtest.me |
| App | https://http-https-echo.localtest.me |
| VictoriaMetrics | https://vmsingle.localtest.me |

## Components

- **k3d** 
Lightweight Kubernetes:

This setup uses k3d, which runs a lightweight k3s Kubernetes cluster inside Docker. k3d was chosen for its fast startup time, low resource usage, and suitability for local cloud-native development.

- **ArgoCD** 
GitOps delivery:

This setup uses Argo CD for GitOps to ensure deployments are reproducible, auditable, and easy to update.
Running ./start.sh bootstraps the local cluster, installs Argo CD, and syncs all applications until they are Healthy.


- **CloudNativePG** 
PostgreSQL operator:

This setup uses CloudNativePG to deploy and manage PostgreSQL in a cloud-native way using a Kubernetes operator.

CloudNativePG was chosen instead of a traditional Helm-based PostgreSQL (Bitnami Helm chart)

- **VictoriaMetrics** - Monitoring stack
- **Traefik** - Ingress controller

##

