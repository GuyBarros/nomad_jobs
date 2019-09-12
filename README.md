# nomad_jobs
A collection of Nomad Jobds to run as part of the meanstack-consul-connect demo

***These should NOT be used as examples of a production deployment.***

## List demos
### PortgreSQL dynamic credentials
Declare the following in your `runjobs.tf`
``` javascript
resource "nomad_job" "postgresSQL" {
  jobspec = "${file("./postgresSQL.nomad")}"
}

resource "nomad_job" "pgadmin" {
  jobspec = "${file("./pgadmin.nomad")}"
}
```
This first script will deploy the PostgreSQL database, whilst the second one will deploy the PGAdmin tool.

Once you open the _pgadmin_ tool, you can configure it to access your database with:
* postgres.service.consul:5432
* username="root"
* password="rootpassword"
* disable SSL
* database = postgres

Setup your vault
```bash
vault secrets enable database
vault write database/config/postgresql  plugin_name=postgresql-database-plugin connection_url="postgresql://{{username}}:{{password}}@postgres.service.consul:5432/postgres?sslmode=disable" allowed_roles="*" username="root" password="rootpassword"
vault write database/roles/readonly db_name=postgresql creation_statements=@readonly.sql default_ttl=1h max_ttl=24h
```

You can find the `readonly.sql` file in this repo.

### Vault SSH OTP demo

Declare the following in your `runjobs.tf`, where `nomad_node` is your nomad node name for ssh.

``` javascript
data "template_file" "vault-ssh-helper" {
  template = "${file("./vault-ssh-helper.nomad")}"
  vars = {
    nomad_node = "ric-lnd-stack-server-1"
  }
}

resource "nomad_job" "vault-ssh-helper" {
  jobspec = "${data.template_file.vault-ssh-helper.rendered}"
}
```

Afterwards, setup vault
```bash
vault secrets enable ssh
vault write ssh/roles/otp_key_role key_type=otp default_user=ubuntu cidr_list=0.0.0.0/0
```

And from your client machine you'll be able to accessthe node:
```
vault ssh -role otp_key_role -mode otp -strict-host-key-checking=no ubuntu@<nomad_node_ip>```