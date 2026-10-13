variable "name"           { type = string }
variable "environment_id" { type = string }
variable "resource_group_name" { type = string }
variable "image"          { type = string }
variable "cpu"             { type = number }
variable "memory"          { type = string }   # e.g. "1Gi"
variable "identity_id"     { type = string }
variable "acr_login_server" { type = string }

variable "min_replicas" { type = number }
variable "max_replicas" { type = number }

# null = worker, no ingress (LLD 7.2: payment-svc, notification-worker)
variable "target_port" {
  type    = number
  default = null
}

variable "env_vars" {
  type    = map(string)
  default = {}
}

# map(secret_name => key vault secret URI) — surfaced to the container as
# env vars via secretRef, per LLD 7.2
variable "secrets" {
  type    = map(string)
  default = {}
}

# "http" = HTTP concurrency rule (LLD 7.2 for the 3 HTTP apps)
# "servicebus" = KEDA Service Bus scale rule (LLD 7.2 for the 2 workers)
variable "scale_rule_type" {
  type = string # "http" | "servicebus"
}

variable "http_concurrent_requests" {
  type    = number
  default = null
}

variable "servicebus_queue_or_topic_name" {
  type    = string
  default = null
}
variable "servicebus_subscription_name" {
  type    = string
  default = null
}
variable "servicebus_namespace" {
  type    = string
  default = null
}

variable "tags" { type = map(string) }
