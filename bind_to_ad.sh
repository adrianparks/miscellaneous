#!/bin/bash
#
# Bind this computer to the specified AD. This will allow login to the computer
# from members of the AD group defined in ALLOWED_AD_GROUP, provided they
# have that group set as their primary group in AD. Home directories are
# automatically created courtesy of oddjobd
#
# Note that this needs to be a CentOS 7 or RHEL7 box to work
# Might work on CentOS 6 but not tested
#
# Note that AD user must be in an AD group with privileges to bind computer
# accounts to the domain and this group must be defined as the user's
# Primary Group in AD, for them to be able to log in. If their primary
# group is "Domain Users" it won't work.

REALM="AD_Domain"
BINDUSER="AD_Bind_User"
ALLOWED_AD_GROUP="AD_Security_Group"

# change this to the OU, you don't need the domain CN= part
COMPUTER_OU="OU=Computers,OU=Department" 

NETBIOSNAME=$(hostname -s)
OSNAME=$(awk {'print $1'} < /etc/redhat-release)
OSVER=$(awk {'print $4'} < /etc/redhat-release)

# Other things like oddjob will also come in as a dependency
yum install -y realmd sssd samba-common-tools adcli krb5-workstation openldap-clients policycoreutils-python

# if it worked OK the AD domain should be discoverable via DNS SRV records
# (at least in Oxford)
realm discover $REALM

if [ $? -eq 0 ]
then

    # this binds the client to the AD domain and creates an AD object for it

    realm -v join --automatic-id-mapping=no \
               --computer-ou=COMPUTER_OU \
               --computer-name=$NETBIOSNAME \
               --os-name=$OSNAME \
               --os-version=$OSVER \
               --user=$BINDUSER \
               $REALM

    # by default any domain member can log in, restrict just to members of this group
    realm permit -g $ALLOWED_AD_GROUP

    # update sssd.conf to change to the following two lines:
    # use_fully_qualified_names = False
    # fallback_homedir = /home/%u

    sed -i -e 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' \
        -e 's/fallback_homedir = \/home\/%u@%d/fallback_homedir = \/home\/%u/g' \
        -e 's/ldap_id_mapping = False/ldap_id_mapping = True/g' \
        /etc/sssd/sssd.conf

    systemctl restart sssd

    echo "Testing with command <id>..."
    id $BINDUSER

    if [ $? -ne 0 ]
    then
        echo "id command did not work"
        exit 1
    else
        echo "All seems OK"
    fi

else
    echo "Could not discover realm $REALM"
    exit 1
fi

