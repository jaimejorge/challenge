# Reference

Ports, URLs, config, and how things connect.

## Architecture

```
![](./architecture.png)
```


## Config

### Environment variables (.env)

| Variable | Default | What it does |
|----------|---------|-------------|
| `IMAGE_NAME` | `gitops-k8s-lab:0.0.1` | Docker tools image |
| `CLUSTER_NAME` | `dev01` | kind cluster name |
| `ARGOCD_NAMESPACE` | `argocd` | ArgoCD namespace |
| `ARGOCD_RELEASE` | `argocd` | ArgoCD Helm release name |
| `ARGOCD_CHART_VERSION` | `9.4.3` | ArgoCD Helm chart version |
| `ARGOCD_DOMAIN` | `argocd.localtest.me` | ArgoCD ingress host |
| `ARGOCD_SYNC_TIMEOUT` | `300s` | Timeout waiting for apps to sync |
| `BOOTSTRAP_REPO_URL` | `https://github.com/jaimejorge/gitops-k8s-lab.git` | Git repo for ArgoCD |
| `BOOTSTRAP_TARGET_REVISION` | `feature/move-kind-docker-in-docker` | Git branch/tag |
| `BOOTSTRAP_PATH` | `apps/bootstrap` | Path to bootstrap chart |
| `BOOTSTRAP_DEST_NAMESPACE` | `default` | Destination namespace |
| `ECHO_APP_NAME` | `http-https-echo` | Echo app name |
| `ECHO_APP_NAMESPACE` | `default` | Echo app namespace |
| `ECHO_APP_SERVICE_PORT` | `80` | Echo service port |
| `ECHO_APP_LOCAL_PORT` | `8080` | Local port for echo |
| `TLS_DOMAIN` | `localtest.me` | Domain for certs |
| `TLS_SECRET_NAME` | `localtest-tls` | Kubernetes TLS secret name |
| `TLS_NAMESPACE` | `default` | TLS secret namespace |
| `GRAFANA_HOST` | `grafana.localtest.me` | Grafana ingress host |
| `GRAFANA_NAMESPACE` | `monitoring` | Grafana namespace |
| `POSTGRESQL_NAMESPACE` | `postgresql` | PostgreSQL namespace |
| `POSTGRESQL_SECRET` | `postgresql-app` | PostgreSQL credentials secret |
| `POSTGRESQL_HOST_PORT` | `5432` | Local port for PostgreSQL |



### Bootstrap values (apps/bootstrap/values.yaml)

| Variable | Default | What it does |
|----------|---------|-------------|
| `domain` | `localtest.me` | Base domain for ingresses |
| `ingressClassName` | `nginx` | Ingress controller class |
| `argocd.chartVersion` | `9.4.3` | ArgoCD Helm version |
| `victoriametrics.chartVersion` | `0.28.0` | VictoriaMetrics stack version |

## Ports

| Port | Service | Protocol |
|------|---------|----------|
| 30080 | ingress-nginx HTTP (NodePort) | HTTP |
| 30443 | ingress-nginx HTTPS (NodePort) | HTTPS |
| 30432 | PostgreSQL (NodePort) | TCP |
| 10254 | ingress-nginx metrics | HTTP |
| 8429 | VMSingle | HTTP |

## URLs

| URL | Service |
|-----|---------|
| https://argocd.localtest.me | ArgoCD |
| https://grafana.localtest.me | Grafana |
| https://echo.localtest.me | Echo app |
| https://vmsingle.localtest.me | VictoriaMetrics UI |
| https://vmagent.localtest.me | VMAgent targets |
| https://postgresql-metrics.localtest.me | PostgreSQL metrics |

## ArgoCD applications

| Application | Source | Sync wave | What it is |
|-------------|--------|-----------|------------|
| bootstrap | apps/bootstrap | n/a | App of Apps, deploys everything else |
| ingress-nginx | ingress-nginx chart | -2 | Ingress controller |
| argocd | argo-cd chart | -1 | ArgoCD itself (self-managed) |
| cloudnative-pg-operator | cloudnative-pg chart | 0 | PostgreSQL operator |
| postgresql-cluster | apps/postgresql | 1 | PostgreSQL instance |
| v-metrics | victoria-metrics-k8s-stack chart | 1 | Monitoring stack |
| monitoring-dashboards | apps/monitoring | 2 | Dashboards and scrape configs |
| http-https-echo | apps/http-https-echo | 0 | Echo demo app |
