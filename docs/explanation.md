# Explanation



## Component choices

### kind over minikube/k3s

kind runs a full Kubernetes cluster using Docker containers as nodes. You get the real thing (etcd, scheduler, controller-manager), not a stripped-down distribution. That means control plane metrics work without extra config, and behavior is closer to what you'd see in production.

It starts fast (~30 seconds), needs no VM, and maps NodePorts to host ports natively. The Docker-in-Docker workflow also works without issues.

### ingress-nginx

Widely used, well documented, and kind supports it with the `ingress-ready=true` node label. Setting a `default-ssl-certificate` gives you wildcard TLS without per-ingress annotations. NodePort on 30080 (HTTP) and 30443 (HTTPS).

I went with ingress-nginx over Traefik mainly because the kind docs cover it in detail and the NodePort setup is straightforward.

### ArgoCD

Git is the source of truth. ArgoCD watches the repo and applies changes, fixing drift when it spots it. Sync waves control the deployment order. The App-of-Apps pattern means one Application resource bootstraps the whole stack. Push to git, everything else happens on its own.

### CloudNativePG

The operator handles failover, backups, and upgrades. With raw StatefulSets you'd have to wire all that up yourself. It ships with a Prometheus-compatible metrics endpoint (port 9187), and adding replicas means bumping the `instances` count. No Helm chart needed for the database itself, a CRD manifest is enough.


## Docker-based tooling

Everything runs inside a container (`scripts/run.sh`). You need Docker and make on the host. kubectl, helm, kind, argocd CLI, and mkcert all live in the image with pinned versions. No "works on my machine" problems, no version drift between contributors.

## Argocd Sync waves

Applications deploy in this order:

| Wave | What and why |
|------|-------------|
| -2 | ingress-nginx. Needs to be up before any Ingress resource works |
| -1 | argocd (self-managed) |
| 0 | cloudnative-pg-operator. CRDs must exist before Cluster resources |
| 1 | postgresql-cluster, victoriametrics |
| 2 | monitoring-dashboards |

Operators go first so their CRDs exist when the custom resources get applied. Dashboards go last because they need the metrics stack running.

## TLS with mkcert

Local HTTPS without browser warnings:

1. `mkcert -install` adds a CA to your system trust store
2. Generate a wildcard cert for `*.localtest.me`
3. Store it as a Kubernetes Secret (`localtest-tls`) in multiple namespaces
4. ingress-nginx uses it as the default certificate

`localtest.me` resolves to `127.0.0.1` already, so no need to touch `/etc/hosts`.

## Dashboard discovery

Grafana's sidecar watches for ConfigMaps labeled `grafana_dashboard: "1"`. When it finds one, it loads the dashboard.

```
ConfigMap with label grafana_dashboard: "1"
         │
         ▼
   Grafana Sidecar
         │
         ▼
   Dashboard loaded
```

The Helm chart uses `.Files.Glob` to create a ConfigMap per JSON file in `dashboards/`. Drop a `.json` file in there, push, and it shows up in Grafana. No manual wiring.
