# For full documentation and examples, see https://www.vaultproject.io/docs/secrets/ssh/signed-ssh-certificates.html
# This file is for the Vault SSH CA demo
# Please see the README.md for more information
#
# Good luck !

job "vault_ssh_ca-${nomad_node}" {
  datacenters = ["eu-west-2","eu-west-1","ukwest","sa-east-1","ap-northeast-1","dc1","europe-west3-dc"]
  type = "batch"
  vault {
    policies = ["superuser"]
    change_mode   = "restart"
  }

  task "vault_ssh_ca_install" {
    constraint {
      attribute = "$${meta.name}"
      value     = "${nomad_node}"
    }
    driver = "raw_exec"

    template {
      data = <<EOH
set -v
export VAULT_ADDR=https://vault.service.consul:8200

# Mounts the secrets engine
vault secrets enable -path=ssh-client-signer ssh || true

# Configure Vault with a CA for signing client keys using the /config/ca endpoint.
vault write ssh-client-signer/config/ca generate_signing_key=true || true

# Add the public key to all target host's SSH configuration
vault read -field=public_key ssh-client-signer/config/ca > /etc/ssh/trusted-user-ca-keys.pem

# Setting up /etc/ssh/sshd_config
grep -qxF 'TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem' /etc/ssh/sshd_config || sudo echo 'TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem' >> /etc/ssh/sshd_config

vault write ssh-client-signer/roles/my-role - << EOF
{
  "allow_user_certificates": true,
  "allowed_users": "*",
  "default_extensions": [
    {
      "permit-pty": ""
    }
  ],
  "key_type": "ca",
  "default_user": "ubuntu",
  "ttl": "30m0s"
}
EOF

# restarting SSHD
sudo systemctl restart sshd

# remove your authorised_keys, if any.
if [ -f /home/ubuntu/.ssh/authorized_keys ]; then
  mv /home/ubuntu/.ssh/authorized_keys /home/ubuntu/.ssh/backup
fi

# Uncomment the line below if you run into issues
# mv /home/ubuntu/.ssh/backup /home/ubuntu/.ssh/authorized_keys

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




