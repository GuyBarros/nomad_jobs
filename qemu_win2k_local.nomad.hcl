job "vm-from-iso" {
  datacenters = ["dc1"]
  type        = "service"

  group "vm-group" {
    count = 1

    network {
      # Map host port 3389 to the VM's RDP port (3389)
      port "rdp" {
        static = 3389
      }
    }

    # Pre-allocate an empty virtual disk file inside the local directory 
    # so the installer has a storage medium to install onto.
    task "create-disk" {
      driver = "raw_exec"

      config {
        command = "qemu-img"
        args    = ["create", "-f", "qcow2", "${NOMAD_ALLOC_DIR}/local/disk.qcow2", "20G"]
      }

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }
    }

    task "windows-vm" {
      driver = "qemu"

      # Download your ISO image into the allocation directory automatically
      artifact {
        source      = "/Users/guybarros/Downloads/Windows_2000_Professional.ISO"
        destination = "Windows_2000_Professional.ISO"
        mode        = "file"
      }

      config {
        # Point image_path to the empty disk created during prestart
        image_path        = "local/disk.qcow2"
        accelerator       = "kvm"
        machine_type      = "q35"
        graceful_shutdown = true

        # Custom arguments to mount the ISO and set boot order to CD-ROM (d)
        args = [
          "-cdrom", "local/Windows_2000_Professional.ISO",
          "-boot", "order=d",
          "-m", "2048"
        ]
      }

      resources {
        cpu    = 2000 # MHz
        memory = 2048 # MB
      }
    }
  }
}
