#!/bin/bash
set -o errexit

unset AWS_SECURITY_TOKEN

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

if ! vagrant destroy -f; then
  echo "vagrant destruction problem"
fi

echo -n "Waiting for instances to terminate ."
while [[ $(aws ec2 describe-instances --filters Name=tag:Name,Values=${MYUID}* --query 'Reservations[*].Instances[*].[State.Name]' | grep terminated 2>/dev/null | wc -l | tr -d " ") -ne 2 ]]; do
  echo -n .
  sleep 1
done
echo

aws elb delete-load-balancer --load-balancer-name ${MYUID}
echo -n "Waiting for load balancer to disappear ."
while aws elb describe-load-balancers --load-balancer-names ${MYUID} > /dev/null 2>&1; do
  echo -n .
  sleep 1
done
echo
aws ec2 revoke-security-group-ingress --group-id ${SGMISC} --source-group ${SGMISC} --protocol tcp --port 80
aws ec2 revoke-security-group-ingress --group-id ${SGMISC} --source-group ${SGMISC} --protocol tcp --port 443
aws ec2 revoke-security-group-ingress --group-id ${SGMISC} --source-group ${SGMISC} --protocol tcp --port 3128
aws ec2 revoke-security-group-ingress --group-id ${SGMISC} --source-group ${SGSTRICT} --protocol tcp --port 3128
aws ec2 revoke-security-group-egress --group-id ${SGSTRICT} --protocol tcp --port 3128 --source-group ${SGMISC}
aws ec2 revoke-security-group-ingress --group-id ${SGSTRICT} --source-group ${SGMISC} --protocol tcp --port 22
aws ec2 revoke-security-group-ingress --group-id ${SGSTRICT} --source-group ${SGMISC} --protocol tcp --port 80
aws ec2 revoke-security-group-ingress --group-id ${SGSTRICT} --source-group ${SGMISC} --protocol tcp --port 443
aws ec2 delete-security-group --group-id ${SGWWW}
aws ec2 delete-security-group --group-id ${SGMISC}
aws ec2 delete-security-group --group-id ${SGSTRICT}
