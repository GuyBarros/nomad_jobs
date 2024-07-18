job "chat-app" {
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]
  type = "service"
  group "chat-app" {
    count = 3

    update {
      max_parallel = 1
      health_check = "checks"
      min_healthy_time = "15s"
      healthy_deadline = "2m"
      # canary = 3
    }
    network {
      mode = "bridge"
      port "http" {
        to = 3000
      }
    }
    task "chat-app" {
      driver = "docker"
      config {
        image = "guybarros/chat-app:latest"
      }
      env {
        MONGODB_SERVER = "127.0.0.1"
        MONGODB_PORT = "27017"
      }
      resources {
        cpu = 300 # MHz
        memory = 512 # MB
      }
    } # end chat-app task
    service {
      name = "chat-app"
      tags = ["urlprefix-/chat",
      "traefik.enable=true",
      "traefik.http.routers.chat.rule=PathPrefix(`/chat`)||PathPrefix(`/socket.io`)",
      "traefik.http.services.chat.loadbalancer.sticky",
      "traefik.http.middlewares.sslheader.headers.customrequestheaders.X-Forwarded-Proto = https"
      ]
      port = "http"
      check {
        name     = "chat-app alive"
        type     = "http"
        path     = "/chats"
        interval = "10s"
        timeout  = "2s"
      }
      connect {
        sidecar_service {
          tags = ["chat-proxy"]
          proxy {
            upstreams {
              destination_name = "mongodb"
              local_bind_port = 27017
            }
          }
        }
      } # end connnect
    } # end service
  } # end chat-app group
}