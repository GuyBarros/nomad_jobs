job "monitoring" {
  datacenters = ["eu-west-1","eu-west-2","eu-west-3","ukwest","sa-east-1","ap-northeast-1","dc1"]
   type = "service"
    group "prometheus-grafana" {
        count = 1

        restart {
            attempts = 0
            mode     = "fail"
         }

            volume "prometheus_vol" {
                type = "host"

                config {
                    source = "prometheus_mount"
                }
            }

        task "prometheus" {
            driver = "docker"
            env { }
            artifact {
                source = "https://raw.githubusercontent.com/GuyBarros/nomad_jobs/master/prometheus/prometheus.yml"
                destination = "/tmp/prometheus.yml"
            }
            volume_mount {
                volume      = "prometheus_vol"
                destination = "/prometheus-data/"
            }
            # docker run -p 9090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \prom/prometheus
            config {
                image = "prom/prometheus"
                network_mode = "host"
                args = [
                    "--config.file=/etc/prometheus/prometheus.yml",
                    "--storage.tsdb.retention.size=150GB",
                ]

                volumes = [
                     "/tmp/prometheus.yml:/etc/prometheus/prometheus.yml"
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
                tags = ["urlprefix-/prometheus strip=/prometheus"]
                port = "prometheus"
                check {
                    type = "tcp"
                    interval = "10s"
                    timeout = "4s"
                }
            }
        }



    task "grafana" {
            driver = "docker"
            env {

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