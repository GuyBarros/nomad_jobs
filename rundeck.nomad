# For full documentation and examples, see
#     https://www.nomadproject.io/docs/job-specification/job.html
job "pipelines" {
  group "ansible" {
    count = 1

    task "rundeck" {
      driver = "docker"
      config {
        image = "phatbrasil/rundeck"

        port_map {
          vaultport = 8200,
          http = 4440
        }
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }
      resources {
        
        network {
          mbits = 10
          port  "vaultport"  {
          
          }
          port  "http"  {
          
          }
          
        }
      }
      service {
        name = "rundeck"
        tags = ["global", "rundeck"]
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
