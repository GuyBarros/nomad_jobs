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
        volumes = [
          "local/servers.json:/servers.json",
          "local/servers.passfile:/root/.pgpass"
        ]

      }
      template {
        perms = "600"
        change_mode = "noop"
        destination = "local/servers.passfile"
        data = <<EOH
postgres.service.consul:5432:postgres:root:rootpassword
EOH
      }
      template {
        change_mode = "noop"
        destination = "local/servers.json"
        data = <<EOH
{
  "Servers": {
    "1": {
      "Name": "Local Server",
      "Group": "Server Group 1",
      "Port": "5432",
      "Username": "root",
      "PassFile": "/root/.pgpass",
      "Host": "postgres.service.consul",
      "SSLMode": "disable",
      "MaintenanceDB": "postgres"
    }
  }
}
EOH
      }
      env {
        PGADMIN_DEFAULT_EMAIL="youremail@yourdomain.com",
        PGADMIN_DEFAULT_PASSWORD="yoursecurepassword",
        PGADMIN_LISTEN_PORT="5050"
        PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION="False"
        PGADMIN_SERVER_JSON_FILE="/servers.json"
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
        tags = [ "urlprefix-/pgadmin strip=/pgadmin"]
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