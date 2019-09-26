job "mongodb_importer" {
  datacenters = ["dc1","eu-west-2"]
  type = "batch"

  group "import_data" {
    count = 1
    
     task "dummy_data" {
      driver = "exec"


      artifact {
           source   = "git::https://github.com/ozlerhakan/mongodb-json-files"
           destination = "local/repo/1/"
           
         }
        env{

        }
      config {
        command = "local/repo/1/import.sh"
        args    = ["-s","--uri=mongodb+srv://root:example@mongodb.service.consul"]
      }

    } 

  }

}
