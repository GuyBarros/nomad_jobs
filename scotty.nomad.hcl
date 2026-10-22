job "scotty-remote-desktop" {
  datacenters = ["eu-west-2*", "ukwest", "sa-east-1", "ap-northeast-1", "dc1", "dc1-eu-west-2"]
  type        = "service"

  constraint {
    attribute = "${meta.type}"
    value     = "worker"
  }

  group "remote-desktop-group" {
    count = 1

    network {
      port "rdp" {
        static = 3389
      }
    }

    service {
      name = "scotty-remote-desktop"
      port = "rdp"
      tags = ["rdp"]
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "remote-desktop" {
      driver = "docker"

      config {
        image    = "scottyhardy/docker-remote-desktop:latest"
        ports    = ["rdp"]
        hostname = "remote-desktop"
        shm_size = 1073741824 # 1GB, helps browsers inside the XFCE session
      }

      # Default login is ubuntu / ubuntu (baked into the image)

      resources {
        cpu    = 1000 # MHz
        memory = 2048 # MB
      }
    }
  }
}
