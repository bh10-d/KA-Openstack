#! /bin/bash

sudo apt update

sudo apt install git python3-dev libffi-dev gcc libssl-dev -y

sudo apt install python3-pip -y

sudo pip3 install -U pip

sudo pip3 install 'ansible-core>=2.16,<2.17.99'

sudo ln -s /usr/local/bin/ansible /usr/bin/ansible

sudo pip3 install git+https://opendev.org/openstack/kolla-ansible@master

sudo mkdir -p /etc/kolla

sudo chown $USER:$USER /etc/kolla

sudo cp -r /usr/local/share/kolla-ansible/etc_examples/kolla/* /etc/kolla

sudo cp /usr/local/share/kolla-ansible/ansible/inventory/* /etc/kolla/

kolla-ansible install-deps

sudo mkdir /etc/ansible

sudo touch /etc/ansible/ansible.cfg

echo "
[defaults]
host_key_checking=False
pipelining=True
forks=100" | sudo tee /etc/ansible/ansible.cfg > /dev/null

kolla-genpwd

cat sglobals.conf | sudo tee /etc/kolla/globals.yml >> /dev/null
cd /etc/kolla
kolla-ansible -i ./all-in-one bootstrap-servers &
wait
kolla-ansible -i ./all-in-one prechecks &
wait
kolla-ansible -i ./all-in-one deploy &
wait

pip3 install python-openstackclient -c https://releases.openstack.org/constraints/upper/master

kolla-ansible post-deploy

cat /etc/kolla/admin-openrc.sh