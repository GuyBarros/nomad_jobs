 job "todo-mongo" {
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c"]
  type = "service"
  group "todo-mongo" {
    count = 1
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
        to = 8000
      }
    }
    task "todo-mongo" {
      driver = "docker"
      config {
        image = "guybarros/nest-todo-app:latest"
      }
      env {
        MONGODB_SERVER = "127.0.0.1"
        MONGODB_PORT = "27017"
        MONGODB_COL = "todoapp"
      }
    } # end todo-mongo task
    service {
      name = "todo-mongo"
      tags = [
        "global",
        "urlprefix-/todos",
        "traefik.enable=true",
        "traefik.http.routers.chat.rule=PathPrefix(`/todos`)",
      ]
      port = "http"
        check {
        name     = "todo-mongo alive"
        type     = "http"
        path     = "/todos"
        interval = "10s"
        timeout  = "2s"
      }
      connect {
        sidecar_service {
          tags = ["todo-mongo-proxy"]
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