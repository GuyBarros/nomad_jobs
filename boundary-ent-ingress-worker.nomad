variable "boundary_version" {
  type = string
  default = "0.12.3+hcp"
}

variable "boundary_checksum" {
  type = string
  default = "f86d4520c279701c88a943a863779d2284514d38b2bfd36f218ab3464fadfa63"

}


job "boundary-ingress-worker" {
 region = "global"
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]
  type = "service"

  group "boundary-worker" {
    count = 3

      constraint {
        operator = "distinct_hosts"
        value = "true"
      }
    network {
          port  "worker"  {
            static = 9202
          }
        }
    task "boundary-ingress-worker.service" {
      driver = "raw_exec"

      resources {
        cpu = 2000
        memory = 1024

      }
      artifact {
         source     = "https://releases.hashicorp.com/boundary-worker/${var.boundary_version}/boundary-worker_${var.boundary_version}_linux_amd64.zip"
        destination = "./tmp/"
        options {
          checksum = "sha256:${var.boundary_checksum}"
        }
      }
      template {
        data        = <<EOF
        disable_mlock = true


listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
     tls_disable = true
}
 


worker {
  auth_storage_path = "tmp/boundary.d/"
  # change this to the public ip address of the specific platform you are running or use "attr.unique.network.ip-address"
   public_addr = "{{ env "attr.unique.platform.aws.public-ipv4" }}"
   initial_upstreams = [
     {{ range service "boundary-controller" }}
        "{{ .Address }}:9201",
     {{ end }}
  ]
     tags {
    type      = ["workers","hcp","demostack","ingress"]
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
        command = "/tmp/boundary-worker"
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
