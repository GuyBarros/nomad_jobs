job "traefik" {
  region      = "global"
 datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1","dc1-eu-west-2"]
  type        = "system"

  group "traefik" {
    count = 1

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v2.2"
        network_mode = "host"

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      template {
        data = <<EOF
[entryPoints]
    [entryPoints.http]
    address = ":8080"
    [entryPoints.traefik]
    address = ":8081"

[ping]
  entryPoint = "traefik"

[api]
    dashboard = true
    insecure = true
    debug = true

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
  prefix = "traefik"
  exposedByDefault = false
  [providers.consulCatalog.endpoint]
    address = "http://127.0.0.1:8500"
     scheme = "http"


EOF

        destination = "local/traefik.toml"
      }

      resources {
        cpu    = 100
        memory = 128

        network {
          mbits = 10

          port "http" {
            static = 8080
          }

          port "api" {
            static = 8081
          }
        }
      }

      service {
        name = "traefik"

        check {
          name     = "alive"
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}