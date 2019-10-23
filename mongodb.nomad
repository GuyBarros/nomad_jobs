job "mongodb" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1"]
   type = "service"
    group "db" {
         count = 1
           volume "mongodb_vol" {
      type = "host"
        source = "mongodb_mount"
    }
     network {
                    mode = "bridge"
                }
    task "mongodb" {
            driver = "docker"
            volume_mount {
                volume      = "mongodb_vol"
                destination = "/data/db"
               }
            config {
                image = "mongo"
            }
 
            logs {
                max_files     = 5
                max_file_size = 15
            }
            resources {
                cpu = 500
                memory = 512
            }
           
        }
         service {
                name = "mongodb"
                tags = ["mongodb"]
                port = "27017"
                 connect {
     sidecar_service {}
   }
            }
    }
 
    group "express" {
        count = 1
        network {
              mode = "bridge"
              port "http" {
      static = 8081
      to     = 8081
    }
                }  
    task "mongo-express" {
            driver = "docker"
            env {
                "ME_CONFIG_MONGODB_SERVER" = "127.0.0.1"
                "ME_CONFIG_MONGODB_PORT" = "27017"
            }
            config {
                image = "mongo-express"
            }
 
            logs {
                max_files     = 5
                max_file_size = 15
            }
            resources {
                cpu = 500
                memory = 512
                
 
            }
         
        }
           service {
                name = "mongo-express"
                tags = ["mongo-express"]
                port = "http"
                 connect {
         sidecar_service {
           proxy {
             upstreams {
               destination_name = "mongodb"
               local_bind_port = 27017
             }
           }
         }
       }
            }
    }
}
