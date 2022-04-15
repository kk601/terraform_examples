locals {
  services_config = {
    emailservice = {
      spec = {
        type     = "ClusterIP"
        selector = "emailservice"
        ports = {
          grpc = {
            port        = 5000
            target_port = 8080
          }
        }
      }
    },

    checkoutservice = {
      spec = {
        type     = "ClusterIP"
        selector = "checkoutservice"
        ports = {
          grpc = {
            port        = 5050
            target_port = 5050
          }
        }
      }
    },

    recommendationservice = {
      spec = {
        type     = "ClusterIP"
        selector = "recommendationservice"
        ports = {
          grpc = {
            port        = 8080
            target_port = 8080
          }
        }
      }
    },

    frontend = {
      spec = {
        type     = "ClusterIP"
        selector = "frontend"
        ports = {
          http = {
            port        = 80
            target_port = 8080
          }
        }
      }
    },
    frontend-external = {
      spec = {
        type     = "LoadBalancer"
        selector = "frontend"
        ports = {
          http = {
            port        = 80
            target_port = 8080
          }
        }
      }
    },

    paymentservice = {
      spec = {
        type     = "ClusterIP"
        selector = "paymentservice"
        ports = {
          grpc = {
            port        = 50051
            target_port = 50051
          }
        }
      }
    },

    productcatalogservice = {
      spec = {
        type     = "ClusterIP"
        selector = "productcatalogservice"
        ports = {
          grpc = {
            port        = 3550
            target_port = 3550
          }
        }
      }
    },

    cartservice = {
      spec = {
        type     = "ClusterIP"
        selector = "cartservice"
        ports = {
          grpc = {
            port        = 7070
            target_port = 7070
          }
        }
      }
    },
    currencyservice = {
      spec = {
        type     = "ClusterIP"
        selector = "currencyservice"
        ports = {
          grpc = {
            port        = 7000
            target_port = 7000
          }
        }
      }
    },
    redis-cart = {
      spec = {
        type     = "ClusterIP"
        selector = "redis-cart"
        ports = {
          grpc = {
            port        = 6379
            target_port = 6379
          }
        }
      }
    },
    adservice = {
      spec = {
        type     = "ClusterIP"
        selector = "adservice"
        ports = {
          grpc = {
            port        = 9555
            target_port = 9555
          }
        }
      }
    },
    shippingservice = {
      spec = {
        type     = "ClusterIP"
        selector = "shippingservice"
        ports = {
          grpc = {
            port        = 50051
            target_port = 50051
          }
        }
      }
    },
  }
}

