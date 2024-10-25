variable "boundary_version" {
  type = string
  default = "0.18.0+ent"
}

variable "boundary_checksum" {
  type = string
  default = "319c91a2137d8ffb9595aa801dedd19f806f868a577010e35b591a45eb13ff39"
}

variable "ent_license" {
  type = string
  default = ""
}

job "boundary-controller" {
 region = "global"
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2"]
  type = "service"

  group "boundary-controller" {
       count = 1
     network {
          port  "ui"  {
            static = 9200
          }
           port  "cluster"  {
            static = 9201
          }
           port  "worker"  {
            static = 9202
          }
        }
        vault {
      policies = ["superuser"]
    }
##############################################################################################
         task "boundary.init" {
         lifecycle {
        hook    = "prestart"
      }
      driver = "raw_exec"
       env {
        VAULT_NAMESPACE = "boundary"
      }
      resources {
        cpu = 512
        memory = 512
      }
      artifact {
         source     = "https://releases.hashicorp.com/boundary/${var.boundary_version}/boundary_${var.boundary_version}_${attr.kernel.name}_${attr.cpu.arch}.zip"
        destination = "./tmp/"
        options {
         # checksum = "sha256:${var.boundary_checksum}"
        }
      }
      template {
        data        = <<TEMPLATEEOF
echo "--> Generating boundary configuration"
sudo tee tmp/config.hcl  <<"EOF"
disable_mlock = true

 listener "tcp" {
  # The purpose of this listener block
  address = "{{ env  "attr.unique.network.ip-address" }}:9200"
  purpose = "api"
  tls_disable = true

  # Uncomment to enable CORS for the Admin UI. Be sure to set the allowed origin(s)
  # to appropriate values.
   cors_enabled = true
   cors_allowed_origins = ["*"]
}

listener "tcp" {
  # Should be the IP of the NIC that the worker will connect on
  address = "{{ env  "attr.unique.network.ip-address" }}:9201"
  # The purpose of this listener
  purpose = "cluster"
  tls_disable = true
}

controller {
  name = "boundary-controller-{{ env "NOMAD_ALLOC_INDEX" }}"
  description = "Controller on on {{ env "attr.unique.hostname" }}"
  database {
    url = "postgresql://root:rootpassword@boundary-postgres.service.consul:5432/boundary?sslmode=disable"
  }

  license = "${var.ent_license}"
}

kms "transit" {
  purpose            = "root"
  address            = "https://vault.service.consul:8200"
  disable_renewal    = "true"

  // Key configuration
  key_name           = "root"
  namespace          = "boundary"
  mount_path         = "transit/"

}

kms "transit" {
  purpose            = "worker-auth"
  address            = "https://vault.service.consul:8200"
  disable_renewal    = "true"

  // Key configuration
  key_name           = "worker-auth"
  namespace          = "boundary"
  mount_path         = "transit/"

}

events {
  audit_enabled       = true
  sysevents_enabled   = true
  observations_enable = true
  sink "stderr" {
    name = "all-events"
    description = "All events sent to stderr"
    event_types = ["*"]
    format = "cloudevents-json"
  }
  sink {
    name = "file-sink"
    description = "All events sent to a file"
    event_types = ["*"]
    format = "cloudevents-json"
    file {
      path = "/var/log/boundary"
      file_name = "controller.log"
    }
    audit_config {
      audit_filter_overrides {
        sensitive = "redact"
        secret    = "redact"
      }
    }
  }
}



EOF

echo "--> running boundary init"
tmp/boundary database init -format=json -config=tmp/config.hcl >> init.txt

echo "--> init output"
cat init.txt

# echo "-->  checking to see if database already initialized before writting to consul"
# if [ $(cat init.txt) == "Database already initialized" ]
# then
# echo "--> Database already initialized, skipping"
# else
echo "--> adding to consul"
DATE=$(date +"%Y%m%d%H%M")
consul kv put service/boundary/boundary-init-$DATE @init.txt
# fi


echo "--> done"
TEMPLATEEOF
        destination = "init.sh"
      }
      config {
      command = "bash"
      args    = ["init.sh"]
      }
    }
############################################################################################
    task "boundary.service" {
      driver = "raw_exec"
  lifecycle {
        hook    = "poststart"
      }
     constraint {
        attribute = "${meta.type}"
        value     = "server"
      }
      env {
        VAULT_NAMESPACE = "boundary"
      }
      resources {
        cpu = 2000
        memory = 1024

      }
      artifact {
        source     = "https://releases.hashicorp.com/boundary/${var.boundary_version}/boundary_${var.boundary_version}_${attr.kernel.name}_${attr.cpu.arch}.zip"
        destination = "./tmp/"
        options {
          # checksum = "sha256:${var.boundary_checksum}"
        }
      }
      template {
        data        = <<EOF
      listener "tcp" {
  address = "{{ env  "attr.unique.network.ip-address" }}:9200"
  # The purpose of this listener block
  purpose = "api"
  tls_disable = true

  # Uncomment to enable CORS for the Admin UI. Be sure to set the allowed origin(s)
  # to appropriate values.
  # cors_enabled = true
  # cors_allowed_origins = ["*"]
}

listener "tcp" {
  # Should be the IP of the NIC that the worker will connect on
  address = "{{ env  "attr.unique.network.ip-address" }}:9201"
  # The purpose of this listener
  purpose = "cluster"
  tls_disable = true
}
controller {
  name = "boundary-controller-{{ env "NOMAD_ALLOC_INDEX" }}"
  description = "Controller on on {{ env "attr.unique.hostname" }}"
  database {
    url = "postgresql://root:rootpassword@boundary-postgres.service.consul:5432/boundary?sslmode=disable"
  }
  license = "${var.ent_license}"
}

kms "transit" {
  purpose            = "root"
  address            = "https://vault.service.consul:8200"
  disable_renewal    = "true"

  // Key configuration
  key_name           = "root"
  namespace          = "boundary"
  mount_path         = "transit/"
}

kms "transit" {
  purpose            = "worker-auth"
  address            = "https://vault.service.consul:8200"
  disable_renewal    = "true"

  // Key configuration
  key_name           = "worker-auth"
  namespace          = "boundary"
  mount_path         = "transit/"
}



        EOF
        destination = "tmp/config.hcl"
      }
      config {
        command = "/tmp/boundary"
        args = ["server", "-config=tmp/config.hcl"]
      }
      service {
        name = "boundary-controller"
        tags = ["boundary-controller","controller-${NOMAD_ALLOC_INDEX}"]
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

}
