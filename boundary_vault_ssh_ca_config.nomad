variable "vault_addr" {
 type = string
 default = "https://guylabstack-vault-public-vault-99c069c2.8c9edb4b.z1.hashicorp.cloud:8200"
 }

variable "vault_token" {
 type = string
 default = "hvs.CAESIJojyfgh7nRKePkk7azU4pm2jhBUkE-eUw6a8NjxpvtcGicKImh2cy5Sd2dlZ29FSGNkUzZ0aHdXa1YzUUJwYTcuZE1la0gQzRQ"
 }

variable "vault_namespace" {
 type = string
 default = "admin/guylabstack"
 }


job "boundary_vault_ssh_ca_config" {
 region = "global"
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2"]
  type = "batch"

  group "vault-config" {
  count = 3
    
    constraint {
      operator  = "distinct_hosts"
      value     = "true"
    }

 /*  
  vault {
    policies = ["superuser"]
    change_mode   = "restart"
    namespace = "${var.vault_namespace}"
  }
 */
  task "vault_ssh_ca_install" {
  
    driver = "raw_exec"

    template {
      data = <<TEMPLATEEOF
    set -v

export VAULT_ADDR=${var.vault_addr}
export VAULT_TOKEN=${var.vault_token}
export VAULT_NAMESPACE=${var.vault_namespace}

    # Add the public key to all target host's SSH configuration
    vault read -field=public_key ssh-client-signer/config/ca > /etc/ssh/trusted-user-ca-keys.pem

    # Setting up /etc/ssh/sshd_config
    grep -qxF 'TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem' /etc/ssh/sshd_config || sudo echo 'TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem' >> /etc/ssh/sshd_config


    # restarting SSHD
    sudo systemctl restart sshd

    # remove your authorised_keys, if any.
    if [ -f /home/ubuntu/.ssh/authorized_keys ]; then
    mv /home/ubuntu/.ssh/authorized_keys /home/ubuntu/.ssh/backup
    fi

    # Uncomment the line below if you run into issues
    # mv /home/ubuntu/.ssh/backup /home/ubuntu/.ssh/authorized_keys

    TEMPLATEEOF

      destination = "script.sh"
      perms = "755"
    }

    config {
      command = "bash"
      args    = ["script.sh"]
    }
 }

 } # Group
} #Job




