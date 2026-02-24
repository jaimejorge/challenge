# Alerting

The monitoring chart ships with VMRule resources for PostgreSQL and the HTTP Echo service. They're on by default.

## Toggle alerts

In `apps/monitoring/values.yaml`:

```yaml
alerts:
  httpEcho:
    enabled: true
  postgresql:
    enabled: true
```

## PostgreSQL alerts

| Alert | Severity | Fires after | What it means |
|-------|----------|-------------|---------------|
| PostgreSQLDown | critical | 1m | CNPG collector stopped responding |
| PostgreSQLSplitBrain | critical | 1m | More than one primary, data corruption risk |
| PostgreSQLBackupFailed | critical | 15m | WAL archiving keeps failing |
| PostgreSQLReplicaLag | warning | 5m | Replication lag >30s |
| PostgreSQLReplicaLagSize | warning | 5m | Replication lag >100MB |
| PostgreSQLHighConnections | warning | 5m | >90% of max_connections used |
| PostgreSQLTooManyDeadTuples | warning | 30m | Dead tuples >10%, needs VACUUM |
| PostgreSQLInactiveReplicationSlots | warning | 30m | Inactive replication slot sitting around |
| PostgreSQLPromotedNode | warning | 1m | A standby got promoted to primary |
| PostgreSQLHighSequentialScans | warning | 10m | Lots of sequential scans, probably missing indexes |

These come from CloudNativePG's built-in Prometheus exporter (`cnpg_*` metrics):

```bash
# Poke at the raw metrics
kubectl port-forward -n postgresql svc/postgresql-rw 9187:9187
curl localhost:9187/metrics
```

## HTTP Echo alerts

| Alert | Severity | Fires after | What it means |
|-------|----------|-------------|---------------|
| HttpEchoDown | critical | 1m | Service not responding |
| HttpEchoHighLatency | warning | 5m | p95 latency >1s |
| HttpEchoHighErrorRate | warning | 5m | 5xx rate >5% |

The echo app exposes Prometheus metrics at `/metrics` (needs `PROMETHEUS_ENABLED=true` in values).

## Checking alert state

In Grafana: open `make grafana-info`, then Alerting > Alert rules, filter by namespace `monitoring`.

Or directly in VMAlert:

```bash
kubectl port-forward -n monitoring svc/v-metrics-victoria-metrics-k8s-stack-vmalert 8080:8080
open http://localhost:8080/vmalert/alerts
```

## Editing alerts

The VMRule templates live in `apps/monitoring/templates/`:

- `vmrule-postgresql.yaml`
- `vmrule-http-echo.yaml`

Push your changes and ArgoCD picks them up. Or apply manually:

```bash
helm upgrade monitoring apps/monitoring -n monitoring
```

## Sending notifications

Alertmanager is included in the VictoriaMetrics stack but has no receivers configured by default. Add them in `apps/bootstrap/templates/victoriametrics.yaml`:

```yaml
alertmanager:
  config:
    receivers:
      - name: slack
        slack_configs:
          - api_url: https://hooks.slack.com/services/XXX
            channel: '#alerts'
```

More receiver types in the [Alertmanager docs](https://prometheus.io/docs/alerting/latest/configuration/).
