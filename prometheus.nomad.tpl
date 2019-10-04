job "monitoring" {
  datacenters = ["eu-west-1","eu-west-2","eu-west-3","ukwest","sa-east-1","ap-northeast-1","dc1"]
    type = "service"
    group "prometheus-grafana" {
        count = 1
        ephemeral_disk {
            size = 300
        }

        vault {
            policies = ["superuser"]
        }

        restart {
            attempts = 0
            mode     = "fail"
         }

        # volume "prometheus_vol" {
        #     type = "host"

        #     config {
        #         source = "prometheus_mount"
        #     }
        # }

        task "prometheus" {

            template {
                change_mode = "noop"
                destination = "local/prometheus.yml"
                data = <<EOH
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
scrape_configs:
  - job_name: 'nomad_metrics'
    scheme: "https"
    tls_config:
        insecure_skip_verify: true
    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
      services: ['nomad-client', 'nomad']

    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex: '(.*)http(.*)'
      action: keep

    scrape_interval: 5s
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']

  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']

  - job_name: 'vault'
    metrics_path: "/v1/sys/metrics"
    scheme: "https"
    tls_config:
        insecure_skip_verify: true
    params:
      format: ['prometheus']
    bearer_token: {{ env "VAULT_TOKEN" }}
    static_configs:
    - targets: ['active.vault.service.consul:8200']
EOH
            }
            driver = "docker"
            # artifact {
            #     source = "https://raw.githubusercontent.com/GuyBarros/nomad_jobs/master/prometheus/prometheus.yml"
            #     destination = "/opt/prometheus/config"
            # }
            # docker run -p 9090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \prom/prometheus
            config {
                image = "prom/prometheus"
                network_mode = "host"
                args = [
                    "--web.external-url=${fabio_url}/prometheus",
                    "--web.route-prefix=/",
                    "--config.file=/etc/prometheus/prometheus.yml",
                    "--storage.tsdb.retention.size=150GB",
                #     # "--storage.tsdb.path=/opt/prometheus/data/"
                ]

                volumes = [
                    "local/prometheus.yml:/etc/prometheus/prometheus.yml"
                ]

                port_map {
                     prometheus = 9090
                }
            }

            logs {
                max_files     = 5
                max_file_size = 15
            }
            resources {
                cpu = 500
                memory = 512
                network {
                    mbits = 10
                    port  "prometheus"  {
                        static = 9090
                    }
                }
            }
            service {
                name = "prometheus"
                tags = ["urlprefix-/prometheus  strip=/prometheus"]
                port = "prometheus"
                check {
                    name     = "prometheus port alive"
                    type     = "http"
                    path     = "/-/healthy"
                    interval = "10s"
                    timeout  = "2s"
                }
            }
        }

        task "grafana" {
            driver = "docker"
            meta {
                FABIO_URL = "${fabio_srv}"
            }
            env {
                "GF_SERVER_DOMAIN"="${fabio_srv}"
                "GF_SERVER_ROOT_URL"="%(protocol)s://%(domain)s/grafana/"
            }
            config {
                image = "grafana/grafana"
                network_mode = "host"
                port_map {
                     http = 3000
                }
            }

            logs {
                max_files     = 5
                max_file_size = 15
            }
            resources {
                cpu = 500
                memory = 512
                network {
                    mbits = 10
                    port  "http"  {
                        static = 3000
                    }
                }

            }
            service {
                name = "grafana"
                tags = ["urlprefix-/grafana strip=/grafana"]
                port = "http"
                check {
                    type = "tcp"
                    interval = "10s"
                    timeout = "4s"
                }
            }
        }

   }
}
