job "linux-vm-arm64" {
  type = "service"

  # Only the Graviton .metal workers expose /dev/kvm
  constraint {
    attribute = "${attr.platform.aws.instance-type}"
    operator  = "regexp"
    value     = "\\.metal"
  }

  group "vm" {
    network {
      port "ssh" {} # dynamic host port, forwarded to guest :22 via -netdev below
    }

    service {
      name     = "linux-vm-arm64-ssh"
      port     = "ssh"
      provider = "consul"

      check {
        type     = "tcp"
        interval = "15s"
        timeout  = "3s"
      }
    }

    task "cirros" {
      driver = "qemu"

      artifact {
        source      = "https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-aarch64-disk.img"
        destination = "local/disk.img"
        mode        = "file"
      }

      config {
        image_path      = "local/disk.img"
        emulator        = "aarch64"
        machine_type    = "virt"
        accelerator     = "kvm"
        drive_interface = "virtio"
        args = [
          "-machine", "gic-version=host", # Graviton has GICv3 only; QEMU defaults to v2
          "-cpu", "host",
          "-smp", "2",
          "-m", "512M", # guest RAM; leave headroom under resources.memory for QEMU overhead
          "-bios", "/usr/share/qemu-efi-aarch64/QEMU_EFI.fd",
          # The driver's port_map only reads task-level network resources, so
          # forward the group's "ssh" port to guest :22 ourselves.
          "-netdev", "user,id=net0,hostfwd=tcp::${NOMAD_PORT_ssh}-:22",
          "-device", "virtio-net-pci,netdev=net0",
        ]
      }

      resources {
        cpu    = 2000
        memory = 1024
      }
    }
  }
}