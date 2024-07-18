
job "redis" {
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]
  
  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 0
  }

  group "cache" {
    count = 1
    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }


    ephemeral_disk {
      size = 300
    }

network {
          mode = "bridge"
          port "db" {
            to = 6379
          }
        }

    task "redis" {
      driver = "docker"
      config {
        image = "redis"
        ports = ["db"]
        
      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
        
      }
    }
    service {
        name = "redis"
        tags = ["global", "cache", "urlprefix-/redis" ]
        port = "db"
        connect {
             sidecar_service {}
        }
      }
  }
}