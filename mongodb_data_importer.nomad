job "guy_importer" {
  datacenters = ["eu-west-2"]
  type = "batch"

  group "import_data" {
    
      constraint {
      attribute = "${meta.name}"
      value     = "EU-guystack-worker-2"
    }
    
    count = 1
     network {
              mode = "bridge"
                }  
     task "dummy_data" {
      driver = "exec"


 template {
        data = <<EOH
        #!/bin/bash
      pip3 install pymongo requests && python3 local/repo/1/mongodb_importer.py && tail -f /dev/null
        EOH
        destination = "local/run.sh"
         perms = "755"
      }

      artifact {
           source   = "git::https://github.com/GuyBarros/nomad_jobs"
           destination = "local/repo/1/"
           
         }
        env{
              "MONGODB_SERVER" = "127.0.0.1"
              "MONGODB_PORT" =   27017
              "MONGODB_DATABASENAME"  =  "users"
          }
        config {
      command = "bash"
      args    = ["local/run.sh"]
    }

    }
        service {
                name = "dataimporter"
                tags = ["dataimporter"]
                port = "8888"
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
