job "boundary-postgres" {
 region = "global"
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c"]
  type = "service"

  group "postgres" {
    count = 1

network {
        mode = "bridge"
        port "db" { 
          static = 5432
           }
     }
    task "postgres" {

      driver = "docker"
      config {
        image = "postgres"
         ports = ["db"]

      }
      env {
          POSTGRES_USER="root",
          POSTGRES_PASSWORD="rootpassword",
          POSTGRES_DB="boundary",
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
        name = "boundary-postgres"
        tags = ["postgres for boundary"]
        port = "db"

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
