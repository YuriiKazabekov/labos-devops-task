variable "BUILD_NUMBER" {
  type = string
}

job "backend-api" {
  datacenters = ["dc1"]
  type        = "service"

  group "backend" {
    count = 1

    network {
      mode = "bridge"
      port "http" {
        static = 5000
      }
    }

    constraint {
      attribute = "${node.unique.id}"
      operator  = "="
      value     = "23b881cc-10cf-6fc5-8369-a84d501a907d"
    }

    task "backend-api" {
      driver = "docker"

      config {
        image = "ykaz1291/backend-api:${var.BUILD_NUMBER}"
        ports = ["http"]
      }

      resources {
        cpu    = 500   # CPU in MHz
        memory = 256   # Memory in MB
      }

      service {
        name = "backend-api"
        port = "http"

        check {
          name     = "backend-api-health-check"
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }

      vault {
        policies = ["backend-api"]
      }
    }
  }
}
