job "nomad_federation" {
 datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1","europe-west3-dc"]
   type = "batch"

  
  task "wan_join" {
       constraint {
        attribute = "${meta.name}"
        value     = "EU-guystack-server-0"
      }
    driver = "raw_exec"

  config {
    command = "/usr/local/bin/nomad"
    args    = ["server","join","3.9.177.97:4648"]
  }
  }
}