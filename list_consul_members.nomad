job "consul_commands" {
 datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1","europe-west3-dc"]
   type = "batch"

  
  task "list_members" {
       constraint {
        attribute = "${meta.type}"
        value     = "server"
      }
    driver = "raw_exec"

  config {
    command = "/usr/local/bin/consul"
    args    = ["members", "list","-wan"]
  }
  }
}