{{/* Validate that essential values like storageClassName and storagePath are provided. */}}
{{- define "validate.requiredValues" -}}
{{- if empty .Values.storageClassNames -}}
{{ fail "Please provide an array of storageclass names" }}
{{- end -}}
{{ $storageClassNames := .Values.storageClassNames | required ".Values.storageClassNames is required" }}
{{ $storagePath := .Values.storagePath | required ".Values.storagePath is required" }}
{{- end -}}

{{/* Convert metricsPort to an integer and validate its value. */}}
{{ define "validate.metricsPort" }}
{{- $metricsPort := .Values.metricsPort | int -}}
{{ if or (le $metricsPort 0) (gt $metricsPort 65535) }}
  {{ fail (printf "metricsPort must be set to a correct non-zero number. (Given value: %s)" .Values.metricsPort) }}
{{ end }}
{{- $metricsPort -}}
{{ end }}

{{/* Validate that each imagePullSecret has a name. */}}
{{ define "validate.imagePullSecrets" }}
{{ if .Values.imagePullSecrets }}
{{ range .Values.imagePullSecrets }}
{{ if not .name }}
{{ fail "imagePullSecrets must have a name" }}
{{ end }}
{{ end }}
{{ end }}
{{ end }}

{{/* Ensure imagePullPolicy is one of the allowed values. */}}
{{ define "validate.imagePullPolicy" -}}
{{ if not (or (eq .Values.imagePullPolicy "Always" ) (eq .Values.imagePullPolicy "IfNotPresent" ) (eq .Values.imagePullPolicy "Never" )) }}
{{ fail (printf "imagePullPolicy must be one of: Always, IfNotPresent, Never (given '%s')" .Values.imagePullPolicy) }}
{{ end }}
{{ end }}