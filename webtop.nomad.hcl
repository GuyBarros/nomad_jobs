job "webtop" {
  datacenters = ["eu-west-2*","ukwest","sa-east-1","ap-northeast-1","dc1","dc1-eu-west-2"]
  type        = "service"

  constraint {
    attribute = "${meta.type}"
    value     = "worker"
  }

  group "webtop-group" {
    count = 1

    network {
      port "http1" {
        to = 3000
      }
      port "http2" {
        to = 3001
      }
    }

    service {
      name = "webtop"
      port = "http1"
      tags = ["http"]
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name = "webtop-https"
      port = "http2"
      tags = ["https"]
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "webtop" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/webtop:latest"
        ports = ["http1", "http2"]
      }

      env {
        PUID      = "1000"
        PGID      = "1000"
        TZ        = "Etc/UTC"
        SUBFOLDER = "/"       # optional
        TITLE     = "Webtop"  # optional
      }
      

      resources {
        cpu    = 1000    # MHz
        memory = 2048   # MB
      }
    }
  }
}