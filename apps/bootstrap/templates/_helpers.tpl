{{/*
Common labels
*/}}
{{- define "bootstrap.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Git repo URL helper
*/}}
{{- define "bootstrap.gitRepoURL" -}}
{{ .Values.git.repoURL }}
{{- end }}

{{/*
Git branch helper
*/}}
{{- define "bootstrap.gitBranch" -}}
{{ .Values.git.branch }}
{{- end }}

{{/*
Domain helper (e.g., localtest.me)
*/}}
{{- define "bootstrap.domain" -}}
{{ .Values.domain }}
{{- end }}

{{/*
Full host helper (e.g., argocd.localtest.me)
*/}}
{{- define "bootstrap.host" -}}
{{- $subdomain := index . 0 -}}
{{- $root := index . 1 -}}
{{ $subdomain }}.{{ $root.Values.domain }}
{{- end }}
