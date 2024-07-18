# For full documentation and examples, see
#     https://www.nomadproject.io/docs/job-specification/job.html
job "Oracle" {
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c"]
  type = "service"

  group "DB_XS" {
    count = 1

    task "oracle-xe-11g" {
      driver = "docker"
      config {
        image = "oracleinanutshell/oracle-xe-11g"

        port_map {
          db = 1521
          http = 5500
          apex = 8080
        }
        }
env {
        "ORACLE_ALLOW_REMOTE" = true

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
              static = 5500
          }
          port  "db"  {
              static = 1521
          }
          port  "apex"  {
              static = 8080
          }
        }
      }
      service {
        name = "oracle"
        tags = ["urlprefix-/oracle strip=/oracle"]
        port = "apex"

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
