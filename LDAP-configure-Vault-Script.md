# Control Groups Demo

## Configure LDAP
* login to: http://fabio.eu-guystack.hashidemos.io:9999/phpldapadmin-server/
* user: cn=admin,dc=example,dc=org
password: admin
* Go to import and import your LDIF file [LDAPVAULT.LDIF](LDAPVAULT.LDIF) (don't stop on errors)

## CONFIGURE VAULT

``` bash
vault auth enable ldap || true

vault write auth/ldap/config \
    url="ldap://ldap-service.service.consul" \
    binddn="cn=admin,dc=example,dc=org" \
    userattr="uid" \
    bindpass='admin' \
    userdn="ou=Users,dc=example,dc=org" \
    groupdn="ou=Groups,dc=example,dc=org" \
    insecure_tls=true

vault auth list -format=json  | jq -r '.["ldap/"].accessor' > accessor.txt

vault write identity/group name="approvers" \
      policies="superuser" \
      type="external"

vault read identity/group/name/approvers  -format=json | jq -r .data.id > approvers_group_id.txt

vault write identity/group-alias name="approvers" \
        mount_accessor=$(cat accessor.txt) \
        canonical_id=$(cat approvers_group_id.txt)


vault write identity/group name="requesters" \
      policies="test" \
      type="external"

vault read identity/group/name/requesters  -format=json | jq -r .data.id > requesters_group_id.txt

vault write identity/group-alias name="requesters" \
        mount_accessor=$(cat accessor.txt) \
        canonical_id=$(cat requesters_group_id.txt)

vault kv put kv/cgtest example=value
```

Next you can login with one user to request the token:
``` bash
vault login -method=ldap username='ricardo'
# ensure the correct identity_policies are applied. (or login again)
vault kv get kv/cgtest
Key                              Value
---                              -----
wrapping_token:                  s.5Sy20xsqnzXc13JosUk7p7su
wrapping_accessor:               SfKGXVXWuId9E1X67K9E8LhG
wrapping_token_ttl:              24h
wrapping_token_creation_time:    2019-09-18 10:58:46 +0000 UTC
wrapping_token_creation_path:    kv/data/cgtest
```

Login with the approver user and authorize the request

```bash
vault login -method=ldap username='andre'
# ensure the correct identity_policies are applied. (or login again)
# check status
vault write sys/control-group/request accessor=SfKGXVXWuId9E1X67K9E8LhG
# authorize
vault write sys/control-group/authorize accessor=SfKGXVXWuId9E1X67K9E8LhG

# check status again
vault write sys/control-group/request accessor=SfKGXVXWuId9E1X67K9E8LhG
```

Now unwrap the secret with the other user

```bash
vault login -method=ldap username='ricardo'

vault unwrap s.5Sy20xsqnzXc13JosUk7p7su
```