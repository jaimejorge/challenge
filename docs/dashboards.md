# Monitoring Dashboards

This document describes the dashboards available in Grafana to monitor the cluster infrastructure.

## Grafana Access

- **URL**: http://grafana.localtest.me
- **User**: admin
- **Password**: Get it with `./scripts/grafana_info.sh`

---

# Default Dashboards (VictoriaMetrics k8s-stack)

These dashboards are included with the VictoriaMetrics k8s-stack installation and require no additional configuration.

## Kubernetes

### Kubernetes / Views / Global

**Dashboard**: Global view of the Kubernetes cluster.

**Main panels**:
- Total CPU and memory usage of the cluster
- Pods running/pending/failed by namespace
- Nodes and their status
- Total resources available vs used

**When to use**: Quick overview of the overall cluster state.

---

### Kubernetes / Views / Namespaces

**Dashboard**: Metrics grouped by namespace.

**Main panels**:
- CPU and memory by namespace
- Pods by namespace and state
- Network I/O by namespace
- Resource quotas and limits

**Variables**: `namespace`

**When to use**: Analyze resource consumption by namespace, identify problematic namespaces.

---

### Kubernetes / Views / Nodes

**Dashboard**: Detailed node metrics of the cluster.

**Main panels**:
- CPU, memory, disk per node
- Pod capacity vs actual
- Network throughput
- Node conditions (Ready, MemoryPressure, DiskPressure)

**Variables**: `node`

**When to use**: Diagnose node issues, capacity planning.

---

### Kubernetes / Views / Pods

**Dashboard**: Pod-level metrics.

**Main panels**:
- CPU and memory per pod/container
- Restarts
- Network I/O
- Pod state

**Variables**: `namespace`, `pod`

**When to use**: Debugging specific applications, resource consumption analysis.

---

## Kubernetes System

### Kubernetes / System / API Server

**Dashboard**: Kubernetes API Server metrics.

**Main panels**:
- Request rate by verb and resource
- Request latency (P50, P90, P99)
- Errors and success rate
- Watch connections
- Request queue depth

**When to use**: Diagnose API server performance issues, analyze usage patterns.

---

### Kubernetes / System / CoreDNS

**Dashboard**: Cluster DNS service metrics.

**Main panels**:
- Queries per second
- DNS resolution latency
- Cache hit ratio
- Errors and NXDOMAIN responses

**When to use**: DNS resolution issues, latency in service discovery.

---

### Kubernetes / System / Controller Manager

**Dashboard**: kube-controller-manager metrics.

**Main panels**:
- Work queue depth per controller
- Reconciliation rate
- Processing latency
- Errors per controller

**Note**: Requires configuring `bind-address: 0.0.0.0` in kind-config.yaml to expose metrics.

**When to use**: Diagnose controller issues (ReplicaSet, Deployment, etc).

---

### Kubernetes / System / Scheduler

**Dashboard**: kube-scheduler metrics.

**Main panels**:
- Scheduling rate
- Scheduling latency
- Pending pods
- Preemption attempts

**Note**: Requires configuring `bind-address: 0.0.0.0` in kind-config.yaml to expose metrics.

**When to use**: Scheduling issues, pending pods.

---

### Kubernetes / System / Kubelet

**Dashboard**: Kubelet metrics for each node.

**Main panels**:
- Pod/container operations rate
- Runtime operations latency
- Volume operations
- cgroup manager operations

**When to use**: Pods not starting, volume errors.

---

### Kubernetes / System / etcd

**Dashboard**: etcd metrics (cluster storage).

**Main panels**:
- Leader health
- Proposals committed/pending
- DB size
- WAL fsync latency
- Client traffic

**Note**: Requires configuring TLS or HTTP metrics in kind-config.yaml.

**When to use**: Persistence issues, cluster latency.

---

## VictoriaMetrics

### VictoriaMetrics / Single Node

**Dashboard**: VictoriaMetrics server metrics.

**Main panels**:
- Ingestion rate (samples/sec)
- Query rate and latency
- Active time series
- Storage size
- Cache hit ratio

**When to use**: Monitor metrics system health, capacity planning.

---

### VictoriaMetrics / vmagent

**Dashboard**: Scraping agent metrics.

**Main panels**:
- Active/failed scrape targets
- Samples scraped/sec
- Scrape duration
- Scraping errors
- Remotewrite throughput

**When to use**: Diagnose scraping issues, verify all targets are UP.

---

### VictoriaMetrics / vmalert

**Dashboard**: Alert evaluator metrics.

**Main panels**:
- Active alerts
- Recording rules executed
- Evaluation latency
- Evaluation errors

**When to use**: Verify active alerts, diagnose failing rules.

---

### VictoriaMetrics / Operator

**Dashboard**: VictoriaMetrics Operator metrics.

**Main panels**:
- Reconciliations by resource type
- Reconciliation errors
- Workqueue depth
- Controller latency

**When to use**: Issues with VMServiceScrape, VMPodScrape or other CRDs.

---

## Others

### Alertmanager Overview

**Dashboard**: Alertmanager status.

**Main panels**:
- Active and silenced alerts
- Notifications sent
- Notification latency
- Integration health

**When to use**: Verify alerts are being sent correctly.

---

### Grafana Overview

**Dashboard**: Grafana metrics.

**Main panels**:
- Active users
- Dashboard load times
- Datasource queries
- Errors

**When to use**: Grafana performance issues.

---

### Node Exporter Full

**Dashboard**: Detailed OS metrics for each node.

**Main panels**:
- CPU per core and mode (user, system, iowait)
- Memory (used, cached, buffers, swap)
- Disk (IOPS, throughput, latency, space)
- Network (packets, bytes, errors, drops)
- Load average
- Processes and threads
- Filesystems
- Systemd services

