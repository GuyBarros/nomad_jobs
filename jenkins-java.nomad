job "jenkins" {
  type = "service"
   datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1"]
    update {
      stagger      = "30s"
        max_parallel = 1
    }
#  constraint {
#    attribute = "${driver.java.version}"
#    operator  = ">"
#    value     = "1.7.0"
#  }
  group "web" {
    count = 1
      # Size of the ephemeral storage for Jenkins. Consider that depending
      # on job count and size it could require larger storage.
      ephemeral_disk {
       migrate = true
       size    = "500"
       sticky  = true
       
     }
    task "frontend" {
      env {
        # Use ephemeral storage for Jenkins data.
        JENKINS_HOME = "/alloc/data"
        JENKINS_SLAVE_AGENT_PORT = "${NOMAD_PORT_slave}"
      }
      driver = "java"
      config {
        jar_path    = "local/jenkins.war"
        jvm_options = ["-Xmx768m", "-Xms384m"]
        args        = ["--httpPort=${NOMAD_PORT_http}"]
      }
      artifact {
        source = "http://ftp-chi.osuosl.org/pub/jenkins/war-stable/2.89.1/jenkins.war"

        options {
          # Checksum will change depending on the Jenkins Version.
          checksum = "sha256:f9f363959042fce1615ada81ae812e08d79075218c398ed28e68e1302c4b272f"
        }
      }
      service {
        # This tells Consul to monitor the service on the port
        # labeled "http".
        port = "http"
        name = "jenkins"

        check {
          type     = "http"
          path     = "/login"
          interval = "10s"
          timeout  = "2s"
        }
    }

      resources {
          cpu    = 2400 # MHz
          memory = 1024 # MB
          network {
            mbits = 100
            port "http" {
                
            }
            port "slave" {
              
            }
          }
        }
      }
    }
}