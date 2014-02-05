#!/bin/bash

CONF_FILE=/etc/xapi.d/plugins/ovs_neutron_plugin.ini

if [ ! -d /etc/xapi.d/plugins ]; then
        echo "Am I on a xenserver? I can't find the plugins directory!"
        exit 1
fi

# Make sure we have sqlalchemy-python
rpm -qa | grep python-sqlalchemy >/dev/null 2>&1
if [ $? -ne 0 ]; then
        echo "python-sqlalchemy not found"
    echo "Please enable the centos repositories and install python-sqlalchemy:"
    echo "yum --disablerepo=citrix --enablerepo=base,updates -y install python-sqlalchemy"
    exit 1
fi

cp ovs_neutron_agent.py /etc/xapi.d/plugins
cp ovs_neutron_plugin.ini /etc/xapi.d/plugins

xe network-list name-label="integration-bridge" | grep xapi >/dev/null 2>&1
if [ $? -ne 0 ]; then
        echo "No integration bridge found.  Creating."
        xe network-create name-label="integration-bridge"
fi

BR=$(xe network-list name-label="integration-bridge" | grep "bridge.*:" | awk '{print $4}')
CONF_BR=$(grep integration-bridge ${CONF_FILE} | cut -d= -f2)
if [ "X$BR" != "X$CONF_BR" ]; then
        echo "Integration bridge doesn't match configuration file; fixing."
        sed -i -e "s/^integration-bridge =.*$/integration-bridge = ${BR}/g" $CONF_FILE
fi

echo "Using integration bridge: $BR (make sure this is set in the nova configuration)"

echo "Make sure to edit: $CONF_FILE"
