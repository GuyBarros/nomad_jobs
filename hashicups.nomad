variable "datacenters" {
  description = "A list of datacenters in the region which are eligible for task placement."
  type        = list(string)
  default     = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2","dc1"]
}

variable "region" {
  description = "The region where the job should be placed."
  type        = string
  default     = "global"
}

variable "product_api_version" {
  description = "Docker version tag"
  default = "v0.0.21"
}

variable "product_api_db_version" {
  description = "Docker version tag"
  default = "v0.0.20"
}

variable "postgres_db" {
  description = "Postgres DB name"
  default = "products"
}

variable "postgres_user" {
  description = "Postgres DB User"
  default = "postgres"
}

variable "postgres_password" {
  description = "Postgres DB Password"
  default = "password"
}

variable "product_api_port" {
  description = "Product API Port"
  default = 9090
}

# Begin Job Spec
job "hashicups" {
  type   = "service"
  region = var.region
  datacenters = var.datacenters

  group "hashicups" {
    network {
      port "db" { 
        static = 5432
      }
      port "product-api" {
        static = var.product_api_port
      }
    }

    task "db" {
      driver = "docker"
      meta {
        service = "database"
      }
      service {
        port     = "db"
        tags     = ["hashicups", "backend"]
        provider = "nomad"
        address  = attr.unique.platform.aws.public-ipv4
      }
      config {
        image   = "hashicorpdemoapp/product-api-db:${var.product_api_db_version}"
        ports = ["db"]
      }
      env {
        POSTGRES_DB       = "products"
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "password"
      }
    }

    task "product-api" {
      driver = "docker"
      meta {
        service = "product-api"
      }
      service {
        port         = "product-api"
        tags         = ["hashicups", "backend"]
        provider     = "nomad"
        address      = attr.unique.platform.aws.public-ipv4
      }
      config {
        image   = "hashicorpdemoapp/product-api:${var.product_api_version}"
        ports = ["product-api"]
      }
      template {
        data        = <<EOH
{{ range nomadService "hashicups-hashicups-db" }}
DB_CONNECTION="host={{ .Address }} port={{ .Port }} user=${var.postgres_user} password=${var.postgres_password} dbname=${var.postgres_db} sslmode=disable"
{{ end }}
EOH
        destination = "local/env.txt"
        env         = true
      }
      env {
        DB_CONNECTION = "host=${NOMAD_IP_db} port=${NOMAD_PORT_db} user=${var.postgres_user} password=${var.postgres_password} dbname=${var.postgres_db} sslmode=disable"
        BIND_ADDRESS = "0.0.0.0:${NOMAD_PORT_product-api}"
      }
    }
  }
}