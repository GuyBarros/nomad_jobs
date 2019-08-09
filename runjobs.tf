# Configure the Nomad provider
provider "nomad" {
  address = data.terraform_remote_state.demostack.outputs.Primary_Nomad
}

// Workspace Data
data "terraform_remote_state" "demostack" {
  backend = "remote"

  config = {
    hostname     = "app.terraform.io"
    organization = var.TFE_ORGANIZATION
    workspaces = {
      name = var.DEMOSTACK_WORKSPACE
    }
  } //config
}


# Register a job
resource "nomad_job" "nginx-pki" {
  jobspec = "${file("./nginx-pki.nomad")}"
}

resource "nomad_job" "hashibo" {
  jobspec = "${file("./hashibo.nomad")}"
}




