# Add metrics scraping

How to tell VictoriaMetrics where to find your app's metrics.

## VMPodScrape vs VMServiceScrape

| Resource | Targets | When to use |
|----------|---------|-------------|
| VMPodScrape | Pods directly | No Service, DaemonSets, per-pod metrics |
| VMServiceScrape | Via a Service | Apps with stable Services |

## Adding a VMPodScrape

For scraping pods directly (like CloudNativePG):

```yaml
apiVersion: operator.victoriametrics.com/v1beta1
kind: VMPodScrape
metadata:
  name: my-app
  namespace: monitoring  # Must be in monitoring namespace
spec:
  podMetricsEndpoints:
    - targetPort: 9187    # Port number on the pod
      path: /metrics
      interval: 30s
  selector:
    matchLabels:
      app: my-app         # Pod labels to match
  namespaceSelector:
    matchNames:
      - my-namespace      # Namespace where pods live
```

## Adding a VMServiceScrape

For scraping via Services (like ArgoCD):

```yaml
apiVersion: operator.victoriametrics.com/v1beta1
kind: VMServiceScrape
metadata:
  name: my-app
  namespace: monitoring  # Must be in monitoring namespace
spec:
  endpoints:
    - port: metrics       # Port NAME from the Service spec
      path: /metrics
      interval: 30s
  selector:
    matchLabels:
      app: my-app         # Service labels to match
  namespaceSelector:
    matchNames:
      - my-namespace      # Namespace where Service lives
```

## The difference in practice

The main thing: VMPodScrape takes a port **number** (`targetPort: 9187`) and hits the pod IP directly. VMServiceScrape takes a port **name** (`port: metrics`) and goes through the Service.

Use VMPodScrape for databases and stateful apps where you want per-pod metrics. VMServiceScrape works better for stateless services behind a Service.

## Finding metrics endpoints

```bash
# Check if the app exposes metrics
kubectl port-forward -n <namespace> <pod> 9090:9090
curl localhost:9090/metrics

# Find port name in the Service
kubectl get svc -n <namespace> <service> -o yaml | grep -A5 ports:

# Check pod labels
kubectl get pods -n <namespace> --show-labels
```

## Verifying it works

```bash
# Check VMAgent targets
curl -s http://vmsingle.localtest.me/targets | grep my-app

# Query metrics
curl -s "http://vmsingle.localtest.me/api/v1/series?match[]=my_metric_name" | jq
```

## Where to put scrape resources

VMPodScrape/VMServiceScrape resources go in the monitoring namespace. Add them as templates in `apps/monitoring/templates/`:

```
apps/monitoring/templates/
├── vmpodscrape-postgresql.yaml
├── vmservicescrape-argocd.yaml
└── vmservicescrape-myapp.yaml
```
