job "cascading_bash_jobs" {
 region = "eu-west-2"
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c"]
   type = "batch"
 group "jobs" {
         count = 1
        
  task "Generate_keys" {
       constraint {
        attribute = "${meta.type}"
        value     = "server"
      }
       lifecycle {
        hook    = "prestart"
      }
      
    driver = "raw_exec"
  
   template {
      data = <<EOH
set -v

# Generate a 2048 bit RSA Key
openssl genrsa -out keypair.pem 2048

# Export the RSA Public Key to a File
openssl rsa -in keypair.pem -pubout -out publickey.crt

# Exports the Private Key
openssl rsa -in keypair.pem -out private_unencrypted.pem -outform PEM

# convert to PKCS#8
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in keypair.pem -out pkcs8.key
pwd

# copy files to a shared directory
cp keypair.pem /tmp/keypair.pem
cp publickey.crt /tmp/publickey.crt
cp private_unencrypted.pem /tmp/private_unencrypted.pem
cp pkcs8.key /tmp/pkcs8.key



EOH
      destination = "script.sh"
      perms = "755"
    }

    config {
      command = "bash"
      args    = ["script.sh"]
    }

  }

  task "Load_to_vault" {
       constraint {
        attribute = "${meta.type}"
        value     = "server"
      }
      /*
      volume_mount {
                volume      = "mongodb_vol"
                destination = "/data/db"
               }
               */
    driver = "raw_exec"
      vault {
  policies = ["superuser"]
}


      env {
        VAULT_ADDR = "https://active.vault.service.consul:8200"
      }

template {
      data = <<EOH
set -v

# view the previously generated files
cat /tmp/keypair.pem
cat /tmp/publickey.crt
cat /tmp/private_unencrypted.pem
cat /tmp/pkcs8.key

cd /tmp

vault kv put kv/nomad_keys keypairs=@keypair.pem
vault kv patch kv/nomad_keys publickey=@publickey.crt
vault kv patch kv/nomad_keys private_unencrypted=@private_unencrypted.pem
vault kv patch kv/nomad_keys pkcs8=@pkcs8.key

EOH
destination = "script.sh"
perms = "755"
    }

    config {
      command = "bash"
      args    = ["script.sh"]
    }
  }

  task "Third_Job" {
       constraint {
        attribute = "${meta.type}"
        value     = "server"
      }
      
    driver = "raw_exec"
template {
      data = <<EOH
set -v

# Generate a 2048 bit RSA Key
echo "get your nomad groove on"

EOH
destination = "script.sh"
perms = "755"
}
        config {
      command = "bash"
      args    = ["script.sh"]
    }
  }
 } #group
} #jobs