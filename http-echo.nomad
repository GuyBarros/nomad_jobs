job "http-echo-${node_name}" {
  datacenters = ["dc1"]

  group "echo" {
    task "server" {
      driver = "docker"

      config {
        image = "hashicorp/http-echo:0.2.3"
        args  = [
          "-listen", ":80",
          "-text", "hello world from ${NOMAD_ADDR_http} ",
        ]
      }

      resources {
        network {
          mbits = 10
          port "http" {
            static = 80
          }
        }
      }

      service {
        name = "http-echo"
        port = "http"

        tags = [
          "${node_name}",
          "urlprefix-/http-echo",
        ]

        check {
          type     = "http"
          path     = "/health"
          interval = "2s"
          timeout  = "2s"
        }
      }
    }
  }
}