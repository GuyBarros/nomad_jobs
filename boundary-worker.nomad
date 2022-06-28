variable "boundary_version" {
  type = string
  default = "0.9.0"
}

variable "boundary_checksum" {
  type = string
  default = "e97c8b93e23326c5cd0cf0a65cc79790d80dcafd175d577175698b0c091da992"
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
          checksum = "sha256:${var.boundary_checksum}"
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
