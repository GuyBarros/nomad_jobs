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
  #cors_enabled = true
  #cors_allowed_origins = ["yourcorp.yourdomain.com"]
}

listener "tcp" {
  # Should be the IP of the NIC that the worker will connect on
  address = "0.0.0.0"
  # The purpose of this listener
  purpose = "cluster"
  tls_disable = true
}

listener "tcp" {
    purpose = "proxy"
    tls_disable = true
}

worker {
  name = "local-worker"
  description = "A local worker"
   public_addr = "server-2.eu-guystack.original.aws.hashidemos.io"
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
  token              = "s.uGadFQIpc4aLqijmyMFo20Jk"
  disable_renewal    = "true"

  // Key configuration
  key_name           = "root"
  mount_path         = "transit/"
  namespace          = "boundary/"

}


kms "transit" {
  purpose            = "worker-auth"
  address            = "https://vault.service.consul:8200"
  token              = "s.uGadFQIpc4aLqijmyMFo20Jk"
  disable_renewal    = "true"

  // Key configuration
  key_name           = "worker-auth"
  mount_path         = "transit/"
  namespace          = "boundary/"

}
        EOF
        destination = "./tmp/boundary.d/config.hcl"
      }
      config {
        command = "./tmp/boundary"
        args = ["database","init","-config=tmp/boundary.d/config.hcl" , ">","init.txt" ,"&&", "consul", "kv", "put", "service/boundary/init", "@init.txt"]
      }
    }
    task "boundary.service" {
      driver = "raw_exec"

     constraint {
        attribute = "${meta.type}"
        value     = "server"
      }
      resources {
        cpu = 2000
        memory = 1024
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
  purpose = "api"
  tls_disable = true
  }

listener "tcp" {
  address = "0.0.0.0"
  purpose = "cluster"
  tls_disable = true
}

listener "tcp" {
    purpose = "proxy"
    tls_disable = true
}

worker {
  name = "local-worker"
  description = "A local worker"
     public_addr = "server-2.eu-guystack.original.aws.hashidemos.io"
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
  token              = "s.uGadFQIpc4aLqijmyMFo20Jk"
  disable_renewal    = "true"

  // Key configuration
  key_name           = "root"
  mount_path         = "transit/"
  namespace          = "boundary/"

}


kms "transit" {
  purpose            = "worker-auth"
  address            = "https://vault.service.consul:8200"
  token              = "s.uGadFQIpc4aLqijmyMFo20Jk"
  disable_renewal    = "true"

  // Key configuration
  key_name           = "worker-auth"
  mount_path         = "transit/"
  namespace          = "boundary/"

}

        EOF
        destination = "./tmp/boundary.d/config.hcl"
      }
      config {
        command = "/tmp/boundary"
        args = ["server", "-config=tmp/boundary.d/config.hcl"]
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
