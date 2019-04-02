# For full documentation and examples, see
#     https://www.nomadproject.io/docs/job-specification/job.html
job "pipelines" {
  datacenters = ["eu-west-2","ukwest"]
  type = "service"

  
  group "ansible" {
    count = 1

    task "rundeck" {
      driver = "docker"
      config {
        image = "jordan/rundeck"

        port_map {
          http = 4440
        }

       
         
      }
      env {
       "EXTERNAL_SERVER_URL"="http://${NOMAD_ADDR_http}"
       "RUNDECK_ADMIN_PASSWORD"="Welcome1"
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }
      resources {
        cpu = 1000
        memory = 2048
        network {
          mbits = 10
          port  "http"  {
             
          }
        }
      }
      service {
        name = "rundeck"
        tags = ["global", "urlprefix-/rundeck"]
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
