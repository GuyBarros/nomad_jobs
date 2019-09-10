#vault secrets enable database
# vault write database/config/my-mongodb-database plugin_name=mongodb-database-plugin allowed_roles="my-role" connection_url="mongodb://{{username}}:{{password}}@mongodb.service.consul:27017/admin?ssl=true" username="root"  password="rootpassword"
# vault write database/roles/my-role db_name=my-mongodb-database creation_statements='{ "db": "admin", "roles": [{ "role": "readWrite" }, {"role": "read", "db": "foo"}] }' default_ttl="1h" max_ttl="24h"
job "mongodb" {

  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1"]
  type = "service"

  
  group "mongodb" {
    count = 1

    task "mongodb" {
      driver = "docker"
      config {
        image = "mongo"

        port_map {
          db = 27017
        }
      }
      
      env {
          MONGO_INITDB_ROOT_USERNAME="root",
      MONGO_INITDB_ROOT_PASSWORD="rootpassword"
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }
      resources {
        
        network {
          mbits = 10
          port  "db"  {
            static = 27017
          }
        }
      }
      service {
        name = "mongodb"
        tags = ["global", "mongodb","urlprefix-/mongodb"]
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
