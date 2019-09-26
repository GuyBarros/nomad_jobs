#vault secrets enable database
# vault write database/config/my-mongodb-database plugin_name=mongodb-database-plugin allowed_roles="my-role" connection_url="mongodb://{{username}}:{{password}}@mongodb.service.consul:27017/admin?ssl=true" username="root"  password="rootpassword"
# vault write database/roles/my-role db_name=my-mongodb-database creation_statements='{ "db": "admin", "roles": [{ "role": "readWrite" }, {"role": "read", "db": "foo"}] }' default_ttl="1h" max_ttl="24h"
job "mongodb" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1"]
   type = "service"
    group "db" {
         count = 1
           volume "mongodb_vol" {
      type = "host"
 
      config {
        source = "mongodb_mount"
      }
    }
    
    task "mongodb" {
            driver = "docker"
            env {
               "MONGO_INITDB_ROOT_USERNAME" = "root"
               "MONGO_INITDB_ROOT_PASSWORD" = "example"
            }
            volume_mount {
                volume      = "mongodb_vol"
                destination = "/data/db"
               }
            config {
                image = "mongo"
                network_mode = "host"
                port_map {
                     db = 27017
                }
            }
 
            logs {
                max_files     = 5
                max_file_size = 15
            }
            resources {
                cpu = 500
                memory = 512
                network {
                    mbits = 10
                    port  "db"  { 
                        static = 27017
                    }
                }  
 
            }
            service {
                name = "mongodb"
                tags = ["mongodb"]
                port = "db"
                check {
                    type = "tcp"
                    interval = "10s"
                    timeout = "4s"
                }
            }
        }
    }
 
    group "express" {
        count = 1
    task "mongo-express" {
            driver = "docker"
            env {
                "ME_CONFIG_MONGODB_ADMINUSERNAME" = "root"
                "ME_CONFIG_MONGODB_ADMINPASSWORD" = "example"
                "ME_CONFIG_MONGODB_SERVER" = "mongodb.service.consul"
                "ME_CONFIG_MONGODB_PORT" = "27017"
            }
            config {
                image = "mongo-express"
                network_mode = "host"
                port_map {
                     http = 8081
                }
            }
 
            logs {
                max_files     = 5
                max_file_size = 15
            }
            resources {
                cpu = 500
                memory = 512
                network {
                    mbits = 10
                    port  "http"  { 
                        static = 8081
                    }
                }  
 
            }
            service {
                name = "mongo-express"
                tags = ["mongo-express"]
                port = "http"
                check {
                    type = "tcp"
                    interval = "10s"
                    timeout = "4s"
                }
            }
        }
    }
}
