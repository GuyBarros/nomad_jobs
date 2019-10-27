job "chat_docker" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1"]
  type = "service"
  group "chat-app" {
    count = 1
    network {
      mode = "bridge"
      port "http" {
        static = 9002
        to     = 5000
      }
    }
    task "chat-app" {
      driver = "docker"
      env {
        "MONGODB_SERVER" = "127.0.0.1"
        "MONGODB_PORT" = "27017"
      }
      config {
        image = "lhaig/anon-app:0.02"
      }
      logs {
        max_files     = 5
        max_file_size = 15
      }
      resources {
        cpu = 500
        memory = 512
      }   
    }
    service {
      name = "chat-app"
      tags = ["chat-app"]
      port = "http"
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "mongodb"
              local_bind_port = 27017
            }
          }
        }
      }
    }
  }
}