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
ibmcloud config --check-version=false

# jq
echo ">> jq"
yum install -y epel-release
yum install -y jq

# logdna
echo ">> log analysis agent"
# extracted from https://cloud.ibm.com/docs/log-analysis?topic=log-analysis-config_agent_rhel3
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
# extracted from https://ibm.biz/install-sysdig-agent
rpm --import https://download.sysdig.com/DRAIOS-GPG-KEY.public
curl -s -o /etc/yum.repos.d/draios.repo https://download.sysdig.com/stable/rpm/draios.repo
rpm --quiet -i https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -q -y install dkms
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
