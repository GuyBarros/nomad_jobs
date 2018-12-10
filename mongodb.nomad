# For full documentation and examples, see
#     https://www.nomadproject.io/docs/job-specification/job.html
job "mongodb" {
  group "mongodb" {
    count = 1

    task "mongodb" {
      driver = "docker"
      config {
        image = "mongo"

        port_map {
          db = 27017
        }
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }
      resources {
        
        network {
          mbits = 10
          port  "db"  {
            
          }
        }
      }
      service {
        name = "mongodb"
        tags = ["global", "mongodb","urlprefix-/mongodb"]
        port = "db"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

  }

  datacenters = ["dc1"]
  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "5s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 0
  }
}
