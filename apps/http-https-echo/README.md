# http-https-echo Helm Chart

Helm chart to deploy [mendhak/http-https-echo](https://github.com/mendhak/docker-http-https-echo), an HTTP/HTTPS echo server for testing and debugging.

## Chart Creation

### 1. Initial Scaffold with Helm

```bash
cd apps/
helm create http-https-echo
```



### 2. Configure Chart.yaml

```yaml
apiVersion: v2
name: http-https-echo
description: A Helm chart for Kubernetes
type: application
version: 0.1.0
appVersion: "39"  # Must match the image tag
```

### 3. Configure values.yaml

```yaml
replicaCount: 1

image:
  repository: mendhak/http-https-echo
  tag: 39
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

# Port where the container listens
containerPort: 8080

# Environment variables for the application
env:
  HTTP_PORT: "8080"
  HTTPS_PORT: "443"
  ENABLE_HTTPS: "false"

ingress:
  enabled: true
  className: traefik
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
  hosts:
    - host: echo.localhost.me
      paths:
        - path: /
          pathType: Prefix
  tls: []

securityContext: 
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000

livenessProbe:
  httpGet:
    path: /
    port: 8080

readinessProbe:
  httpGet:
    path: /
    port: 8080

resources: 
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

## Changes Made to Base Chart

### 1. Add environment variables support

In `templates/deployment.yaml`, add after `imagePullPolicy`:

```yaml
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          {{- if .Values.env }}
          env:
            {{- range $key, $value := .Values.env }}
            - name: {{ $key }}
              value: {{ $value | quote }}
            {{- end }}
          {{- end }}
          ports:
```

### 2. Configure dynamic containerPort

In `templates/deployment.yaml`:

```yaml
          ports:
            - name: http
              containerPort: {{ .Values.containerPort }}
              protocol: TCP
```

### 3. Configure Service with correct targetPort

In `templates/service.yaml`:

```yaml
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.containerPort }}
      protocol: TCP
      name: http
```

### 4. Configure probes with hardcoded port

In `values.yaml`, probes point directly to the container port:

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 8080

readinessProbe:
  httpGet:
    path: /
    port: 8080
```


## Usage

### Validate chart (dry-run)

```bash
helm template http-https-echo ./apps/http-https-echo
```

### Lint check

```bash
helm lint ./apps/http-https-echo
```

## Testing

### Included connection test

```bash
helm test http-https-echo
```

### Manual testing

```bash
# With curl
curl http://echo.localhost.me

# Port-forward directly to pod
kubectl port-forward svc/http-https-echo 8080:80
curl http://localhost:8080
```


