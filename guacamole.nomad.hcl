job "guacamole" {
  datacenters = ["dc1","eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2"]

  group "database" {
    count = 1

    network {
      port "db" {
        static = 5432
      }
    }

    service {
      name = "postgres"
      port = "db"
      tags = ["database"]
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "init-script" {
      driver = "raw_exec"

      config {
        command = "/bin/sh"
        args = ["-c", "echo 'CREATE TABLE guacamole_entity (entity_id serial PRIMARY KEY, name varchar(128) NOT NULL UNIQUE, type varchar(32) NOT NULL); CREATE TABLE guacamole_user (entity_id integer PRIMARY KEY REFERENCES guacamole_entity(entity_id) ON DELETE CASCADE, username varchar(128) NOT NULL UNIQUE, password_hash bytea NOT NULL, password_salt bytea NOT NULL, password_date timestamp NOT NULL, disabled boolean NOT NULL DEFAULT false, expired boolean NOT NULL DEFAULT false, access_window_start time, access_window_end time, valid_from timestamp, valid_until timestamp, timezone varchar(64));' > ./tmp/local/postgres-init/initdb.sql"]
      }

      template {
        data = <<EOF
#!/bin/bash
echo 'CREATE TABLE guacamole_entity (
    entity_id serial PRIMARY KEY,
    name varchar(128) NOT NULL UNIQUE,
    type varchar(32) NOT NULL
);
CREATE TABLE guacamole_user (
    entity_id integer PRIMARY KEY REFERENCES guacamole_entity(entity_id) ON DELETE CASCADE,
    username varchar(128) NOT NULL UNIQUE,
    password_hash bytea NOT NULL,
    password_salt bytea NOT NULL,
    password_date timestamp NOT NULL,
    disabled boolean NOT NULL DEFAULT false,
    expired boolean NOT NULL DEFAULT false,
    access_window_start time,
    access_window_end time,
    valid_from timestamp,
    valid_until timestamp,
    timezone varchar(64)
);
-- Additional tables and indexes as required by Guacamole
-- Refer to the Guacamole schema documentation for a complete list of tables and indexes' > /local/postgres-init/initdb.sql
EOF

        destination = "./tmp/local/postgres-init/initdb.sql"
      }

      lifecycle {
        hook = "prestart"
      }

      resources {
        cpu    = 100
        memory = 50
      }
    }

    task "postgres" {
      driver = "docker"

      config {
        image = "postgres:latest"
        
        ports = ["db"]

        env = {
          POSTGRES_DB       = "guacamole_db"
          POSTGRES_USER     = "guacamole_user"
          POSTGRES_PASSWORD = "your-secure-password"
        }

        volumes = [
          "./tmp/local/postgres-init:/docker-entrypoint-initdb.d"
        ]
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }

  group "guacamole" {
    count = 1

    network {
      port "guacamole" {
        static = 8080
      }
    }

    service {
      name = "guacamole"
      port = "guacamole"
      tags = ["web"]
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "guacamole" {
      driver = "docker"

      config {
        image = "guacamole/guacamole:latest"

        ports = ["guacamole"]

        env = {
          GUACAMOLE_HOME              = "/guacamole"
          POSTGRES_HOSTNAME           = "postgres.service.consul"
          POSTGRES_PORT               = "5432"
          POSTGRES_DATABASE           = "guacamole_db"
          POSTGRES_USER               = "guacamole_user"
          POSTGRES_PASSWORD           = "your-secure-password"
        }

        volumes = [
          "local/guacamole:/guacamole"
        ]
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }

    task "guacd" {
      driver = "docker"

      config {
        image = "guacamole/guacd:latest"
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
