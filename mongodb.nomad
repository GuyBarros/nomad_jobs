variable "consul_namespace"{
  description = "which consul namespace you want to deploy this job to" 
  default = "default"
}
job "mongodb" {
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]
   type = "service"
    group "db" {
         count = 1
         consul{
      namespace = var.consul_namespace
    }
#           volume "mongodb_vol" {
#      type = "host"
#        source = "mongodb_mount"
#    }
     network {
                    mode = "bridge"
                    port "db"{
                      static = 27017
                    }
                }
    task "mongodb" {
            driver = "docker"
#            volume_mount {
#                volume      = "mongodb_vol"
#                destination = "/data/db"
#               }
            config {
                image = "mongo"
                ports = ["db"]
            }

            logs {
                max_files     = 5
                max_file_size = 15
            }
            resources {
                cpu = 500
                memory = 512
            }
            env{
              CONSUL_HTTP_TOKEN="11a9a399-3f1d-b431-2a09-5e50e0ea3a02"
            }

        }
         service {
                name = "mongodb"
                tags = ["mongodb"]
                port = "db"
                 connect {
     sidecar_service {}
   }
            }
    }

    group "express" {
        count = 1
        network {
         #    mode = "bridge"
              port "http" {
      static = 8082
      to     = 8082
    }
                }
    task "mongo-express" {
            driver = "docker"
            env {
                ME_CONFIG_MONGODB_SERVER = "127.0.0.1"
                ME_CONFIG_MONGODB_PORT = "27017"
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

