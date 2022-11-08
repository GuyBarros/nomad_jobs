# For full documentation and examples, see
#     https://www.nomadproject.io/docs/job-specification/job.html
job "jupyterhub" {
    datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]

  group "jupyterhub" {
    count = 1
network {
          port  "http"  {
            to = 8000   
          }
        }
    task "jupyterhub" {
      driver = "docker"
      config {
        image = "jupyterhub/jupyterhub"
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
        name = "jupyterhub"
        tags = ["urlprefix-/jupyterhub strip=/jupyterhub"]
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
  
  update {
    max_parallel = 1
    min_healthy_time = "5s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 0
  }
}