**Variables**: `node`

**When to use**: Deep system resource analysis, hardware/OS issues.

---

# Custom Dashboards

These dashboards are located in `apps/monitoring/dashboards/` and are managed by ArgoCD.

## 1. ArgoCD / Operational / Overview

**File**: `argocd-operational.json`

### Description
Operational dashboard for ArgoCD. Shows the state of deployed applications and sync activity.

### Main panels
- **Application Sync Status**: Application sync state (Synced, OutOfSync, Unknown)
- **Application Health**: Application health (Healthy, Degraded, Progressing, Suspended)
- **Sync Operations**: Sync operations by result (Success, Error, Failed)
- **Repository Server**: Repo server metrics (latency, requests)
- **Controller**: Application-controller metrics (reconciliations, workqueue)

### Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `namespace` | ArgoCD namespace | `argocd` |
| `job` | Metrics job | `argocd-*-metrics` |

### Key metrics
```promql
# Synced applications
argocd_app_info{sync_status="Synced"}

# Sync operations per second
rate(argocd_app_sync_total[5m])

# Repo-server latency
histogram_quantile(0.99, argocd_git_request_duration_seconds_bucket)
```

### When to use
- Verify applications are synced
- Diagnose deployment issues
- Monitor ArgoCD performance

---

## 2. CloudNativePG

**File**: `cloudnativepg.json`

### Description
Dashboard for PostgreSQL clusters managed by CloudNativePG (CNPG). Includes operator and database cluster metrics.

### Main sections

#### Operator Section
- **Ready Operator Pods**: Number of operator pods in ready state
- **Reconcile Errors**: Reconciliation errors by controller (cluster, backup, pooler)

#### Cluster Overview
- **Cluster Status**: Overall PostgreSQL cluster status
- **Instances**: PostgreSQL pods (primary/replica)
- **Replication Lag**: Replication delay in seconds

#### Database Metrics
- **Connections**: Active, idle, waiting connections
- **Transactions**: Commits and rollbacks per second
- **Tuples**: Read/write operations (fetched, inserted, updated, deleted)
- **Cache Hit Ratio**: PostgreSQL cache efficiency

#### Resource Usage
- **CPU Usage**: CPU usage per pod
- **Memory Usage**: Memory usage per pod
- **Disk I/O**: Disk read/write operations

### Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `operatorNamespace` | CNPG operator namespace | `cnpg-system` |
| `namespace` | PostgreSQL cluster namespace | `postgresql` |
| `instances` | PostgreSQL pods | `postgresql-1` |

### Key metrics
```promql
# Operator status
kube_pod_status_ready{namespace="cnpg-system", pod=~"cloudnative-pg-operator.+"}

# Active connections
cnpg_backends_total{state="active"}

# Replication lag
cnpg_pg_replication_lag

# Transactions per second
rate(cnpg_pg_stat_database_xact_commit[5m])
```

### When to use
- Verify PostgreSQL cluster health
- Diagnose performance issues
- Monitor replication
- Analyze database usage patterns

---

## 3. Kubernetes Nginx Ingress Prometheus NextGen

**File**: `kubernetes-nginx-ingress-prometheus-nextgen.json`

### Description
Dashboard for nginx-ingress-controller. Shows HTTP/HTTPS traffic entering the cluster.

### Main panels

#### Request Metrics
- **Requests/sec**: Request rate per ingress/service
- **Success Rate**: Percentage of successful responses (2xx/3xx)
- **Error Rate**: Percentage of errors (4xx/5xx)

#### Latency
- **Request Duration**: P50, P90, P95, P99 latency
- **Upstream Response Time**: Backend response time

#### Connections
- **Active Connections**: Active connections to ingress
- **Connection Rate**: New connections per second

#### Traffic
- **Bytes In/Out**: Inbound/outbound traffic
- **Request Size**: Request sizes

### Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `namespace` | Ingress namespace | `default`, `All` |
| `controller_class` | Ingress controller class | `nginx` |
| `ingress` | Ingress name | `echo-http-https-echo` |
| `service` | Backend service | `echo-http-https-echo` |

### Key metrics
```promql
# Requests per second
sum(rate(nginx_ingress_controller_requests[5m])) by (ingress)

# P99 latency
histogram_quantile(0.99, 
  sum(rate(nginx_ingress_controller_request_duration_seconds_bucket[5m])) by (le, ingress)
)

# 5xx errors
sum(rate(nginx_ingress_controller_requests{status=~"5.."}[5m])) by (ingress)
```

### When to use
- Analyze incoming HTTP traffic
- Detect errors in specific services
- Measure application latency
- Capacity planning

---

## Adding dashboards

See [How to add a Grafana dashboard](howto/add-dashboard.md) for step-by-step instructions.

---

## Troubleshooting

### Dashboard with no data

1. **Verify metrics exist**:
   ```bash
   curl -s 'http://vmsingle.localtest.me/api/v1/query?query=METRIC' | jq '.data.result | length'
   ```

2. **Verify dashboard variables**:
   - Open the dashboard in Grafana
   - Review variable values at the top
   - Check that filters are correct

3. **Verify scraping**:
   - Go to http://vmagent.localtest.me/targets
   - Find the corresponding target
   - Verify it is `UP`

### Dashboard not appearing in Grafana

1. Verify the file is committed and pushed
2. Verify the `monitoring-dashboards` app is synced in ArgoCD
3. Review Grafana sidecar logs:
   ```bash
   kubectl logs -n monitoring deploy/v-metrics-grafana -c grafana-sc-dashboard
   ```
