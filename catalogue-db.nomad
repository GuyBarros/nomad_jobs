job "catalogue-middleware" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1"]

  constraint {
    attribute = "${attr.kernel.name}"
    value = "linux"
  }

  group "cataloguedb" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    # - db - #
    task "cataloguedb" {
      driver = "docker"

      config {
        image = "rberlind/catalogue-db:latest"
       # network_mode = "bridge"
        port_map = {
          db  = 3306
        }
      }

      env {
        MYSQL_DATABASE = "socksdb"
        MYSQL_ALLOW_EMPTY_PASSWORD = "true"
      }

      service {
        name = "catalogue-db"
        tags = ["db", "catalogue", "catalogue-db"]
        port = "db"
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 256 # 256MB
        network {
          mbits = 10
        port "db" {}
        }
      }

    } # - end db - #

    # - cataloguedb proxy - #
    task "cataloguedbproxy" {
      driver = "exec"

      config {
        command = "/usr/local/bin/consul"
        args    = [
          "connect", "proxy",
          "-http-addr", "${NOMAD_IP_proxy}:8500",
          "-log-level", "trace",
          "-service", "catalogue-db",
          "-service-addr", "${NOMAD_ADDR_cataloguedb_db}",
          "-listen", ":${NOMAD_PORT_proxy}",
          "-register",
        ]
      }

      resources {
        network {
          port "proxy" {}
        }
      }
    } # - end cataloguedbproxy - #
  } # - end cataloguedb group - #
}