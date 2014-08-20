#!/bin/bash
set -o errexit

# setup some defaults
AWS_DEFAULT_REGION='ap-southeast-2'
AMI='ami-43128a79'
INSTANCE_TYPE='m3.medium'

unset AWS_SECURITY_TOKEN

function usage {
  cat << _EOF_
  Usage $0 -s aws_ssh_key_name -p path_to_ssh_key -i a_unique_short_string -r region -n subnet_id
_EOF_
}

if [[ -f params.conf ]]
then
  . params.conf
  export AWS_DEFAULT_REGION AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
else
  echo "you need an existing params.conf file to load the AWS keys from"
fi

if [[ -z "${AWS_ACCESS_KEY_ID}" && -z "${AWS_SECRET_ACCESS_KEY}" ]]
then
  echo "please make sure you have a params.conf with your aws keys in it"
  exit 1
fi

while getopts ":r:s:i:p:n:" opt; do
  case $opt in
    r)
      AWS_DEFAULT_REGION=${OPTARG}
      ;;
    i)
      MYUID=${OPTARG}
      ;;
    s)
      KEYPAIR_NAME=${OPTARG}
      ;;
    p)
      KEY_PATH=${OPTARG}
      ;;
    n)
      SUBNET=${OPTARG}
      ;;
    *)
      usage
      exit 0
      ;;
  esac
done

# All these can now be readonly
readonly AWS_DEFAULT_REGION
readonly MYUID
readonly KEYPAIR_NAME
readonly KEY_PATH
readonly AMI
readonly INSTANCE_TYPE
readonly AWS_SECRET_ACCESS_KEY
readonly AWS_ACCESS_KEY_ID

if [[ -z "${MYUID}" ]]
then
  echo "you forgot to supply a unique identifier"
  exit 1
fi

if [[ -z "${KEYPAIR_NAME}" ]]
then
  echo "you forgot to supply the aws key name"
  exit 1
fi

if [[ -z "${KEY_PATH}" ]]
then
  echo "you forgot to supply a path to the ssh key"
  exit 1
fi

if [[ -z "${SUBNET}" ]]
then
  echo "you forgot to supply a subnet id"
  exit 1
fi

read AZ VPCID <<<$(aws ec2 describe-subnets --subnet-ids ${SUBNET} | awk '{print $2" "$NF}')

#SGMISC
read SGMISC NULL <<<$(aws ec2 create-security-group --vpc-id ${VPCID} --group-name ${MYUID} --description "${MYUID} SGMISC" | tr "\t" " ")
#SGWWW
read SGWWW NULL <<<$(aws ec2 create-security-group --vpc-id ${VPCID} --group-name ${MYUID}-www --description "${MYUID} SGWWW" | tr "\t" " ")
#SGSTRICT
read SGSTRICT NULL <<<$(aws ec2 create-security-group --vpc-id ${VPCID} --group-name ${MYUID}-strict --description "${MYUID} SGSTRICT" | tr "\t" " ")


#populate params.conf
cat > params.conf <<_EOF_
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
KEYPAIR_NAME=${KEYPAIR_NAME}
AMI=${AMI}
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}
AZ=${AZ}
SUBNET=${SUBNET}
INSTANCE_TYPE=${INSTANCE_TYPE}
KEY_PATH=${KEY_PATH}
SGMISC=${SGMISC}
SGWWW=${SGWWW}
SGSTRICT=${SGSTRICT}
MYUID=${MYUID}
_EOF_

MYIP=$(curl ipv4.icanhazip.com)

# misc
aws ec2 authorize-security-group-ingress --group-id ${SGMISC} --protocol tcp --port 22 --cidr ${MYIP}/32
aws ec2 authorize-security-group-ingress --group-id ${SGMISC} --protocol tcp --port 2222 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${SGMISC} --source-group ${SGMISC} --protocol tcp --port 80
aws ec2 authorize-security-group-ingress --group-id ${SGMISC} --source-group ${SGMISC} --protocol tcp --port 443
aws ec2 authorize-security-group-ingress --group-id ${SGMISC} --source-group ${SGMISC} --protocol tcp --port 3128
aws ec2 authorize-security-group-ingress --group-id ${SGMISC} --source-group ${SGSTRICT} --protocol tcp --port 3128

# -www
aws ec2 authorize-security-group-ingress --group-id ${SGWWW} --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${SGWWW} --protocol tcp --port 443 --cidr 0.0.0.0/0

# -strict
aws ec2 revoke-security-group-egress --group-id ${SGSTRICT} --protocol -1 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-egress --group-id ${SGSTRICT} --protocol udp --port 53 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-egress --group-id ${SGSTRICT} --protocol tcp --port 3128 --source-group ${SGMISC}
aws ec2 authorize-security-group-ingress --group-id ${SGSTRICT} --source-group ${SGMISC} --protocol tcp --port 22
aws ec2 authorize-security-group-ingress --group-id ${SGSTRICT} --source-group ${SGMISC} --protocol tcp --port 80
aws ec2 authorize-security-group-ingress --group-id ${SGSTRICT} --source-group ${SGMISC} --protocol tcp --port 443
