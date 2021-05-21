job "vault.service" {
  datacenters = ["dc1"]
  type = "service"
  group "vault" {
    count = 1
    task "vault.service" {
      driver = "exec"
      resources {
        cpu = 2000
        memory = 1024
      }
      artifact {
        source      = "https://releases.hashicorp.com/vault/1.5.5/vault_1.5.5_${attr.kernel.name}_${attr.cpu.arch}.zip"
        destination = "/tmp/"
        options {
          checksum = "sha256:2a6958e6c8d6566d8d529fe5ef9378534903305d0f00744d526232d1c860e1ed"
        }
      }
      template {
        data        = <<EOF
        ui = true
        storage "file" {
          path = "/opt/vault/data"
        }
        listener "tcp" {
          address = ":8200"
          tls_disable = 1
        }
        EOF
        destination = "/etc/vault.d/vault.hcl"
      }
      config {
        command = "/tmp/vault"
        args = ["server", "config=/etc/vault.d/vault.hcl"]
      }
    }
  }
}
