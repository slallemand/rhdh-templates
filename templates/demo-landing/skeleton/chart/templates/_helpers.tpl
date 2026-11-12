{{- define "demo-landing.name" -}}
{{- default .Chart.Name .Values.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "demo-landing.labels" -}}
app.kubernetes.io/name: {{ include "demo-landing.name" . }}
app.kubernetes.io/instance: {{ include "demo-landing.name" . }}
app.kubernetes.io/part-of: {{ include "demo-landing.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.openshift.io/runtime: nginx
backstage.io/kubernetes-id: {{ .Values.backstage.kubernetesId | default (include "demo-landing.name" .) }}
{{- end -}}

{{- define "demo-landing.selectorLabels" -}}
app.kubernetes.io/name: {{ include "demo-landing.name" . }}
app.kubernetes.io/instance: {{ include "demo-landing.name" . }}
{{- end -}}
