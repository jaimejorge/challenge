# Troubleshoot Installation

## Setup

The kubeconfig is created automatically during `make install`. If it's missing or corrupted:

```bash
# Regenerate kubeconfig
make kubeconfig

# Set it for kubectl
export KUBECONFIG=.kube/config
```

Or use it inline with each command: `KUBECONFIG=.kube/config kubectl ...`

## Quick checks

```bash
# Check cluster and diagnose issues (shows apps, warnings for Unknown/Degraded)
make check

# View all pods
kubectl get pods -A

# Check ArgoCD apps status (short form)
kubectl get apps -A
```

## Common issues

### Kind cluster not starting

```bash
# Check Docker is running
docker ps

# Delete and recreate cluster
make clean
make install
```

### ArgoCD app shows Unknown sync status

This usually means ArgoCD can't reach the Git repository or there's a manifest error.

```bash
# Check the app conditions
kubectl get application bootstrap -n argocd -o jsonpath='{.status.conditions}' | jq

# View sync errors
kubectl describe application bootstrap -n argocd | grep -A 10 "Conditions:"

# Check argocd-repo-server logs (handles git operations)
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server --tail=50

# Force a refresh from Git
kubectl patch application bootstrap -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

### ArgoCD apps stuck in Progressing

Apps in this project:
- `bootstrap` - App-of-apps, deploys all other apps
- `ingress-nginx` - Ingress controller
- `http-https-echo` - Test application
- `cloudnative-pg-operator` - CloudNativePG operator
- `postgresql-cluster` - PostgreSQL database
- `v-metrics` - VictoriaMetrics + Grafana

```bash
# Check app sync status
kubectl get applications -n argocd -o wide

# View specific app details
kubectl describe application bootstrap -n argocd
kubectl describe application ingress-nginx -n argocd
kubectl describe application http-https-echo -n argocd
kubectl describe application cloudnative-pg-operator -n argocd
kubectl describe application postgresql-cluster -n argocd
kubectl describe application v-metrics -n argocd

# Force sync an app
kubectl patch application <app-name> -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'
```

### Ingress not working

```bash
# Check ingress-nginx pods
kubectl get pods -n ingress-nginx

# Check ingress resources
kubectl get ingress -A

# View ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### PostgreSQL not ready

```bash
# Check CNPG operator
kubectl get pods -n cnpg-system

# Check PostgreSQL cluster
kubectl get cluster -n postgresql

# View cluster events
kubectl describe cluster postgresql -n postgresql
```

### Grafana/VictoriaMetrics not accessible

```bash
# Check monitoring namespace
kubectl get pods -n monitoring

# Check services
kubectl get svc -n monitoring

# View pod logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

## View logs

```bash
# ArgoCD server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# ArgoCD application controller
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# All events sorted by time
kubectl get events -A --sort-by='.lastTimestamp' | tail -30
```

## Reset everything

```bash
make clean && make install
```
