job "guacamole" {
  datacenters = ["dc1", "eu-west-2a", "eu-west-2b", "eu-west-2c", "eu-west-2"]
  type        = "service"

  # All tasks share one network namespace (bridge mode), so guacamole talks to
  # guacd and postgres over 127.0.0.1 without exposing them outside the alloc.
  group "guacamole" {
    count = 1

    network {
      mode = "bridge"
      port "http" {
        static = 8080
        to     = 8080
      }
    }

    service {
      name = "guacamole"
      port = "http"
      tags = ["web", "urlprefix-/guacamole"]
      check {
        type     = "http"
        path     = "/guacamole/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    # Generate the full Guacamole PostgreSQL schema using the script shipped in
    # the guacamole image, and drop it where the postgres task will pick it up.
    task "init-schema" {
      driver = "docker"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      config {
        image      = "guacamole/guacamole:1.6.0"
        entrypoint = ["/bin/sh", "-c"]
        args       = ["mkdir -p /alloc/data/initdb && /opt/guacamole/bin/initdb.sh --postgresql > /alloc/data/initdb/initdb.sql"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }

    task "postgres" {
      driver = "docker"

      config {
        image = "postgres:16-alpine"
        volumes = [
          "../alloc/data/initdb:/docker-entrypoint-initdb.d:ro"
        ]
      }

      env {
        POSTGRES_DB       = "guacamole_db"
        POSTGRES_USER     = "guacamole_user"
        POSTGRES_PASSWORD = "your-secure-password"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }

    task "guacd" {
      driver = "docker"

      config {
        image = "guacamole/guacd:1.6.0"
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }

    task "guacamole" {
      driver = "docker"

      config {
        image = "guacamole/guacamole:1.6.0"
        ports = ["http"]
      }

      env {
        GUACD_HOSTNAME      = "127.0.0.1"
        GUACD_PORT          = "4822"
        POSTGRESQL_HOSTNAME = "127.0.0.1"
        POSTGRESQL_PORT     = "5432"
        POSTGRESQL_DATABASE = "guacamole_db"
        POSTGRESQL_USER     = "guacamole_user"
        POSTGRESQL_PASSWORD = "your-secure-password"
      }

      restart {
        attempts = 10
        interval = "5m"
        delay    = "15s"
        mode     = "delay"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
