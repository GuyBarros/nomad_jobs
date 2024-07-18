job "vaultupdater" {
  datacenters = ["dc1","eu-west-2"]
  type = "batch"

periodic {
    cron             = "* * * * *"
    prohibit_overlap = true
  }

  group "vaultEnityUpdater" {
    count = 1
    
     task "GroupEntityRenamer" {
      driver = "exec"
      vault {
  policies = ["superuser"]
}


      env {
        VAULT_ADDR = "https://active.vault.service.consul:8200"
      }

      artifact {
           source   = "git::https://github.com/andrefcpimentel2/vault_groups_python.git"
           destination = "local/repo/1/"
           
         }

      config {
        command = "local/repo/1/run.sh"
      }

      resources {
        network {
          port "proxy" {}
        }
      }
    } 

  }

}
