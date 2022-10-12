#### to run: nomad job run  -var="hcp_boundary_cluster_id=0fcfa413-3d03-4ba3-89f4-389be0a7e252" hcp-boundary-worker.nomad


variable "boundary_version" {
  type = string
  default = "0.11.0+hcp"
}

variable "boundary_checksum" {
  type = string
  default = "cde09452d5d129c56e03f4f495f87ab0586005b31aba53fd8501b8b02199d6c3"

}

variable "hcp_boundary_cluster_id" {
  type = string
  
}


job "boundary-worker" {
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
    task "boundary-worker.service" {
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

    hcp_boundary_cluster_id = "${var.hcp_boundary_cluster_id}"

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
     tls_disable = true
}
 


worker {
  auth_storage_path = "tmp/boundary.d/"
  # change this to the public ip address of the specific platform you are running or use "attr.unique.network.ip-address"
   public_addr = "{{ env "attr.unique.platform.aws.public-ipv4" }}"
     tags {
    type      = ["workers","hcp","demostack"]
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
        name = "hcp-boundary-worker"
        tags = ["hcp","boundary-worker","worker-${NOMAD_ALLOC_INDEX}"]
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
