# GitLab CE — Nomad Job Specification (no host volumes)
# Note: data will not persist across task restarts without volumes.
#
# Written by Claude for a quick demo of running GitLab CE on Nomad. 
# For production use, you should add host volumes to persist data across task restarts, 
# and consider using a more robust database and Redis configuration.
# See the official GitLab documentation for more details: https://docs.gitlab.com/ee
#
# Override hostname at submission time:
#   nomad job run -var="gitlab_hostname=gitlab.mycompany.com" gitlab-ce.nomad

variable "gitlab_hostname" {
  type        = string
  default     = "gitlab.example.com"
  description = "Fully-qualified hostname for the GitLab CE instance"
}

job "gitlab-ce" {
  datacenters = ["dc1"]
  type        = "service"
  namespace   = "default"

  spread {
    attribute = "${node.unique.id}"
  }

  group "gitlab" {
    count = 1

    restart {
      attempts = 3
      interval = "5m"
      delay    = "25s"
      mode     = "fail"
    }

    update {
      max_parallel      = 1
      min_healthy_time  = "90s"
      healthy_deadline  = "10m"
      progress_deadline = "15m"
      auto_revert       = true
    }

    network {
      mode = "bridge"
      port "http"  {  to = 80   }
      port "https" {  to = 443  }
      port "ssh"   { to = 22   }
    }

    service {
      name     = "gitlab-ce"
      provider = "consul"
      port     = "http"
      tags     = ["gitlab", "scm", "traefik.enable=true"]

      check {
        name     = "gitlab-health"
        type     = "http"
        path     = "/-/health"
        interval = "30s"
        timeout  = "10s"

        check_restart {
          limit           = 3
          grace           = "300s"
          ignore_warnings = false
        }
      }
    }

    task "gitlab-ce" {
      driver = "docker"

      config {
        image    = "gitlab/gitlab-ce:latest"
        hostname = var.gitlab_hostname
        ports    = ["http", "https", "ssh"]
        shm_size = 256000000

        volumes = [
          "local/gitlab.rb:/etc/gitlab/gitlab.rb",
        ]
      }

      template {
        destination = "local/gitlab.rb"
        data        = <<-EOT
external_url 'https://{{ with nomadVar "nomad/jobs/gitlab-ce" }}{{ .gitlab_hostname }}{{ end }}'
gitlab_rails['gitlab_shell_ssh_port'] = 2222
gitlab_rails['time_zone'] = 'UTC'
puma['worker_processes'] = 2
sidekiq['concurrency'] = 10
prometheus_monitoring['enable'] = true
EOT
        change_mode = "restart"
      }

      resources {
        cpu    = 2000
        memory = 4096
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }
    }
  }
}