#! /bin/bash

GET_PWD="$(pwd)"
WOR_ANSIBLE="/etc/ansible"

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

sleep 50
echo -e "\033[1;34m========================================================================"
echo -e "\033[1;34mCreate ansible folder and create ansible.cfg file"
echo -e "\033[1;34m========================================================================"

sudo mkdir /etc/ansible
sudo touch /etc/ansible/ansible.cfg
echo "[defaults]
host_key_checking=False
pipelining=True
forks=100" | sudo tee /etc/ansible/ansible.cfg > /dev/null


if [ -d "$WOR_ANSIBLE" ]; then
  ### Take action if $DIR exists ###
  FILE=/etc/ansible/ansible.cfg
  if [ -f "$FILE" ]; then
    echo -e "\033[1;33m$FILE exists."
    echo "[defaults]
host_key_checking=False
pipelining=True
forks=100" | sudo tee /etc/ansible/ansible.cfg > /dev/null
  else 
    #echo "$FILE does not exist."
    sudo touch /etc/ansible/ansible.cfg
    echo "[defaults]
host_key_checking=False
pipelining=True
forks=100" | sudo tee /etc/ansible/ansible.cfg > /dev/null
  fi
else
  ###  Control will jump here if $DIR does NOT exists ###
  echo "Create folder /etc/ansible"
  sudo mkdir /etc/ansible
  sudo touch /etc/ansible/ansible.cfg
  echo "[defaults]
host_key_checking=False
pipelining=True
forks=100" | sudo tee /etc/ansible/ansible.cfg > /dev/null
  exit 1
fi


sleep 50
echo -e "\033[1;34m========================================================================"
echo -e "\033[1;34mRunning command kolla-genpwd"
echo -e "\033[1;34m========================================================================"
kolla-genpwd

sleep 50
echo -e "\033[1;34m========================================================================"
echo -e "\033[1;34mConfig globals.yml file in /etc/kolla"
echo -e "\033[1;34m========================================================================"
cat $GET_PWD/sglobals.conf | sudo tee -a /etc/kolla/globals.yml > /dev/null

sleep 50
echo -e "\033[1;34m========================================================================"
echo -e "\033[1;34m======== Bootstrap-servers ======== Prechecks ========= Deploy ========="
echo -e "\033[1;34m========================================================================"
cd /etc/kolla
kolla-ansible -i ./all-in-one bootstrap-servers &
wait
kolla-ansible -i ./all-in-one prechecks &
wait
kolla-ansible -i ./all-in-one deploy &
wait

sleep 50
echo -e "\033[1;34m========================================================================"
echo -e "\033[1;34mDownload Openstack"
echo -e "\033[1;34m========================================================================"
pip3 install python-openstackclient -c https://releases.openstack.org/constraints/upper/master

echo -e "\033[1;34m========================================================================"
echo -e "\033[1;34mDeploy Openstack"
echo -e "\033[1;34m========================================================================"
kolla-ansible post-deploy

cat /etc/kolla/admin-openrc.sh