job "open-webui" {
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2"]
  type       = "service"

  group "open-webui" {
    
    count = 1
    vault {
      policies = ["superuser"]
      # namespace = "admin"
      env = false
    }
    network {
      port "open-webui" {
        to     = 8080
        static = 80
      }
    }

    task "open-webui" {
      driver = "docker"
      config {
          image = "ghcr.io/open-webui/open-webui:main"
          ports = ["open-webui"]
        }
      resources {
          cpu    = 4000
          memory = 3500
        }

      service {
        name = "openwebui"
        port = "open-webui"
        tags = [
          "global",
          "urlprefix-/openwebui"
          ]
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }

      }

      template {
        data        = <<EOH
          OLLAMA_BASE_URL={{ range nomadService "ollama-backend" }}http://{{ .Address }}:{{ .Port }}{{ end }}
          ENV="dev"
          DEFAULT_MODELS="granite-3.3"
          OFFLINE_MODE="True"
          ENABLE_SIGNUP="True"
          ENABLE_OPENAI_API="False"
          STORAGE_PROVIDER="gcs"
          {{ with secret "gcp/static-account/openwebui/key"}}
          GOOGLE_APPLICATION_CREDENTIALS_JSON={{ base64Decode .Data.private_key_data  | toJSON }}
          GCS_BUCKET_NAME="andre17-openwebui"
          {{ end }}
          DATABASE_TYPE="sqlite+sqlcipher"
          {{- with secret "secret/data/openwebui" -}}
          DATABASE_PASSWORD="{{.Data.data.password}}"
          {{- end }}
          EOH
        destination = "local/env.txt"
        env         = true
      }
      
    }

  }

  }