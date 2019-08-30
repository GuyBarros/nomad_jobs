job "phpldapadmin" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1"]
  type = "service"

  group "phpldapadmin" {
    count = 1

    task "phpldapadmin-server" {
      driver = "docker"
      config {
        image = "osixia/phpldapadmin:0.8.0"
        network_mode = "host"
        port_map {
          https = 443
        }    

      }
      env {
        PHPLDAPADMIN_LDAP_HOSTS="ldap-service.service.consul"
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
          port  "https"  {
            static = 443
          }
        }
      }
      service {
        name = "phpldapadmin-server"
        tags = ["urlprefix-/phpldapadmin-server strip=/phpldapadmin-server  proto=https tlsskipverify=true"]
        port = "https"

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
