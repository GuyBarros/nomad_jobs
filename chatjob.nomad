job "chat2" {
 datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]

  type = "service"
  group "anon_chat" {
    count = 1
    network {
      mode = "bridge"
      port "http" {
        static = 9002
        to     = 5000
      }
    }  
    task "anon_chat_server" {
      driver = "raw_exec"
       template {
        data = <<EOH
        #!/bin/bash
        cd local/repo/1/
        npm install && npm start
        EOH
        destination = "local/run.sh"
        perms = "755"
      }
      artifact {
        source   = "git::https://github.com/GuyBarros/anonymouse-realtime-chat-app"
        destination = "local/repo/1/"
      }
      env{
        MONGODB_SERVER = "127.0.0.1"
        MONGODB_PORT =   27017
      }
      config {
        command = "bash"
        args    = ["local/run.sh"]
      }
    }
    service {
      name = "chat"
      tags = ["chat"]
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
