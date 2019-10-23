
job "Consul-Resolvers" {
 datacenters = ["eu-west-2","eu-west-1","ukwest","sa-east-1","ap-northeast-1","dc1","europe-west3-dc"]
  type = "batch"
  task "resolver-for-countapi" {

    driver = "exec"

    template {
      data = <<EOH
set -v

cat << EOF >  proxy-defaults.json
{
    "Kind": "proxy-defaults",
    "Name": "global",
MeshGateway : {
  mode : "local"
}
}
EOF


cat << EOF > count-api.hcl
Kind = "service-defaults"
Name = "count-api"
Protocol = "http"
MeshGateway = {
  mode = "local"
}
EOF
cat << EOF >  resolver.hcl
kind = "service-resolver"
name = "count-api"

redirect {
service    = "count-api"
  datacenter = "eu-west-2"
}
EOF

consul config write proxy-defaults.json
consul config write count-api.hcl
consul config write resolver.hcl


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




