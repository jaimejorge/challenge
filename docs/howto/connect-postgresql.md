# Connect to PostgreSQL

## Via NodePort

Simplest option, no port-forward (kind maps NodePort 30432 → host 5432):

```bash
psql -h localhost -p 5432 -U app -d app
```

Connection string:
```
postgresql://app:<password>@localhost:5432/app
```

## Via kubectl port-forward

```bash
kubectl port-forward -n postgresql svc/postgresql-rw 5432:5432

# Then in another terminal
psql -h localhost -U app -d app
```

## Get the password

```bash
kubectl get secret -n postgresql postgresql-app -o jsonpath='{.data.password}' | base64 -d
```

## From inside the cluster

Three service endpoints:
- `postgresql-rw.postgresql.svc:5432` read/write (primary)
- `postgresql-ro.postgresql.svc:5432` read-only (replicas)
- `postgresql-r.postgresql.svc:5432` any instance
