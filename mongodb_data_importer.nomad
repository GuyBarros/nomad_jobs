job "mongodb_importer" {
  datacenters = ["dc1","eu-west-2"]
  type = "batch"

  group "import_data" {
    count = 1
    
     task "dummy_data" {
      driver = "exec"

 template {
        data = <<EOH
        #!/bin/bash
      pip3 install pymongo requests && python3 local/repo/1/mongodb_importer.py
        EOH
        destination = "local/run.sh"
         perms = "755"
      }

      artifact {
           source   = "git::https://github.com/GuyBarros/nomad_jobs"
           destination = "local/repo/1/"
           
         }
        env{

        }
        config {
      command = "bash"
      args    = ["local/run.sh"]
    }

    } 

  }

}
