
job "vault_ssh_ca" {
  region = "global"
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2"]
  type = "batch"

/*
  vault {
    policies = ["superuser"]
    change_mode   = "restart"
    namespace = "=admin/guystack"
  }
*/

  task "vault_ssh_ca_install" {
    
    driver = "raw_exec"

    template {
      data = <<EOH
set -v
export VAULT_ADDR=https://guylabstack-vault-public-vault-a78b392f.1ee20bcf.z1.hashicorp.cloud:8200
export VAULT_NAMESPACE=admin/guylabstack
export VAULT_TOKEN=

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

exit 0
EOH

      destination = "script.sh"
      perms = "755"
    }

    config {
      command = "bash"
      args    = ["script.sh"]
    }
  }

}




