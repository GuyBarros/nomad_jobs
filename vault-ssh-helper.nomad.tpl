# For full documentation and examples, see
# This file is for the Vault SSH OTP demo
# Currently this is restricted to work on a single node
# Use the below example on your terraform spec, without the doubling the '$'
# data "template_file" "vault-ssh-helper" {
#   template = "$${file("./vault-ssh-helper.nomad")}"
#   vars = {
#     nomad_node = "ric-lnd-stack-server-1"
#   }
# }
# resource "nomad_job" "vault-ssh-helper" {
#   jobspec = "$${data.template_file.vault-ssh-helper.rendered}"
# }

# ::: Vault setup :::
# vault secrets enable ssh
# vault write ssh/roles/otp_key_role key_type=otp default_user=ubuntu cidr_list=0.0.0.0/0
#
# vault ssh -role otp_key_role -mode otp -strict-host-key-checking=no ubuntu@<nomad_node_ip>
#
# Good luck !

job "vault_ssh_helper-${nomad_node}" {
 datacenters = ["eu-west-2","eu-west-1","ukwest","sa-east-1","ap-northeast-1","dc1","europe-west3-dc"]
  type = "batch"

  task "vault_ssh_helper_install" {
    constraint {
      attribute = "$${meta.name}"
      value     = "${nomad_node}"
    }
    driver = "raw_exec"

    template {
      data = <<EOH
set -v
if [ ! -f /usr/local/bin/vault-ssh-helper ]; then
  # Download the vault-ssh-helper
  wget https://releases.hashicorp.com/vault-ssh-helper/0.1.4/vault-ssh-helper_0.1.4_linux_amd64.zip

  # Unzip the vault-ssh-helper in /user/local/bin
  sudo unzip -q vault-ssh-helper_0.1.4_linux_amd64.zip -d /usr/local/bin
fi

# Make sure that vault-ssh-helper is executable
sudo chmod 0755 /usr/local/bin/vault-ssh-helper

# Set the usr and group of vault-ssh-helper to root
sudo chown root:root /usr/local/bin/vault-ssh-helper

# Configuring the agent
sudo mkdir -p /etc/vault-ssh-helper.d/

openssl s_client -showcerts -connect vault.service.consul:8200 </dev/null 2>/dev/null|openssl x509 -outform PEM > /etc/vault-ssh-helper.d/vault.crt

cat << EOF > /etc/vault-ssh-helper.d/config.hcl
vault_addr = "https://vault.service.consul:8200"
ssh_mount_point = "ssh"
ca_cert = "/etc/vault-ssh-helper.d/vault.crt"
tls_skip_verify = true
allowed_roles = "*"
allowed_cidr_list = "0.0.0.0/0"
EOF

# Configuring PAM
sudo sed -i "/^@include common-auth/c\#@include common-auth" /etc/pam.d/sshd
grep -qxF 'auth requisite pam_exec.so quiet expose_authtok log=/tmp/vaultssh.log /usr/local/bin/vault-ssh-helper -config=/etc/vault-ssh-helper.d/config.hcl' /etc/pam.d/sshd || sudo echo 'auth requisite pam_exec.so quiet expose_authtok log=/tmp/vaultssh.log /usr/local/bin/vault-ssh-helper -config=/etc/vault-ssh-helper.d/config.hcl' >> /etc/pam.d/sshd
grep -qxF 'auth optional pam_unix.so not_set_pass use_first_pass nodelay' /etc/pam.d/sshd || sudo echo 'auth optional pam_unix.so not_set_pass use_first_pass nodelay' >> /etc/pam.d/sshd

# Configuring SSHD
sudo sed -i "/^ChallengeResponseAuthentication no/c\ChallengeResponseAuthentication yes" /etc/ssh/sshd_config
sudo sed -i "/^UsePAM no/c\UsePAM yes" /etc/ssh/sshd_config
sudo sed -i "/^PasswordAuthentication yes/c\PasswordAuthentication no" /etc/ssh/sshd_config

# restarting SSHD
sudo systemctl restart sshd

# remove your authorised_keys, if any.
if [ -f /home/ubuntu/.ssh/authorized_keys ]; then
  mv /home/ubuntu/.ssh/authorized_keys /home/ubuntu/.ssh/backup
fi

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




