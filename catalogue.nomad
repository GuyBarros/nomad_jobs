job "catalogue-middleware" {
  datacenters = ["eu-west-2","ukwest"]

  constraint {
    attribute = "${attr.kernel.name}"
    value = "linux"
  }

/*
  constraint {
    operator = "distinct_hosts"
    value = "true"
  }
*/
  update {
    stagger = "10s"
    max_parallel = 1
  }


  # - catalogue - #
  group "catalogue" {
    count = 3

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    # - app - #
    task "catalogue" {
      driver = "docker"

      config {
        image = "rberlind/catalogue:latest"
        command = "/app"
        args = ["-port", "8080", "-DSN", "catalogue_user:default_password@tcp(${NOMAD_ADDR_catalogueproxy_upstream})/socksdb"]
        hostname = "catalogue.service.consul"
        # network_mode = "bridge"
        port_map = {
          http = 8080
        }
      }

      service {
        name = "catalogue"
        tags = ["urlprefix-/catalogue"]
        port = "http"
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 128 # 32MB
        network {
          mbits = 10
          port "http" {
            
          }
        }
      }
    } # - end app - #

    # - catalogue connect upstream proxy - #
    task "catalogueproxy" {
      driver = "exec"

      config {
        command = "/usr/local/bin/run-proxy.sh"
        args    = ["${NOMAD_IP_proxy}", "${NOMAD_TASK_DIR}", "catalogue"]
      }

      meta {
        proxy_name = "catalogue"
        proxy_target = "catalogue-db"
      }

      template {
        data = <<EOH
{
    "name": "{{ env "NOMAD_META_proxy_name" }}-proxy",
    "port": {{ env "NOMAD_PORT_proxy" }},
    "kind": "connect-proxy",
    "proxy": {
      "destination_service_name": "{{ env "NOMAD_META_proxy_name" }}",
      "destination_service_id": "{{ env "NOMAD_META_proxy_name" }}",
      "upstreams": [
        {
          "destination_name": "{{ env "NOMAD_META_proxy_target" }}",
          "local_bind_address": "{{ env "NOMAD_IP_upstream" }}",
          "local_bind_port": {{ env "NOMAD_PORT_upstream" }}
        }
      ]
    }
}
EOH

        destination = "local/${NOMAD_META_proxy_name}-proxy.json"
      }


      resources {
        network {
          port "proxy" {}
          port "upstream" {}
        }
      }
    } # - end catalogue upstream proxy - #
  } # end catalogue group

}
