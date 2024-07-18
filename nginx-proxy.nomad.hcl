job "nginx-proxy" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1","dc1-eu-west-2"]

  type     = "system"
  priority = 75

  update {
    stagger      = "10s"
    max_parallel = 1
  }

  group "nginx-proxy" {

    task "nginx-proxy" {
      driver = "docker"

      config {
        image = "nginx"

        port_map {
          http = 8085
        }

        volumes = [
          "local:/etc/nginx/conf.d",
        ]
      }

      template {
        data = <<EOF
upstream myapp {
    ip_hash;
{{ range service "demo-webapp" }}
  server {{ .Address }}:{{ .Port }};
{{ else }}server 127.0.0.1:65535; # force a 502
{{ end }}
}

upstream chat {
    ip_hash;
{{ range service "chat-app" }}
  server {{ .Address }}:{{ .Port }};
{{ else }}server 127.0.0.1:65535; # force a 502
{{ end }}
}
server {
   listen 8085;

   location /myapp/ {
      proxy_pass http://myapp;
   }

     location / {
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $host;

      proxy_pass http://chat;

      # enable WebSockets
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
    }

    location /chat/ {
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $host;

      proxy_pass http://chat;

      # enable WebSockets
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
    }


     location  /socket.io/ {
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $host;

      proxy_pass http://chat;

      # enable WebSockets
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
    }


  }
EOF
        destination   = "local/load-balancer.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      resources {
        network {
          mbits = 10

          port "http" {
            static = 8085
          }
        }
      }

      service {
        name = "nginx-proxy"
        tags = ["nginx-proxy"]
        port = "http"
          check {
          name     = "nginx alive"
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}