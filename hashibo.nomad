# For full documentation and examples, see
#     https://www.nomadproject.io/docs/job-specification/job.html
job "presentation" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1"]
  type = "service"

  group "presentation" {
    count = 3

    task "hashibo" {
      driver = "docker"
      config {
        image = "boeroboy/hashibo:2019"

        port_map {
          http = 80
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
        name = "hashibo"
        tags = ["urlprefix-/hashibo strip=/hashibo"]
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

  
  
  update {
    max_parallel = 1
    min_healthy_time = "5s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 0
  }
}
