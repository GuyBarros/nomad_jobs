job "jupyter" {
    region = "europe-west3"
  datacenters = ["primarystack"]


  group "jupyter-notebook" {
    count = 1

    task "scipy" {
         constraint {
        attribute = "${meta.type}"
        value     = "server"
      }
      driver = "docker"
      config {
        image = "jupyter/scipy-notebook"

        port_map {
          http = 8888
        }
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }
      resources {
        cpu = 1000
        memory = 1024
        network {
          mbits = 10
          port  "http"  {
            
          }
        }
      }
      service {
        name = "jupyter-scipy"
        tags = ["urlprefix-/jupyter-scipy strip=/jupyter-scipy"]
        port = "http"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

  }

  
  
  update {
    max_parallel = 1
    min_healthy_time = "5s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 0
  }
}
