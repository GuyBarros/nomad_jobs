# Configure the Nomad provider
provider "nomad" {
  address = data.terraform_remote_state.demostack.outputs.Primary_Nomad
}
locals {
  fabio  = "${data.terraform_remote_state.demostack.outputs.Primary_Fabio}"
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


resource "nomad_job" "consul-federation" {
  jobspec = "${file("./consul-federation.nomad")}"
}



# resource "nomad_job" "nomad-federation" {
#   jobspec = "${file("./nomad_federation.nomad")}"
# }

resource "nomad_job" "countapi" {
  jobspec = "${file("./countapi.nomad")}"
}

resource "nomad_job" "countdashboard" {
  jobspec = "${file("./countdashboard.nomad")}"
}

resource "nomad_job" "postgresSQL" {
  jobspec = "${file("./postgresSQL.nomad")}"
}
resource "nomad_job" "postgresSQL_admin" {
  jobspec = "${file("./pgadmin.nomad")}"
}

resource "nomad_job" "ldap-server" {
  jobspec = "${file("./ldap-server.nomad")}"
}
resource "nomad_job" "phpldapadmin" {
  jobspec = "${file("./phpldapadmin.nomad")}"
}
resource "nomad_job" "vaultupdater" {
  jobspec = "${file("./vaultupdater.nomad")}"
}

 data "template_file" "vault-ssh-helper" {
   template = "${file("./vault-ssh-helper.nomad.tpl")}"
   vars = {
     nomad_node = var.nomad_node
   }
 }
 resource "nomad_job" "vault-ssh-helper" {
   jobspec = "${data.template_file.vault-ssh-helper.rendered}"
 }


# data "template_file" "vault-ssh-ca" {
#   template = "${file("./vault-ssh-ca.nomad.tpl")}"
#   vars = {
#     nomad_node = "ric-lnd-stack-server-1"
#   }
# }
# resource "nomad_job" "vault-ssh-ca" {
#   jobspec = "${data.template_file.vault-ssh-ca.rendered}"
# }

### Monitoring Stack (may need to be applied twice)
data "template_file" "prometheus_monitoring" {
  template = "${file("./prometheus.nomad.tpl")}"
  vars = {
    fabio_url = "${local.fabio}"
    fabio_srv = substr(local.fabio, 7, length(local.fabio))
  }
}
resource "nomad_job" "prometheus_monitoring" {
  jobspec = "${data.template_file.prometheus_monitoring.rendered}"
}

provider "grafana" {
  url  = "${local.fabio}/grafana"
  auth = "admin:admin"
}
resource "grafana_data_source" "prometheus" {
  type          = "prometheus"
  name          = "prometheus"
  url           = "http://prometheus.service.consul:9090"
  is_default    = "true"
}
resource "grafana_dashboard" "Nomad" {
  config_json = "${file("./grafana/Nomad.json")}"
}
resource "grafana_dashboard" "Consul" {
  config_json = "${file("./grafana/Consul.json")}"
}
resource "grafana_dashboard" "Vault" {
  config_json = "${file("./grafana/Vault.json")}"
}

# resource "grafana_data_source" "influxdb" {
#   type          = "influxdb"
#   name          = "test_influxdb"
#   url           = "http://influxdb.example.net:8086/"
#   username      = "foo"
#   password      = "bar"
#   database_name = "mydb"
# }

