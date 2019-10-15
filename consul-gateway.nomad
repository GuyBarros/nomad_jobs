
job "Consul-Service-Gateways" {
 datacenters = ["eu-west-2","eu-west-1","ukwest","sa-east-1","ap-northeast-1","dc1","europe-west3-dc"]
  type = "system"

  task "consul-gateway" {
    
    driver = "exec"

    template {
      data = <<EOH
set -v

consul connect envoy \
 -mesh-gateway -register \
   -service "gateway" \
     -address "$(private_ip):8700" \
      -wan-address "$(public_ip):8700"  \
      -admin-bind "127.0.0.1:19005"                    
EOH

      destination = "script.sh"
      perms = "755"
    }

    config {
      command = "bash"
      args    = ["script.sh"]
    }
  }

}




