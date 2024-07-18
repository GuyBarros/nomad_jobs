job "minecraft" {
  datacenters = ["EU-guystack"]
  group "minecraft" {
    volume "minecraft" {
      type   = "host"
      source = "minecraft"
    }
    task "eula" {
      driver = "exec"
      config {
        command = "mv"
        args    = ["local/eula.txt", "/var/volume/"]
      }
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }
      template {
        data        = "eula=true"
        destination = "local/eula.txt"
      }
      volume_mount {
        volume      = "minecraft"
        destination = "/var/volume"
      }
    }
    task "minecraft" {
      driver = "exec"
      config {
        command = "/bin/sh"
        args    = ["-c", "cd /var/volume && exec java -Xms1024M -Xmx2048M -jar /local/server.jar --nogui"]
      }
      artifact {
        source = "https://launcher.mojang.com/v1/objects/bb2b6b1aefcd70dfd1892149ac3a215f6c636b07/server.jar"
      }
      resources {
        cpu    = 4000
        memory = 2048
      }
      volume_mount {
        volume      = "minecraft"
        destination = "/var/volume"
      }
    }
  }
}
