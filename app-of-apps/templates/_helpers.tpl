{{/*
Common sync policy for child Applications.
Provides automated sync with prune, selfHeal, retry with backoff, and standard syncOptions.
*/}}
{{- define "app-of-apps.syncPolicy" -}}
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  retry:
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 2m0s
    limit: 30
  syncOptions:
    - CreateNamespace=true
    - RespectIgnoreDifferences=true
    - SkipDryRunOnMissingResource=true
{{- end }}

{{/*
Returns the operator catalog source name.
When catalog snapshot is enabled, returns the custom CatalogSource name;
otherwise returns "redhat-operators".
*/}}
{{- define "app-of-apps.operatorSource" -}}
{{- if .Values.catalogSource.enabled -}}
{{ .Values.catalogSource.name }}
{{- else -}}
redhat-operators
{{- end -}}
{{- end -}}

{{/*
Common Application metadata with foreground finalizer.
Usage: {{ include "app-of-apps.metadata" (dict "name" "my-app" "namespace" .Values.argocd.namespace "syncWave" "0") }}
*/}}
{{- define "app-of-apps.metadata" -}}
metadata:
  name: {{ .name }}
  namespace: {{ .namespace }}
  labels:
    app.kubernetes.io/part-of: app-of-apps
  annotations:
    argocd.argoproj.io/sync-wave: "{{ .syncWave }}"
  finalizers:
    - resources-finalizer.argocd.argoproj.io/foreground
{{- end }}

{{/*
Install plan approval for operator Subscriptions: Automatic (default) or Manual.
*/}}
{{- define "app-of-apps.installPlanApproval" -}}
{{- $operators := .Values.operators | default dict -}}
{{- $operators.installPlanApproval | default "Automatic" -}}
{{- end -}}

{{/*
Exact operator version for one package: channel and startingCSV lines from
operators.pins (workshop-setup stage 000 writes them from platform/pinned-versions.json),
or nothing. Not used with the catalog snapshot (catalogSource.enabled), which pins by
catalog image instead. Call: include "app-of-apps.pin" (dict "root" $ "package" "<name>")
*/}}
{{- define "app-of-apps.pin" -}}
{{- $catalog := .root.Values.catalogSource | default dict -}}
{{- if not $catalog.enabled -}}
{{- $operators := .root.Values.operators | default dict -}}
{{- $pins := $operators.pins | default dict -}}
{{- $pin := get $pins .package | default dict -}}
{{- with $pin.channel }}
channel: {{ . }}
{{- end }}
{{- with $pin.startingCSV }}
startingCSV: {{ . }}
{{- end }}
{{- end -}}
{{- end -}}
