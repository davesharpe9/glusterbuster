#!/bin/bash
set -o errexit

unset AWS_SECURITY_TOKEN

function usage {
  cat << _EOF_
  Usage $0
_EOF_
}

if [[ -f params.conf ]]
then
  . params.conf
  export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION
else
  echo "you need an existing params.conf file to load the AWS keys from"
fi

if [[ -z "${AWS_ACCESS_KEY_ID}" && -z "${AWS_SECRET_ACCESS_KEY}" ]]
then
  echo "please make sure you have a params.conf with your aws keys in it"
  exit 1
fi

# where is this script?
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# bring up the candidate, but don't provision
vagrant up --provider aws candidate
vagrant up --provider aws proxy

candinst=$(aws ec2 describe-instances --filters Name=tag-value,Values=${MYUID}-candidate Name=instance-state-name,Values=running | grep ^INSTANCES | awk '{print $8}')

# setup ssh config
rm -rf ${DIR}/.tmp
mkdir -p ${DIR}/.tmp
vagrant ssh-config candidate > ${DIR}/.tmp/vagrant-ssh
vagrant ssh-config proxy >> ${DIR}/.tmp/vagrant-ssh

# remove evidence of vagrant
ssh -F ${DIR}/.tmp/vagrant-ssh candidate 'sudo rm -rf /vagrant'
ssh -F ${DIR}/.tmp/vagrant-ssh candidate 'sudo rm -rf /tmp/vagrant*'

# get proxy ip and set it up on candidate for apt- updates
proxyip=$(aws ec2 describe-instances --filters Name=tag-value,Values=${MYUID}-proxy Name=instance-state-name,Values=running | grep ^PRIVATEIPADDRESSES | awk '{print $NF}')
candip=$(aws ec2 describe-instances --filters Name=tag-value,Values=${MYUID}-candidate Name=instance-state-name,Values=running | grep ^PRIVATEIPADDRESS | awk '{print $NF}')
ssh -F ${DIR}/.tmp/vagrant-ssh candidate "echo 'Acquire::http { Proxy \"http://${proxyip}:3128\"; };'  | sudo tee /etc/apt/apt.conf.d/00proxy"

aws ec2 modify-instance-attribute --instance-id ${candinst} --groups ${SGSTRICT}

# start an ELB
aws elb create-load-balancer --subnets ${SUBNET} --listeners Protocol=http,LoadBalancerPort=80,InstanceProtocol=http,InstancePort=80 --load-balancer-name ${MYUID} --security-groups ${SGMISC} ${SGWWW}
aws elb register-instances-with-load-balancer --load-balancer-name ${MYUID} --instances ${candinst}
aws elb configure-health-check --load-balancer-name ${MYUID} --health-check Target=TCP:80,Interval=5,Timeout=2,UnhealthyThreshold=10,HealthyThreshold=2
aws elb create-load-balancer-listeners --load-balancer-name ${MYUID} --listeners Protocol=tcp,LoadBalancerPort=443,InstanceProtocol=tcp,InstancePort=443


# start mitmproxy shell script
ssh -F ${DIR}/.tmp/vagrant-ssh proxy "screen -d -m /vagrant/source/runssh.sh ${candip}"

echo "Copy and paste this to the candidate:"
echo
echo -n "ELB: "
aws elb describe-load-balancers --load-balancer-names ${MYUID} | awk '/^LOADBALANCERDESCRIPTIONS/ {print $2}'
echo
echo -n "Access IP: "
aws ec2 describe-instances --filters Name=tag-value,Values=${MYUID}-proxy Name=instance-state-name,Values=running | awk '/^ASSOCIATION/ {print $NF}' | head -1
