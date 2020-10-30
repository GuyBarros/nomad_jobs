job "boundary-worker" {
 region = "global"
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c"]
  type = "service"

  group "boundary-worker" {
    count = 1
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
        network {
          mbits = 10
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
    purpose = "proxy"
    address = "{{ env  "attr.unique.network.ip-address" }}:9202"
    tls_disable = true
}

worker {
  name = "local-worker-{{ env "NOMAD_ALLOC_INDEX" }}"
  description = "Worker on {{ env "attr.unique.hostname" }}"
   public_addr = "{{ env "attr.unique.platform.aws.public-ipv4" }}"
   controllers = [
     {{ range service "boundary-server" }}
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
