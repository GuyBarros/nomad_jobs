
job "Consul-Resolvers" {
 datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]
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
"MeshGateway" : {
  "mode" : "local"
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
cat << EOF >  count-api-resolver.hcl
kind = "service-resolver"
name = "count-api"

redirect {
service    = "count-api"
  datacenter = "eu-west-2"
}
EOF


cat << EOF > mongodb.hcl
Kind = "service-defaults"
Name = "mongodb"
Protocol = "http"
MeshGateway = {
  mode = "local"
}
EOF
cat << EOF >  mongodb-resolver.hcl
kind = "service-resolver"
name = "mongodb"

redirect {
service    = "mongodb"
  datacenter = "eu-west-2"
}
EOF


consul config write proxy-defaults.json
consul config write count-api.hcl
consul config write count-api-resolver.hcl
consul config write mongodb.hcl
consul config write mongodb-resolver.hcl


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




