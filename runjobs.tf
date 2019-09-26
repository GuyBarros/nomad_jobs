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
data "template_file" "vault-ssh-helper" {
  template = "${file("./vault-ssh-helper.nomad.tpl")}"
  vars = {
    nomad_node = "EU-guystack-worker-1"
  }
}

resource "nomad_job" "vault-ssh-helper" {
  jobspec = "${data.template_file.vault-ssh-helper.rendered}"
}


