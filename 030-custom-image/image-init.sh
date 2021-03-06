#!/bin/bash
# This script is used to pre-install software into the virtual server instance
# before it gets captured as an image

# IBM Cloud CLI
echo ">> ibmcloud"
curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

# IBM Cloud CLI plugins
echo ">> ibmcloud plugins"
ibmcloud_plugins=( \
  code-engine \
  cloud-databases \
  cloud-dns-services \
  cloud-functions \
  cloud-internet-services \
  cloud-object-storage \
  container-registry \
  container-service \
  vpc-infrastructure \
  key-protect \
  power-iaas \
  schematics \
  secrets-manager \
  tg \
  tke \
)
for plugin in "${ibmcloud_plugins[@]}"
do
  ibmcloud plugin install $plugin -f -r "IBM Cloud"
done
ibmcloud cf install --force
ibmcloud config --check-version=false

# jq
echo ">> jq"
yum install -y epel-release
yum install -y jq

# logdna
echo ">> log analysis agent"
rpm --import https://assets.logdna.com/logdna.gpg
echo "[logdna]
name=LogDNA packages
baseurl=https://assets.logdna.com/el6/
enabled=1
gpgcheck=1
gpgkey=https://assets.logdna.com/logdna.gpg" | tee /etc/yum.repos.d/logdna.repo

# install a specific version
yum install -y logdna-agent-3.3.3-1.x86_64

# sysdig
echo ">> sysdig"
rpm --import https://download.sysdig.com/DRAIOS-GPG-KEY.public
curl -s -o /etc/yum.repos.d/draios.repo http://download.sysdig.com/stable/rpm/draios.repo
yum -y install kernel-devel-$(uname -r)
yum -y install draios-agent

# tools
echo ">> tools"
yum install -y nano

# enable the boot service that performs instance specific configuration
echo ">> on-boot service"
ln -s /usr/local/on-boot/on-boot.service /etc/systemd/system/on-boot.service
systemctl daemon-reload
systemctl enable on-boot.service
