# Tutorial: deploy the stack

Get a local Kubernetes cluster running with GitOps, monitoring, and PostgreSQL. Takes about 10 minutes.

You need Docker installed and ~6GB of free RAM.

---

## 1. Clone the repo

```bash
git clone https://github.com/jaimejorge/gitops-k8s-lab.git
cd gitops-k8s-lab
```

## 2. Deploy everything

```bash
./start.sh
```

That builds the tools container and deploys the full stack. If you prefer doing it step by step:

```bash
make docker-build   # Build the tools container
make install        # Create kind cluster and deploy all apps via ArgoCD
```

## 3. TLS certificates (optional)

```bash
make tls        # Generate wildcard certificates (runs in Docker)
make trust-ca   # Trust the CA on your host (gets rid of browser warnings)
```

## 4. Wait for apps to sync

Open ArgoCD and watch everything come up:

```bash
make argocd-info                    # Get credentials
open https://argocd.localtest.me    # Open the UI
```

Give it a few minutes. Once everything shows "Synced" and "Healthy", you're good.

## 5. Open Grafana

```bash
make grafana-info                    # Get credentials
open https://grafana.localtest.me
```

It comes with dashboards for ArgoCD, CloudNativePG, and PostgreSQL already loaded.

## 6. Test the echo app

```bash
curl https://echo.localtest.me
```

You'll get a JSON response with the request headers, method, path, etc.

## 7. Connect to PostgreSQL

```bash
# Get the password
kubectl get secret -n postgresql postgresql-app \
  -o jsonpath='{.data.password}' | base64 -d

# Connect directly via NodePort (kind maps 30432 → host 5432)
psql -h localhost -p 5432 -U app -d app
```

---

## Interactive shell

If you want to poke around inside the tools container:

```bash
make run

# Then:
kubectl get pods -A
helm list -A
argocd app list
```

---

## Cleanup

```bash
make clean
```

Deletes the kind cluster and everything in it.

---

## What's next

- [Add a Grafana dashboard](howto/add-dashboard.md)
- [Add metrics scraping](howto/add-metrics-scrape.md)
- [Connect to PostgreSQL](howto/connect-postgresql.md)
- [Design decisions](explanation.md)
- [Config reference](reference.md)
