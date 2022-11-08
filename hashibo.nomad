# For full documentation and examples, see
#     https://www.nomadproject.io/docs/job-specification/job.html
job "presentation" {
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]
  type = "service"

  group "presentation" {
    count = 3
 network {
        port "http" {
         to = 80
        }
      }
    task "hashibo" {
      driver = "docker"
      config {
        image = "boeroboy/hashibo:2019"
        ports = ["http"]
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }
  
      service {
        name = "hashibo"
        tags = [
          "urlprefix-/hashibo strip=/hashibo",
          "traefik.enable=true",
          "traefik.http.routers.hashibo.rule=PathPrefix(`/hashibo`)",
          "traefik.http.middlewares.hashibo.stripprefix.prefixes=/hashibo"
        ]
        port = "http"
        check {
        type     = "http"
        port     = "http"
        path     = "/#/"
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
