# For full documentation and examples, see
#     https://www.nomadproject.io/docs/job-specification/job.html
job "meanstack" {
  group "nodejs" {
    count = 3

    task "backend" {
      driver = "docker"
      config {
        image = "phatbrasil/meanstack_backend"
args = [
    "--env", "MONGODB_URL",
    "mongodb.service.consul",
    "--env", "MONGODB_PORT",
    "27017",
  ]
        port_map {
          http = 5000
        }
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }
      resources {
        cpu = 1000
        memory = 1024
        network {
          mbits = 10
          port  "http"  {
            
          }
        }
      }
      service {
        name = "meanstack_backend"
        tags = ["urlprefix-/meanstack_backend strip=/meanstack_backend"]
        port = "http"

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
