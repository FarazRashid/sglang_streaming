{{/*
Expand the name of the chart.
*/}}
{{- define "sglang.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "sglang.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "sglang.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sglang.labels" -}}
helm.sh/chart: {{ include "sglang.chart" . }}
{{ include "sglang.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "sglang.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sglang.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "sglang.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "sglang.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Common environment variables
*/}}
{{- define "sglang.commonEnv" -}}
{{- if .Values.global.huggingface.token }}
- name: HF_TOKEN
  value: {{ .Values.global.huggingface.token | quote }}
{{- end }}
{{- end }}

{{/*
Common volume mounts
*/}}
{{- define "sglang.commonVolumeMounts" -}}
{{- if .Values.storage.shm.enabled }}
- name: shm
  mountPath: /dev/shm
{{- end }}
{{- if .Values.storage.huggingfaceCache.enabled }}
- name: hf-cache
  mountPath: /root/.cache/huggingface
  readOnly: true
{{- end }}
- name: localtime
  mountPath: /etc/localtime
  readOnly: true
{{- if eq .Values.storage.model.type "hostPath" }}
- name: model
  mountPath: /model-data
{{- end }}
{{- if eq .Values.storage.model.type "pvc" }}
- name: model
  mountPath: /model-data
{{- end }}
{{- if .Values.rdma.enabled }}
- name: ib
  mountPath: {{ .Values.rdma.infinibandPath }}
{{- end }}
{{- end }}

{{/*
Common volumes
*/}}
{{- define "sglang.commonVolumes" -}}
{{- if .Values.storage.shm.enabled }}
- name: shm
  emptyDir:
    medium: Memory
    sizeLimit: {{ .Values.storage.shm.size }}
{{- end }}
{{- if .Values.storage.huggingfaceCache.enabled }}
- name: hf-cache
  hostPath:
    path: {{ .Values.storage.huggingfaceCache.hostPath }}
    type: Directory
{{- end }}
- name: localtime
  hostPath:
    path: /etc/localtime
    type: File
{{- if eq .Values.storage.model.type "hostPath" }}
- name: model
  hostPath:
    path: {{ .Values.storage.model.hostPath.path }}
    type: {{ .Values.storage.model.hostPath.type }}
{{- end }}
{{- if eq .Values.storage.model.type "pvc" }}
- name: model
  persistentVolumeClaim:
    claimName: {{ .Values.storage.model.pvc.name }}
{{- end }}
{{- if .Values.rdma.enabled }}
- name: ib
  hostPath:
    path: {{ .Values.rdma.infinibandPath }}
{{- end }}
{{- end }}

{{/*
Model path resolution
*/}}
{{- define "sglang.modelPath" -}}
{{- if eq .Values.storage.model.type "huggingface" }}
{{- .Values.global.model.path }}
{{- else }}
/model-data
{{- end }}
{{- end }}

{{/*
Security context
*/}}
{{- define "sglang.securityContext" -}}
{{- if .Values.security.privileged }}
privileged: true
{{- end }}
{{- if .Values.security.securityContext }}
{{- toYaml .Values.security.securityContext | nindent 0 }}
{{- end }}
{{- end }}

{{/*
DNS Policy based on host networking
*/}}
{{- define "sglang.dnsPolicy" -}}
{{- if .Values.networking.hostNetwork }}
ClusterFirstWithHostNet
{{- else }}
{{ .Values.networking.dnsPolicy }}
{{- end }}
{{- end }}
