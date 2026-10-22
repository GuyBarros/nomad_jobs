
variable "boundary_version" {
  type = string
  default = "1.0.2+ent"
}

variable "boundary_checksum" {
  type = string
  default = "975250804d1f08fb1e1020090030e866fb75c41bb7ba3b78a4a0ebe96a0b0e08"
}

variable "hcp_boundary_cluster_id" {
  type = string
  default = "6f14cf8d-21a9-4421-ab43-562fbfe9fa64"
}

job "boundary-hcp-worker" {
 region = "global"
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]
  type = "service"

  group "boundary-hcp-worker" {
    count = 1

      constraint {
        operator = "distinct_hosts"
        value = "true"
      }
    network {
          port  "worker"  {
            static = 9202
          }
          port  "client"  {
            static = 9201
          }
          port  "api"  {
            static = 9200
          }
        }
    task "boundary-hcp-worker.service" {
      driver = "raw_exec"

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
        disable_mlock = true

hcp_boundary_cluster_id = "6f14cf8d-21a9-4421-ab43-562fbfe9fa64"

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}


worker {
  auth_storage_path = "tmp/boundary.d/"
  recording_storage_path = "tmp/boundary.d/"
  # change this to the public ip address of the specific platform you are running or use "attr.unique.network.ip-address"
  # initial_upstreams = ["10.1.2.86:9202","10.1.2.148:9202"]
  
  public_addr = "{{ env "attr.unique.platform.aws.public-ipv4" }}"

     tags {
    type      = ["workers","ent","demostack","ingress","mhop-{{ env "node.unique.name" }}"]
  }

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
        destination = "./tmp/boundary.d/pki-worker.hcl"
      }
      config {
        command = "/tmp/boundary"
        args = ["server", "-config=tmp/boundary.d/pki-worker.hcl"]
      }
      service {
        name = "boundary-mhop-worker"
        tags = ["boundary-mhop-worker","worker-${NOMAD_ALLOC_INDEX}"]
        port = "worker"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "30s"
          timeout  = "5s"
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
