job "LDAP" {
  datacenters = ["eu-west-2","eu-west-1","ukwest","sa-east-1","ap-northeast-1","dc1"]
  type = "service"

  group "openldap" {
    count = 1
    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    task "ldap-service" {
      driver = "docker"
      config {
        image = "osixia/openldap"
        network_mode = "host"
        port_map {
          LDAP = 389
        }

        volumes = [
          "local:/container/service/slapd/assets/config/bootstrap/ldif/custom"
        ]

      }
      env {
        LDAP_TLS = "false"
        LDAP_REMOVE_CONFIG_AFTER_SETUP = "false"
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }

      resources {
        cpu = 1000
        memory = 1024
        network {
          mbits = 10
          port  "LDAP"  {
            static = 389
          }
        }
      }
      service {
        name = "ldap-service"
        tags = ["urlprefix-/ldap-service strip=/ldap-service"]
        port = "LDAP"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
      template {
        change_mode = "noop"
        perms = "755"
        destination = "local/bootstrapp.ldif"
        data = <<EOH
# Entry 3: ou=Groups,dc=example,dc=org
dn: ou=Groups,dc=example,dc=org
objectclass: organizationalUnit
objectclass: top
ou: Groups

# Entry 4: cn=approvers,ou=Groups,dc=example,dc=org
dn: cn=approvers,ou=Groups,dc=example,dc=org
cn: approvers
gidnumber: 501
memberuid: andre
objectclass: posixGroup
objectclass: top

# Entry 5: cn=requesters,ou=Groups,dc=example,dc=org
dn: cn=requesters,ou=Groups,dc=example,dc=org
cn: requesters
gidnumber: 500
memberuid: ricardo
objectclass: posixGroup
objectclass: top

# Entry 6: ou=Users,dc=example,dc=org
dn: ou=Users,dc=example,dc=org
objectclass: organizationalUnit
objectclass: top
ou: Users

# Entry 7: cn=Andre Pimentel,ou=Users,dc=example,dc=org
dn: cn=Andre Pimentel,ou=Users,dc=example,dc=org
cn: Andre Pimentel
displayname: @Andre
gidnumber: 501
givenname: Andre
homedirectory: /home/users/andre
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
sn: Andre
uid: andre
uidnumber: 1001
userpassword: password

# Entry 8: cn=Ricardo Oliveira,ou=Users,dc=example,dc=org
dn: cn=Ricardo Oliveira,ou=Users,dc=example,dc=org
cn: Ricardo Oliveira
displayname: @Ricardo
gidnumber: 500
givenname: Ricardo
homedirectory: /home/users/ricardo
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
sn: Ricardo
uid: ricardo
uidnumber: 1000
userpassword: password

EOH
      }
    }
  }

  update {
    max_parallel = 1
    min_healthy_time = "5s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 0
  }
}
