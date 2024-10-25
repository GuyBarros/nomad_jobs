job "guacamole" {
  datacenters = ["dc1"]
  type        = "service"

  group "guacamole" {
    count = 1

    network {
      mode = "bridge"
      port "nginx" {
        static = 8443
      }
      port "guacamole" {
        static = 8080
      }
    }

    service {
      name = "guacamole"
      port = "guacamole"
      tags = ["urlprefix-/guacamole"]
      check {
        name     = "alive"
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "guacd" {
      driver = "docker"

      config {
        image = "guacamole/guacd"
        network_mode = "guacnetwork_compose"
        volumes = [
          "./drive:/drive:rw",
          "./record:/record:rw"
        ]
      }

      resources {
        cpu    = 500
        memory = 256
      }

      restart {
        attempts = 10
        interval = "5m"
        delay    = "25s"
        mode     = "delay"
      }
    }

    task "postgres" {
      driver = "docker"

      config {
        image = "postgres:15.2-alpine"
        network_mode = "guacnetwork_compose"
        volumes = [
          "./init:/docker-entrypoint-initdb.d:z",
          "./data:/var/lib/postgresql/data:Z"
        ]
        env = {
          PGDATA = "/var/lib/postgresql/data/guacamole"
          POSTGRES_DB = "guacamole_db"
          POSTGRES_PASSWORD = "ChooseYourOwnPasswordHere1234"
          POSTGRES_USER = "guacamole_user"
        }
      }

      resources {
        cpu    = 500
        memory = 512
      }

      restart {
        attempts = 10
        interval = "5m"
        delay    = "25s"
        mode     = "delay"
      }
    }

    task "guacamole" {
      driver = "docker"

      config {
        image = "guacamole/guacamole"
        network_mode = "guacnetwork_compose"
        depends_on = ["guacd", "postgres"]
        volumes = [
          "./record:/record:rw"
        ]
        env = {
          GUACD_HOSTNAME    = "guacd"
          POSTGRES_DATABASE = "guacamole_db"
          POSTGRES_HOSTNAME = "postgres"
          POSTGRES_PASSWORD = "ChooseYourOwnPasswordHere1234"
          POSTGRES_USER     = "guacamole_user"
        }
      }

      resources {
        cpu    = 500
        memory = 512
      }

      restart {
        attempts = 10
        interval = "5m"
        delay    = "25s"
        mode     = "delay"
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx:latest"
        network_mode = "guacnetwork_compose"
        volumes = [
          "./nginx/templates:/etc/nginx/templates:ro",
          "./nginx/ssl/self.cert:/etc/nginx/ssl/self.cert:ro",
          "./nginx/ssl/self-ssl.key:/etc/nginx/ssl/self-ssl.key:ro"
        ]
        ports = ["8443:443"]
      }

      resources {
        cpu    = 500
        memory = 256
      }

      restart {
        attempts = 10
        interval = "5m"
        delay    = "25s"
        mode     = "delay"
      }
    }
  }
}
