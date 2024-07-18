
variable "terraform_version" {
  type = string
  default = "1.5.7"
}

variable "terraform_checksum" {
  type = string
  default = "c0ed7bc32ee52ae255af9982c8c88a7a4c610485cf1d55feeb037eab75fa082c"

}

job "terraform-cli" {
 region = "global"
  datacenters = ["eu-west","eu-west-2b","eu-west-2c","eu-west-2","dc1"]
  type = "batch"

  group "terraform-worker" {
    count = 1

    task "terraform-ingress-worker.service" {
      driver = "raw_exec"


      artifact {
         source     = "https://releases.hashicorp.com/terraform/${var.terraform_version}/terraform_${var.terraform_version}_linux_amd64.zip"
        destination = "./tmp/"
        options {
          # checksum = "sha256:$${var.terraform_checksum}"
        }
      }
 
   ####################################################
      template {
        data        = <<EOF
        resource "random_pet" "example" {
  
        }

        output "example"{
          value = random_pet.example.id
        }

        EOF
        destination = "./tmp/example.tf"
      }
  ####################################################
      template {
        data        = <<EOF
        cd ./tmp/
        ./terraform init
        ./terraform apply -auto-approve
        EOF
        destination = "./tmp/run.sh"
      }
      config {
        command = "/usr/bin/bash"
        args = ["tmp/run.sh"]
      }
   
    }

  }

}
