#To Configure postgres
# postgres.service.consul:5432/postgres?sslmode=disable
# username="root"     password="rootpassword"


job "pgadmin4" {
  datacenters = ["eu-west-2","eu-west-1","ukwest","sa-east-1","ap-northeast-1","dc1"]
  type = "service"

  group "pgadmin4" {
    count = 1

    task "pgadmin4" {
      driver = "docker"
      config {
        image = "dpage/pgadmin4"
        network_mode = "host"
        port_map {
          db = 5050
        }

      }
      env {
        PGADMIN_DEFAULT_EMAIL="youremail@yourdomain.com",
        PGADMIN_DEFAULT_PASSWORD="yoursecurepassword",
        PGADMIN_LISTEN_PORT="5050"
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
          port  "ui"  {
            static = 5050
          }
        }
      }
      service {
        name = "pgadmin"
        tags = [ "urlprefix-/pgadmin", "strip=/pgadmin"]
        port = "ui"

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