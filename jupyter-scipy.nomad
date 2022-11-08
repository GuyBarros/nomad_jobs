job "jupyter" {
    datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]

  group "jupyter-notebook" {
    count = 1
   network {
          port  "http"  {
            to = 8888
          }
        }
    task "scipy" {
       
      driver = "docker"
      config {
        image = "jupyter/scipy-notebook"
        ports = ["http"]
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }
      resources {
        cpu = 1000
        memory = 1024
      }
      
    }
    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }
   service {
        name = "jupyter-scipy"
        tags = ["urlprefix-/jupyter-scipy strip=/jupyter-scipy"]
        port = "http"

        check {
          name     = "alive"
          port = "http"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
     }
  }
}
