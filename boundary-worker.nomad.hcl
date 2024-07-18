variable "boundary_version" {
  type = string
  default = "0.13.0"
}

variable "boundary_checksum" {
  type = string
  default = "7c3db27111d8622061b1fc667ab4b1bb0d6af04f8a8ae3e0f6dfd58dfb086d41"
}

job "boundary-worker" {
 region = "global"
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2"]
  type = "service"

  group "boundary-worker" {
    count = 3

      constraint {
        operator = "distinct_hosts"
        value = "true"
      }
    network {
           port  "api"  {
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
    task "boundary-worker.service" {
      driver = "raw_exec"

      env {
        VAULT_NAMESPACE = "boundary"
      }

      resources {
        cpu = 2000
        memory = 1024

      }
      artifact {
         source     = "https://releases.hashicorp.com/boundary/${var.boundary_version}/boundary_${var.boundary_version}_linux_amd64.zip"
        destination = "./tmp/"
        options {
         # checksum = "sha256:${var.boundary_checksum}"
        }
      }
      template {
        data        = <<EOF
        listener "tcp" {
    purpose = "proxy"
    address = "{{ env  "attr.unique.network.ip-address" }}:9202"
    tls_disable = true
}

worker {
  name = "local-worker-{{ env "NOMAD_ALLOC_INDEX" }}"
  description = "Worker on {{ env "attr.unique.hostname" }}"
   public_addr = "{{ env "attr.unique.platform.aws.public-ipv4" }}"
   controllers = [
     {{ range service "boundary-controller" }}
        "{{ .Address }}:9201",
     {{ end }}
  ]
     tags {
    region    = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2"]
    type      = ["demostack","workers"]
  }

}
kms "transit" {
  purpose            = "worker-auth"
  address            = "https://vault.service.consul:8200"
  disable_renewal    = "true"

  // Key configuration
  key_name           = "worker-auth"
  mount_path         = "transit/"
  namespace          = "boundary"

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
      file_name = "egress-worker.log"
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
        destination = "./tmp/boundary.d/config.hcl"
      }
      config {
        command = "/tmp/boundary"
        args = ["server", "-config=tmp/boundary.d/config.hcl"]
      }
      service {
        name = "boundary-worker"
        tags = ["boundary-worker","worker-${NOMAD_ALLOC_INDEX}"]
        port = "worker"

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
