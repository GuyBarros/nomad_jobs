job "boundary-server" {
 region = "global"
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c"]
  type = "service"

  group "boundary-server" {
    count = 1
    task "boundary.init" {
         lifecycle {
        hook    = "prestart"
      }
      driver = "raw_exec"
      resources {
        cpu = 512
        memory = 512
      }
      artifact {
        source     = "https://releases.hashicorp.com/boundary/0.1.1/boundary_0.1.1_linux_amd64.zip"
        # source      = "https://releases.hashicorp.com/boundary/0.1.1/boundary_0.1.1_${attr.kernel.name}_${attr.cpu.arch}.zip"
        destination = "tmp/"
        options {
          checksum = "sha256:10ac2ab9b46a0b0644eb08f9d2fb940734dc5c55c23d0ec43528bc73a591790b"
        }
      }
      template {
        data        = <<TEMPLATEEOF
echo "--> Generating boundary configuration"
sudo tee tmp/config.hcl  <<"EOF"
 listener "tcp" {
  address = "0.0.0.0"
  # The purpose of this listener block
  purpose = "api"
  tls_disable = true

  # Uncomment to enable CORS for the Admin UI. Be sure to set the allowed origin(s)
  # to appropriate values.
  cors_enabled = true
  cors_allowed_origins = ["*.hashidemos.io"]
}

listener "tcp" {
  # Should be the IP of the NIC that the worker will connect on
  address = "0.0.0.0"
  # The purpose of this listener
  purpose = "cluster"
  tls_disable = true
}

controller {
  name = "example-controller"
  description = "An example controller"
  database {
    url = "postgresql://root:rootpassword@boundary-postgres.service.consul:5432/boundary?sslmode=disable"
  }
}

kms "transit" {
  purpose            = "root"
  address            = "https://vault.service.consul:8200"
  token              = "s.XTIw8fXc5zKpUhKUDoVH62mr"
  disable_renewal    = "true"

  // Key configuration
  key_name           = "root"
  mount_path         = "transit/"
  namespace          = "boundary/"

}

kms "transit" {
  purpose            = "worker-auth"
  address            = "https://vault.service.consul:8200"
  token              = "s.XTIw8fXc5zKpUhKUDoVH62mr"
  disable_renewal    = "true"

  // Key configuration
  key_name           = "worker-auth"
  mount_path         = "transit/"
  namespace          = "boundary/"

}

EOF

echo "--> init config file"
cat tmp/config.hcl

echo "--> running boundary init"
tmp/boundary database init -config=tmp/config.hcl >> init.txt

echo "--> init output"
cat init.txt

echo "--> adding to consul"
consul kv put service/boundary/init @init.txt

echo "--> done"
TEMPLATEEOF
        destination = "init.sh"
      }
      config {
      command = "bash"
      args    = ["init.sh"]
      }
    }

  ################################################################################################

    task "boundary.service" {
      driver = "raw_exec"

     constraint {
        attribute = "${meta.name}"
        value     = "EU-guystack-server-2"
      }
      resources {
        cpu = 2000
        memory = 1024
        network {
          mbits = 10
          port  "ui"  {
            static = 9200
          }
           port  "worker"  {
            static = 9202
          }
        }
      }
      artifact {
         source     = "https://releases.hashicorp.com/boundary/0.1.1/boundary_0.1.1_linux_amd64.zip"
        # source      = "https://releases.hashicorp.com/boundary/0.1.1/boundary_0.1.1_${attr.kernel.name}_${attr.cpu.arch}.zip"
        destination = "./tmp/"
        options {
          checksum = "sha256:10ac2ab9b46a0b0644eb08f9d2fb940734dc5c55c23d0ec43528bc73a591790b"
        }
      }
      template {
        data        = <<EOF
      listener "tcp" {
  address = "0.0.0.0"
  # The purpose of this listener block
  purpose = "api"
  tls_disable = true

  # Uncomment to enable CORS for the Admin UI. Be sure to set the allowed origin(s)
  # to appropriate values.
  cors_enabled = true
  cors_allowed_origins = ["*.hashidemos.io"]
}

listener "tcp" {
  # Should be the IP of the NIC that the worker will connect on
  address = "0.0.0.0"
  # The purpose of this listener
  purpose = "cluster"
  tls_disable = true
}
controller {
  name = "example-controller"
  description = "An example controller"
  database {
    url = "postgresql://root:rootpassword@boundary-postgres.service.consul:5432/boundary?sslmode=disable"
  }
}

kms "transit" {
  purpose            = "root"
  address            = "https://vault.service.consul:8200"
  token              = "s.XTIw8fXc5zKpUhKUDoVH62mr"
  disable_renewal    = "true"

  // Key configuration
  key_name           = "root"
  mount_path         = "transit/"
  namespace          = "boundary/"

}

kms "transit" {
  purpose            = "worker-auth"
  address            = "https://vault.service.consul:8200"
  token              = "s.XTIw8fXc5zKpUhKUDoVH62mr"
  disable_renewal    = "true"

  // Key configuration
  key_name           = "worker-auth"
  mount_path         = "transit/"
  namespace          = "boundary/"

}



        EOF
        destination = "tmp/config.hcl"
      }
      config {
        command = "/tmp/boundary"
        args = ["server", "-config=tmp/config.hcl"]
      }
      service {
        name = "boundary-server"
        tags = ["boundary-server"]
        port = "ui"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }

  }

  update {
    max_parallel = 1
    min_healthy_time = "5s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 0
  }
}
