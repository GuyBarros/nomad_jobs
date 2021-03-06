job "boundary-worker" {
 region = "global"
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c"]
  type = "service"

  group "boundary-worker" {
    count = 1
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

     constraint {
        attribute = "${meta.type}"
        value     = "server"
      }

      resources {
        cpu = 2000
        memory = 1024

      }
      artifact {
         source     = "https://releases.hashicorp.com/boundary/0.2.1/boundary_0.2.1_linux_amd64.zip"
        # source      = "https://releases.hashicorp.com/boundary/0.1.1/boundary_0.1.1_${attr.kernel.name}_${attr.cpu.arch}.zip"
        destination = "./tmp/"
        options {
          checksum = "sha256:718ec76d17982606f1a8db8f5667f49ea498e7ce18990cccd669f3f65f0b58c4"
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

}
kms "transit" {
  purpose            = "worker-auth"
  address            = "https://vault.service.consul:8200"
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
