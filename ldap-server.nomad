job "LDAP" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1"]
  type = "service"

  group "openldap" {
    count = 1

    task "ldap-service" {
      driver = "docker"
      config {
        image = "osixia/openldap"
        network_mode = "host"
        port_map {
          LDAP = 389
        }    

      }
      env {
        LDAP_TLS = "false"
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
          port  "LDAP"  {
            static = 389
          }
        }
      }
      service {
        name = "ldap-service"
        tags = ["urlprefix-/ldap-service strip=/ldap-service"]
        port = "LDAP"

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