locals {
  deployments = {
    emailservice = {
      spec = {
        termination_grace_period_seconds = 5
        container = {
          name  = "server"
          image = "gcr.io/google-samples/microservices-demo/emailservice:v${var.app_version}"
          port = {
            container_port = 8080
          }
          env = {
            PORT             = 8080
            DISABLE_TRACING  = "1"
            DISABLE_PROFILER = "1"
          }
          readiness_probe = {
            period_seconds = 5
            exec           = ["/bin/grpc_health_probe", "-addr=:8080"]
          }
          liveness_probe = {
            period_seconds = 5
            exec           = ["/bin/grpc_health_probe", "-addr=:8080"]
          }
          resources = {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    },

    checkoutservice = {
      spec = {
        container = {
          name  = "server"
          image = "gcr.io/google-samples/microservices-demo/checkoutservice:v${var.app_version}"
          port = {
            container_port = 5050
          }
          env = {
            PORT                         = 5050
            PRODUCT_CATALOG_SERVICE_ADDR = "productcatalogservice:3550"
            SHIPPING_SERVICE_ADDR        = "shippingservice:50051"
            PAYMENT_SERVICE_ADDR         = "paymentservice:50051"
            EMAIL_SERVICE_ADDR           = "emailservice:${local.services_config.emailservice.spec.ports.grpc.port}"
            CURRENCY_SERVICE_ADDR        = "currencyservice:7000"
            CART_SERVICE_ADDR            = "cartservice:7070"
            DISABLE_STATS                = "1"
            DISABLE_TRACING              = "1"
            DISABLE_PROFILER             = "1"
          }
          readiness_probe = {
            period_seconds = 5
            exec           = ["/bin/grpc_health_probe", "-addr=:5050"]
          }
          liveness_probe = {
            period_seconds = 5
            exec           = ["/bin/grpc_health_probe", "-addr=:5050"]
          }
          resources = {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    },

    recommendationservice = {
      spec = {
        container = {
          name                             = "server"
          termination_grace_period_seconds = 5
          image                            = "gcr.io/google-samples/microservices-demo/recommendationservice:v${var.app_version}"
          port = {
            container_port = 8080
          }
          env = {
            PORT                         = 8080
            PRODUCT_CATALOG_SERVICE_ADDR = "productcatalogservice:3550"
            DISABLE_STATS                = "1"
            DISABLE_TRACING              = "1"
            DISABLE_PROFILER             = "1"
          }
          readiness_probe = {
            period_seconds = 5
            exec           = ["/bin/grpc_health_probe", "-addr=:8080"]
          }
          liveness_probe = {
            period_seconds = 5
            exec           = ["/bin/grpc_health_probe", "-addr=:8080"]
          }
          resources = {
            requests = {
              cpu    = "100m"
              memory = "220Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "450Mi"
            }
          }
        }
      }
    },

    frontend = {
      spec = {
        container = {
          name  = "server"
          image = "gcr.io/google-samples/microservices-demo/frontend:v${var.app_version}"
          port = {
            container_port = 8080
          }
          env = {
            PORT                         = 8080
            PRODUCT_CATALOG_SERVICE_ADDR = "productcatalogservice:3550"
            CURRENCY_SERVICE_ADDR        = "currencyservice:7000"
            CART_SERVICE_ADDR            = "cartservice:7070"
            RECOMMENDATION_SERVICE_ADDR  = "recommendationservice:8080"
            SHIPPING_SERVICE_ADDR        = "shippingservice:50051"
            CHECKOUT_SERVICE_ADDR        = "checkoutservice:5050"
            AD_SERVICE_ADDR              = "adservice:9555"
            ENV_PLATFORM                 = "azure"
            DISABLE_TRACING              = "1"
            DISABLE_PROFILER             = "1"
          }
          readiness_probe = {
            initial_delay_seconds = 10
            http_get = {
              path = "/_healthz"
              port = 8080
              http_header = {
                header_name  = "Cookie"
                header_value = "shop_session-id=x-readiness-probe"
              }
            }
          }
          liveness_probe = {
            initial_delay_seconds = 10
            http_get = {
              path = "/_healthz"
              port = 8080
              http_header = {
                header_name  = "Cookie"
                header_value = "shop_session-id=x-liveness-probe"
              }
            }
          }
          resources = {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    },

    paymentservice = {
      spec = {
        termination_grace_period_seconds = 5
        container = {
          name  = "server"
          image = "gcr.io/google-samples/microservices-demo/paymentservice:v${var.app_version}"
          port = {
            container_port = 50051
          }
          env = {
            PORT             = 50051
            DISABLE_DEBUGGER = "1"
            DISABLE_TRACING  = "1"
            DISABLE_PROFILER = "1"
          }
          readiness_probe = {
            period_seconds = 5
            exec           = ["/bin/grpc_health_probe", "-addr=:50051"]
          }
          liveness_probe = {
            period_seconds = 5
            exec           = ["/bin/grpc_health_probe", "-addr=:50051"]
          }
          resources = {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    },

    productcatalogservice = {
      spec = {
        termination_grace_period_seconds = 5
        container = {
          name  = "server"
          image = "gcr.io/google-samples/microservices-demo/productcatalogservice:v${var.app_version}"
          port = {
            container_port = 3550
          }
          env = {
            PORT             = 3550
            DISABLE_STATS    = "1"
            DISABLE_TRACING  = "1"
            DISABLE_PROFILER = "1"
          }
          readiness_probe = {
            period_seconds = 5
            exec           = ["/bin/grpc_health_probe", "-addr=:3550"]
          }
          liveness_probe = {
            period_seconds = 5
            exec           = ["/bin/grpc_health_probe", "-addr=:3550"]
          }
          resources = {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    },

    cartservice = {
      spec = {
        termination_grace_period_seconds = 5
        container = {
          name  = "server"
          image = "gcr.io/google-samples/microservices-demo/cartservice:v${var.app_version}"
          port = {
            container_port = 7070
          }
          env = {
            REDIS_ADDR = "redis-cart:6379"
          }
          readiness_probe = {
            initial_delay_seconds = 15
            period_seconds        = 5
            exec                  = ["/bin/grpc_health_probe", "-addr=:7070", "-rpc-timeout=5s"]
          }
          liveness_probe = {
            initial_delay_seconds = 15
            period_seconds        = 10
            exec                  = ["/bin/grpc_health_probe", "-addr=:7070", "-rpc-timeout=5s"]
          }
          resources = {
            requests = {
              cpu    = "200m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "300"
              memory = "128Mi"
            }
          }
        }
      }
    },
    # TODO curently not working because of missing init_container
    loadgenerator = {
      spec = {
        termination_grace_period_seconds = 5
        restart_policy                   = "Always"
        container = {
          name  = "main"
          image = "gcr.io/google-samples/microservices-demo/loadgenerator:v${var.app_version}"
          env = {
            FRONTEND_ADDR = "frontend:80"
            USERS         = "10"
          }
          resources = {
            requests = {
              cpu    = "300m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    },

    currencyservice = {
      spec = {
        termination_grace_period_seconds = 5
        container = {
          name  = "server"
          image = "gcr.io/google-samples/microservices-demo/currencyservice:v${var.app_version}"
          port = {
            container_port = 7000
          }
          env = {
            PORT             = 7000
            DISABLE_DEBUGGER = "1"
            DISABLE_TRACING  = "1"
            DISABLE_PROFILER = "1"
          }
          readiness_probe = {
            period_seconds = 5
            exec           = ["/bin/grpc_health_probe", "-addr=:7000"]
          }
          liveness_probe = {
            period_seconds = 5
            exec           = ["/bin/grpc_health_probe", "-addr=:7000"]
          }
          resources = {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    },

    shippingservice = {
      spec = {
        termination_grace_period_seconds = 5
        container = {
          name  = "server"
          image = "gcr.io/google-samples/microservices-demo/shippingservice:v${var.app_version}"
          port = {
            container_port = 50051
          }
          env = {
            PORT             = 50051
            DISABLE_STATS = "1"
            DISABLE_TRACING  = "1"
            DISABLE_PROFILER = "1"
          }
          readiness_probe = {
            period_seconds = 5
            exec           = ["/bin/grpc_health_probe", "-addr=:50051"]
          }
          liveness_probe = {
            exec           = ["/bin/grpc_health_probe", "-addr=:50051"]
          }
          resources = {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    },

    redis-cart = {
      spec = {
        container = {
          name  = "redis"
          image = "redis:alpine"
          port = {
            container_port = 6379
          }
          env = {
            PORT = 6379
          }
          readiness_probe = {
            period_seconds = 5
            tcp_socket     = 6379
          }
          liveness_probe = {
            period_seconds = 5
            tcp_socket     = 6379
          }
          volume_mount = {
            mount_path = "/data"
            name       = "redis-data"
          }
          resources = {
            requests = {
              cpu    = "70m"
              memory = "200Mi"
            }
            limits = {
              cpu    = "125m"
              memory = "256Mi"
            }
          }
        }
        volume = {
          name = "redis-data"
        }
      }
    },
    adservice = {
      spec = {
        termination_grace_period_seconds = 5
        container = {
          name  = "server"
          image = "gcr.io/google-samples/microservices-demo/adservice:v${var.app_version}"
          port = {
            container_port = 9555
          }
          env = {
            PORT             = 9555
            DISABLE_TRACING  = "1"
            DISABLE_STATS = "1"
          }
          readiness_probe = {
            initial_delay_seconds = 20
            period_seconds = 15
            exec           = ["/bin/grpc_health_probe", "-addr=:9555"]
          }
          liveness_probe = {
            initial_delay_seconds = 20
            period_seconds = 15
            exec           = ["/bin/grpc_health_probe", "-addr=:9555"]
          }
          resources = {
            requests = {
              cpu    = "200m"
              memory = "180Mi"
            }
            limits = {
              cpu    = "300m"
              memory = "300Mi"
            }
          }
        }
      }
    }
  }
}