job "consul_commands" {
 datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]
   type = "batch"

  
  task "list_members" {
       
    driver = "raw_exec"

  config {
    command = "/usr/bin/consul"
    args    = ["members", "list","-wan"]
  }
  }
}