# For full documentation and examples, see
#     https://www.nomadproject.io/docs/job-specification/job.html
job "pipelines" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1"]
  group "ansible" {
    count = 1
network {
          port  "http"  {
            to = 4440   
          }
        }
    task "rundeck" {
      driver = "docker"
      config {
        image = "phatbrasil/rundeck"
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }
      resources {
        cpu = 1000
        memory = 1024
        
      }
      service {
        name = "rundeck"
        tags = ["global", "rundeck"]
        port = "http"

        check {
          name     = "alive"
          port = "http"
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
