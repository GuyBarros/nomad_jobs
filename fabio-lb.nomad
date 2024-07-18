job "fabio" {
  region = "global"
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]
  type     = "system"
  priority = 75

  update {
    stagger      = "10s"
    max_parallel = 1
  }

  group "fabio-lb"{

      network {

        port "http" {
          static = 9999
        }

        port "ui" {
          static = 9998
        }
      }

  task "fabio" {
    driver = "exec"

    config {
      command = "fabio"
    }

    artifact {
      source      = "https://github.com/fabiolb/fabio/releases/download/v1.6.3/fabio-1.6.3-linux_amd64"
      destination = "fabio"
      mode        = "file"
    }

    service {
      port = "http"
      name = "fabio"

      check {
        type     = "http"
        port     = "ui"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

  }
  }
}
