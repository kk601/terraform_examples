provider "kubernetes" {
  config_path    = "~/.kube/kubernetes_management_demo_kubeconfig"
  config_context = azurerm_kubernetes_cluster.aks_cluster.name
}

# TODO just use kubernetes_mainfest resource 
resource "kubernetes_namespace" "onlineboutique-namespace" {
  metadata {
    name = "onlineboutique"
  }
  depends_on = [
    local_sensitive_file.kubeconfig
  ]
}
resource "kubernetes_deployment" "deployments" {
  for_each = local.deployments
  metadata {
    name      = each.key
    namespace = kubernetes_namespace.onlineboutique-namespace.metadata.0.name
  }
  spec {
    selector {
      match_labels = {
        app = each.key
      }
    }
    template {
      metadata {
        labels = {
          app = each.key
        }
      }
      spec {
        service_account_name             = "default"
        termination_grace_period_seconds = try(each.value.spec.termination_grace_period_seconds, null)
        restart_policy                   = try(each.value.spec.restart_policy, null)
        container {
          image = each.value.spec.container.image
          name  = try(each.value.spec.container.name, null)

          dynamic "port" {
            for_each = can(each.value.spec.container.port) ? [each.value.spec.container.port] : []
            content {
              container_port = each.value.spec.container.port.container_port
            }
          }

          dynamic "env" {
            for_each = each.value.spec.container.env
            content {
              name  = env.key
              value = env.value
            }
          }
          dynamic "readiness_probe" {
            for_each = can(each.value.spec.container.readiness_probe) ? [each.value.spec.container.readiness_probe] : []
            content {
              initial_delay_seconds = try(each.value.readiness_probe.initial_delay_seconds, null)
              period_seconds        = try(each.value.readiness_probe.period_seconds, null)
              dynamic "exec" {
                for_each = can(readiness_probe.value.exec) ? [readiness_probe.value.exec] : []
                content {
                  command = exec.value
                }
              }
              dynamic "http_get" {
                for_each = can(readiness_probe.value.http_get) ? [readiness_probe.value.http_get] : []
                content {
                  path = http_get.value.path
                  port = http_get.value.port
                  http_header {
                    name  = http_get.value.http_header.header_name
                    value = http_get.value.http_header.header_value
                  }
                }
              }
              dynamic "tcp_socket" {
                for_each = can(readiness_probe.value.tcp_socket) ? [readiness_probe.value.tcp_socket] : []
                content {
                  port = tcp_socket.value
                }
              }
            }
          }
          dynamic "liveness_probe" {
            for_each = can(each.value.spec.container.liveness_probe) ? [each.value.spec.container.liveness_probe] : []
            content {
              initial_delay_seconds = try(each.value.liveness_probe.initial_delay_seconds, null)
              period_seconds        = try(each.value.liveness_probe.period_seconds, null)
              dynamic "exec" {
                for_each = can(liveness_probe.value.exec) ? [liveness_probe.value.exec] : []
                content {
                  command = exec.value
                }
              }
              dynamic "http_get" {
                for_each = can(liveness_probe.value.http_get) ? [liveness_probe.value.http_get] : []
                content {
                  path = http_get.value.path
                  port = http_get.value.port
                  http_header {
                    name  = http_get.value.http_header.header_name
                    value = http_get.value.http_header.header_value
                  }
                }
              }
              dynamic "tcp_socket" {
                for_each = can(liveness_probe.value.tcp_socket) ? [liveness_probe.value.tcp_socket] : []
                content {
                  port = tcp_socket.value
                }
              }
            }
          }
          dynamic "volume_mount" {
            for_each = can(each.value.spec.container.volume_mount) ? [each.value.spec.container.volume_mount] : []
            content {
              mount_path = volume_mount.value.mount_path
              name       = volume_mount.value.name
            }
          }
          resources {
            requests = each.value.spec.container.resources.requests
            limits   = each.value.spec.container.resources.limits
          }
        }
        dynamic "volume" {
          for_each = can(each.value.spec.volume) ? [each.value.spec.volume] : []
          content {
            name = volume.value.name
            empty_dir {

            }
          }
        }
      }
    }
  }
  depends_on = [
    local_sensitive_file.kubeconfig
  ]
}
resource "kubernetes_service" "services" {
  for_each = local.services_config
  metadata {
    namespace = kubernetes_namespace.onlineboutique-namespace.metadata.0.name
    name      = each.key
  }
  spec {
    type = each.value.spec.type
    selector = {
      app = each.value.spec.selector
    }
    dynamic "port" {
      for_each = each.value.spec.ports
      content {
        name        = port.key
        port        = port.value.port
        target_port = port.value.target_port
      }
    }
  }
  depends_on = [
    local_sensitive_file.kubeconfig
  ]
}
