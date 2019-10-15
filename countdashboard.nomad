    job "countdash" {
        datacenters = ["eu-west-2","eu-west-1","ukwest","sa-east-1","ap-northeast-1","dc1","europe-west3-dc"]
        group "dashboard" {
        network {
        mode ="bridge"
        port "http" {
            static = 9002
            to     = 9002
        }
        }

        service {
        name = "count-dashboard"
        tags = ["urlprefix-/count-dashboard strip=/count-dashboard"]

        port = "9002"

        connect {
            sidecar_service {
            proxy {
              upstreams {
                destination_name = "count-api"
                local_bind_port = 8080
              }
              config {
                mesh_gateway {
                  mode = "local"
                }
              }
            }
          }
        }
        }

        task "dashboard" {
        driver = "docker"
        env {
            COUNTING_SERVICE_URL = "http://127.0.0.1:8080"
        }
        config {
            image = "hashicorpnomad/counter-dashboard:v1"
        }
        }
    }
    }