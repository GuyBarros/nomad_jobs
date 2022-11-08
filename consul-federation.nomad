job "consul_federation" {
 datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]
   type = "batch"

  
  task "wan_join" {
       constraint {
        attribute = "${meta.type}"
        value     = "server"
      }
    driver = "raw_exec"

  config {
    command = "/usr/bin/consul"
    args    = ["join","-wan","server-0.sp-guystack.guy.aws.hashidemos.io"]
  }
  }
}
