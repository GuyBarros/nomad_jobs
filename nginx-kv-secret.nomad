job "nginx" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1"]
  type = "service"

  group "nginx" {
    count = 3

    vault {
      policies = ["test"]
       change_mode   = "restart"
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx"
        port_map {
          http = 8080
        }
        port_map {
          https = 443
        }
        volumes = [
          "custom/default.conf:/etc/nginx/conf.d/default.conf"
        ]
      }

      template {
        data = <<EOH
          server {
            listen 8080;
            server_name nginx.service.consul;
            location /nginx-secret {
              root /local/data;
            }
          }
        EOH

        destination = "custom/default.conf"
      }

      # vault write secret/motd ttl=10s message='Live demos rock!!!'
      template {
        data = <<EOH
	  from ${NOMAD_ADDR_http}
    
	  {{ with secret "secret/test" }}
	  secret: {{ .Data.message }}
      {{ end }}

     
      EOH

        destination = "local/data/nginx-secret/index.html"
      }

      resources {
        cpu    = 100 # 100 MHz
        memory = 128 # 128 MB
        network {
          mbits = 10
          port "http" {
              
          }
          port "https" {
            
          }
        }
      }

      service {
        name = "nginx"
        tags = [
          "global",
          "urlprefix-/nginx-secret"
          ]
        port = "http"
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}