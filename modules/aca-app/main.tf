# LLD 7.2 — one Container App definition, reused for all 5 services by
# passing different values from each stack/60-platform module call.
resource "azurerm_container_app" "this" {
  name                         = var.name
  container_app_environment_id = var.environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                 = "Single" # LLD 7.3 — Phase 1 default
  tags                           = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  registry {
    server   = var.acr_login_server
    identity = var.identity_id
  }

  dynamic "ingress" {
    for_each = var.target_port != null ? [1] : []
    content {
      external_enabled = false # internal only — reached via Application Gateway (LLD 7.2)
      target_port       = var.target_port
      transport          = "http"
      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = var.name
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secrets
        content {
          name        = env.key
          secret_name = env.key
        }
      }

      # LLD 7.2 — probes only on the 3 HTTP apps (target_port != null)
      dynamic "liveness_probe" {
        for_each = var.target_port != null ? [1] : []
        content {
          transport               = "HTTP"
          path                     = "/health/live"
          port                     = var.target_port
          initial_delay            = 5
          interval_seconds         = 10
          failure_count_threshold  = 3
        }
      }

      dynamic "readiness_probe" {
        for_each = var.target_port != null ? [1] : []
        content {
          transport               = "HTTP"
          path                     = "/health/ready"
          port                     = var.target_port
          interval_seconds         = 5
          failure_count_threshold  = 3
        }
      }

      dynamic "startup_probe" {
        for_each = var.target_port != null ? [1] : []
        content {
          transport               = "HTTP"
          path                     = "/health/live"
          port                     = var.target_port
          interval_seconds         = 5
          failure_count_threshold  = 10
        }
      }
    }

    # LLD 7.2 — HTTP concurrency scale rule for the 3 HTTP-facing apps
    dynamic "http_scale_rule" {
      for_each = var.scale_rule_type == "http" ? [1] : []
      content {
        name                = "http-concurrency"
        concurrent_requests = tostring(var.http_concurrent_requests)
      }
    }

    # LLD 7.2 — KEDA Service Bus scale rule for payment-svc / notification-worker
    dynamic "custom_scale_rule" {
      for_each = var.scale_rule_type == "servicebus" ? [1] : []
      content {
        name             = "servicebus-scale"
        custom_rule_type = "azure-servicebus"
        metadata = {
          queueName    = var.servicebus_queue_or_topic_name
          namespace    = var.servicebus_namespace
          messageCount = "1"
        }
        authentication {
          secret_name       = "servicebus-auth"
          trigger_parameter = "workloadIdentityResourceId"
        }
      }
    }
  }

  secret {
    name  = "servicebus-auth"
    value = var.identity_id # workload-identity based auth — no connection string
  }
}
