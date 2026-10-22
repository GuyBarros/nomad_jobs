job "ollama" {
   datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2"]
  type = "service"

  group "ollama" {
    count = 1

  network {
    port "ollama" {
        to = 11434
        static = 8080
    }
  }

  volume "ollama" {
      type            = "host"
      source          = "ollama"
      access_mode     = "single-node-writer"
      attachment_mode = "file-system"
    }

    task "ollama" {
      driver = "docker"

     config {
        image = "ollama/ollama"
        ports = ["ollama"]
      }
  
      resources {
        cpu    = 9100 
        memory = 15000 
        
      }

      service {
        name     = "ollama-backend"
        provider = "nomad"
        port = "ollama"
        
      }
    }

    task "download-granite3.3-model" {
      driver = "exec"
      lifecycle {
        hook = "poststart"
      }
      resources {
        cpu    = 100
        memory = 100
      }
      template {
        data        = <<EOH
{{ range nomadService "ollama-backend" }}
OLLAMA_BASE_URL="http://{{ .Address }}:{{ .Port }}"
{{ end }}
EOH
        destination = "local/env.txt"
        env         = true
      }
      config {
        command = "/bin/bash"
        args = [
          "-c",
          "curl -X POST ${OLLAMA_BASE_URL}/api/pull -d '{\"name\": \"granite3.3:2b\"}'"
        ]
      }
    }

  }
}