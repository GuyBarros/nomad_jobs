job "countapi" {
   datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]
    group "api" {
    network {
      mode = "bridge"
    }

    service {
      name = "count-api"
      port = "9001"

      connect {
        sidecar_service {
          proxy {
            transparent_proxy {}
          }
        }
      }
    }

    task "web" {
      driver = "docker"

      config {
        image = "hashicorpdev/counter-api:v3"
      }
    }
  }

  group "dashboard" {
    network {
      mode = "bridge"

      port "http" {
        static = 9002
        to     = 9002
      }
    }

    service {
      name = "count-dashboard"
      port = "http"

      connect {
        sidecar_service {
          proxy {
            transparent_proxy {}
          }
        }
      }
    }

    task "dashboard" {
      driver = "docker"

      env {
        COUNTING_SERVICE_URL = "http://count-api.virtual.consul"
      }

      config {
        image = "hashicorpdev/counter-dashboard:v3"
      }
    }
  }
}