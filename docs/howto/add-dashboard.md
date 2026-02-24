# Add a Grafana dashboard

Download dashboards from grafana.com and deploy them through ArgoCD.

## Steps

### 1. Find the dashboard ID

Go to [grafana.com/dashboards](https://grafana.com/grafana/dashboards/) and grab the ID from the URL.

Some useful ones:
- `20417` CloudNativePG
- `1860` Node Exporter
- `12740` Kubernetes Pods

### 2. Download it

```bash
# From the host
make download-dashboard ID=1860

# With a specific revision and output name
make download-dashboard ID=1860 REV=latest NAME=node-exporter

# Or inside the Docker container
make run
./scripts/download-dashboard.sh 1860
```

The script downloads the JSON from the grafana.com API, replaces `${DS_PROMETHEUS}` with `VictoriaMetrics`, and saves it to `apps/monitoring/dashboards/`.

### 3. Commit and push

```bash
git add apps/monitoring/dashboards/
git commit -m "Add Node Exporter dashboard"
git push
```

### 4. Check ArgoCD

ArgoCD syncs automatically. Grafana's sidecar picks up new ConfigMaps with the `grafana_dashboard: "1"` label.

## How it works

The Helm chart uses `.Files.Glob` to turn every JSON file in `dashboards/` into a ConfigMap:

```yaml
{{- range $path, $bytes := .Files.Glob "dashboards/*.json" }}
# Creates ConfigMap for each dashboard
{{- end }}
```
