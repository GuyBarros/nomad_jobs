variable "front_version" {
  type = string
  default = "v0.26.2"
}

job "front-service" {

  group "frontend" {
    network {
      mode = "bridge"
      port "http" {
        to = 9090
      }
    }
    service {
      name = "front-service"
      tags = ["web","frontend"]
      port = 9090
      # # For TProxy and Consul Connect we need to use the port and address of the Allocation
      # address_mode = "alloc"
    
      connect {
        sidecar_service {
          proxy {
            transparent_proxy {}
          } 
        }
      }
    }

    task "web" {
      driver = "docker"

      config {
        image          = "nicholasjackson/fake-service:${var.front_version}"
        ports          = ["http"]
      }

      # identity {
      #   env  = true
      #   file = true
      # }

      # resources {
      #   cpu    = 500
      #   memory = 256
      # }
      env {
        PORT = "9090"
        LISTEN_ADDR = "0.0.0.0:9090"
        MESSAGE = "Hello World fron Frontend V1"
        NAME = "web"
       # UPSTREAM_URIS = "http://public-api.virtual.consul:9090,http://private-api.virtual.consul:9090"
      }
    }
  }
}