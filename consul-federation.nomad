job "consul_federation" {
 datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1","europe-west3-dc"]
   type = "batch"

  
  task "wan_join" {
       constraint {
        attribute = "${meta.type}"
        value     = "server"
      }
    driver = "raw_exec"

  config {
    command = "/usr/local/bin/consul"
    args    = ["join","-wan","server-0.sp-guystack.guy.aws.hashidemos.io"]
  }
  }
}
