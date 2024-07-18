
job "Consul-Service-Gateways" {
 datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]
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




