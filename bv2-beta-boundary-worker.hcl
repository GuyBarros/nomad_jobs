variable "boundary_version" {
  type = string
  default = "0.13.0+ent"
}

variable "boundary_checksum" {
  type = string
  default = "f86d4520c279701c88a943a863779d2284514d38b2bfd36f218ab3464fadfa63"

}

variable "boundary_auth_tokens" {
  default = "neslat_2KrTaG72coHRjJmR9RsyyESJ9ShxpSRR4c5a3zMPYQACgFcrPGw8Ck5rmh3QuhdxTQp77n83BhBgVMw52FazwAGofiV6p"
}

variable "boundary_ingress_worker_count"{
  type = number
  default = 3
}

variable "initial_upstreams_address"{
  type = string
  default = "42e0c292-9833-4c5e-b9fa-67bb7a11182e.boundary.hashicorp.cloud"
}


job "boundary-ingress-worker" {
 region = "global"
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]
  type = "service"

  group "boundary-worker" {
    count = var.boundary_ingress_worker_count

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
        source     = "https://releases.hashicorp.com/boundary/${var.boundary_version}/boundary_${var.boundary_version}_linux_amd64.zip"
        destination = "./tmp/"
        options {
          # checksum = "sha256:${var.boundary_checksum}"
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
   initial_upstreams = [ "${var.initial_upstreams_address}"
  ]
     tags {
    type      = ["workers","ent","demostack","ingress"]
  }
   controller_generated_activation_token = "${boundary_auth_token}"
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
        address = "${attr.unique.platform.aws.public-ipv4}"
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