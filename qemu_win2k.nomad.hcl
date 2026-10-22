job "qemu-test" {
    datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2"]

    
    task "test" {
        driver = "qemu"

        artifact {
            source      = "https://archive.org/download/win2kproiso/Windows%202000%20Professional.ISO"
            destination = "./tmp"
            #options {
            #    checksum = "md5:df6a4178aec9fbdc1d6d7e3634d1bc33"
            #}
        }

        config {
            image_path        = "./tmp/Windows 2000 Professional.ISO"
            # accelerator       = "none"
        }
}
}