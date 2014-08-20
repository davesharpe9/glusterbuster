#!/bin/bash
cd /vagrant/source/mitmproxy
logno=0
while true
do
  ./mitmproxy_ssh -H $1 -P 22 -p 2222 -o /home/ubuntu/capture${logno}.log
  logno=`expr $logno + 1`
done
