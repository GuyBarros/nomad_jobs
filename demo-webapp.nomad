job "demo-webapp" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1","dc1-eu-west-2"]

  group "demo" {
    count = 3

    task "server" {
      env {
        PORT    = "${NOMAD_PORT_http}"
        NODE_IP = "${NOMAD_IP_http}"
      }

      driver = "docker"

      config {
        image = "hashicorp/demo-webapp-lb-guide"
      }

      resources {
        network {
          mbits = 10
          port  "http"{}
        }
      }

      service {
        name = "demo-webapp"
        port = "http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.chat.rule=PathPrefix(`/myapp`)",
        ]

        check {
          type     = "http"
          path     = "/"
          interval = "2s"
          timeout  = "2s"
        }
      }
    }
  }
}