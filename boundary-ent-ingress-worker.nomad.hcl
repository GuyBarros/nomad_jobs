variable "boundary_version" {
  type = string
  default = "1.0.2+ent"
}

variable "boundary_checksum" {
  type = string
  default = "537ed4916cfe584ccb0243449866a4f8dccd697ce4eb87ee2f9b5a4b21bae72c"
}


job "boundary-ingress-worker" {
 region = "global"
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]
  type = "service"

  group "boundary-worker" {
    count = 2

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
    task "boundary-ingress-worker.service" {
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


listener "tcp" {
  # Should be the IP of the NIC that the worker will connect on
  address = "{{ env  "attr.unique.network.ip-address" }}:9201"
  # The purpose of this listener
  purpose = "cluster"
  tls_disable = true
}

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
     tls_disable = true
}
 
hcp_boundary_cluster_id = "6f14cf8d-21a9-4421-ab43-562fbfe9fa64"

worker {
  auth_storage_path = "tmp/boundary.d/"
  recording_storage_path = "tmp/boundary.d/"
  # change this to the public ip address of the specific platform you are running or use "attr.unique.network.ip-address"
   public_addr = "{{ env "attr.unique.platform.aws.public-ipv4" }}"

     tags {
    type      = ["workers","ent","demostack","ingress","ingress-{{ env "node.unique.name" }}"]
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
        name = "boundary-ingress-worker"
        tags = ["boundary-ingress-worker","worker-${NOMAD_ALLOC_INDEX}"]
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
