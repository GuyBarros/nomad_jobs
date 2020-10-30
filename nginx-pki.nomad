job "nginx" {
   datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c"]
  type = "service"

  group "withvault" {
    count = 5

    vault {
      policies = ["superuser"]
    }

    task "nginx-pki" {
      driver = "docker"

      config {
        image = "nginx"
        port_map {
          http = 80
        }
        port_map {
          https = 443
        }
        volumes = [
          "custom/default.conf:/etc/nginx/conf.d/default.conf",
          "secret/cert.key:/etc/nginx/ssl/nginx.key",
        ]
      }

      template {
        data = <<EOH
          server {
            listen 80;
            listen 443 ssl;

            server_name nginx.service.consul;
            # note this is slightly wonky using the same file for
            # both the cert and key
            ssl_certificate /etc/nginx/ssl/nginx.key;
            ssl_certificate_key /etc/nginx/ssl/nginx.key;

            location / {
              root /local/data/;
            }
          }
        EOH

        destination = "custom/default.conf"
      }

      template {
        data = <<EOH
{{ with secret "pki/issue/consul-service" "common_name=nginx.service.consul" "ttl=30m" }}
{{ .Data.certificate }}
{{ .Data.private_key }}
{{ end }}
      EOH

        destination = "secret/cert.key"
      }

      template {
        data = <<EOH
            <h2> Hello World </h2>
            <br />
            <br />

             from {{ env "node.unique.name" }}
            <br />
            <br />

            <br />
	          <br />
            {{ with secret "pki/issue/consul-service" "common_name=nginx.service.consul" "ttl=90m" }}
            {{ .Data.certificate }}
            <br />
            <br />
            {{ .Data.private_key }}
            {{ end }}
        EOH

        destination = "local/data/nginx-pki/index.html"
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
        name = "nginx-pki"
        port = "http"
        tags = [
          "global",
          "urlprefix-/nginx-pki"
          ]
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }

  }
}
