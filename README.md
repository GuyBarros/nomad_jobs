# nomad_jobs
A collection of Nomad Jobds to run as part of the meanstack-consul-connect demo

These are tightly coupled with the nomad created in the repo `terraform-aws-demostack`

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

```bash
# read credentials
vault read database/creds/readonly
```

### Vault SSH OTP demo

Declare the following in your `runjobs.tf`, where `nomad_node` is your nomad node name for ssh.

``` javascript
data "template_file" "vault-ssh-helper" {
  template = "${file("./vault-ssh-helper.nomad.tpl")}"
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

``` bash
vault ssh -role otp_key_role -mode otp -strict-host-key-checking=no ubuntu@<nomad_node_ip/host>
```

### Vault SSH CA demo

Declare the following in your `runjobs.tf`, where `nomad_node` is your nomad node name for ssh.

``` javascript
data "template_file" "vault-ssh-ca" {
  template = "${file("./vault-ssh-ca.nomad.tpl")}"
  vars = {
    nomad_node = "ric-lnd-stack-server-1"
  }
}

resource "nomad_job" "vault-ssh-ca" {
  jobspec = "${data.template_file.vault-ssh-ca.rendered}"
}
```

This demo will already setup your Vault with the right backend and role.
To use it, make sure you have an existing ssh key pair (`ssh-keygen -t rsa -C "user@example.com`)
Then sign your key and save it to disk

``` bash
# to sign your key
vault write -field=signed_key ssh-client-signer/sign/my-role \
    public_key=@$HOME/.ssh/id_rsa.pub > signed-cert.pub

# (Optional) to verify your keygen
ssh-keygen -Lf  signed-cert.pub

# Then just sign in (replacing your server hostname)
ssh -i signed-cert.pub -i ~/.ssh/id_rsa ubuntu@<nomad_node_ip/hostname>
```

### LDAP demo

Declare the following in your `runjobs.tf`,

``` javascript
resource "nomad_job" "ldap-server" {
  jobspec = "${file("./ldap-server.nomad")}"
}
resource "nomad_job" "phpldapadmin" {
  jobspec = "${file("./phpldapadmin.nomad")}"
}
```

Optionally, you can login via `fabio` on `http://fabio.<demo stack namespace>.hashidemos.io:9999/phpldapadmin-server/` as `cn=admin,dc=example,dc=org` and import the `LDAPVAULT.LDIF` file (don't stop on errors)

Here's an example on how to configure vault for the control groups demo.

``` bash
vault auth enable ldap

vault write auth/ldap/config \
    url="ldap://ldap-service.service.consul" \
    binddn="cn=admin,dc=example,dc=org" \
    userattr="uid" \
    bindpass='admin' \
    userdn="ou=Users,dc=example,dc=org" \
    groupdn="ou=Groups,dc=example,dc=org" \
    insecure_tls=true

vault write identity/group name="approvers" \
      policies="superuser" \
      type="external"

vault read identity/group/name/approvers  -format=json | jq -r .data.id > approvers_group_id.txt
vault auth list -format=json  | jq -r '.["ldap/"].accessor' > accessor.txt

vault write identity/group-alias name="approvers" \
        mount_accessor=$(cat accessor.txt) \
        canonical_id=$(cat approvers_group_id.txt)


vault kv put kv/cgtest example=value
```

And here's how one would login
``` bash
vault login -method=ldap username='andre'
```
