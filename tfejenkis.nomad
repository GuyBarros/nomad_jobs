# For full documentation and examples, see
#     https://www.nomadproject.io/docs/job-specification/job.html
job "tfe-integration" {
  datacenters = ["dc1"]
  type = "service"

  group "terraform-jenkins" {
    count = 1

    task "jenkins" {
      driver = "docker"
      config {
        image = "phatbrasil/tfejenkins:version2"

        port_map {
          http = 8080
        }
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }
      resources {
        cpu = 1500
        memory = 2048
        network {
          mbits = 10
          port  "http"  {
            
          }
        }
      }
      service {
        name = "tfejenkins"
        tags = ["urlprefix-/tfejenkins strip=/tfejenkins"]
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
