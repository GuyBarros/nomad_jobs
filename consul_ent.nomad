# For full documentation and examples, see
#     https://www.nomadproject.io/docs/job-specification/job.html
job "hashicorp" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1"]
  type = "service"

  group "consul" {
    count = 1

    task "consul-enterprise" {
      driver = "docker"
      config {
        image = "hashicorp/consul-enterprise:1.4.3-ent"

        port_map {
          http = 8500
        }
      }

      logs {
        max_files     = 5
        max_file_size = 35
      }
      resources {
          
        network {
          port  "http"  {
            static = 8500
          }
        }
      }
      service {
        name = "consul-docker"
        tags = ["urlprefix-/consul-docker strip=/consul-docker"]
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
