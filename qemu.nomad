job "qemu-test" {
    datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2"]

    
    task "test" {
        driver = "qemu"

        artifact {
            source      = "https://cloud-images.ubuntu.com/daily/server/jammy/20230329/jammy-server-cloudimg-amd64-disk-kvm.img"
            destination = "./tmp"
            #options {
            #    checksum = "md5:df6a4178aec9fbdc1d6d7e3634d1bc33"
            #}
        }

        config {
            image_path        = "./tmp/jammy-server-cloudimg-amd64-disk-kvm.img"
            # accelerator       = "none"
        }
}
}