#!/bin/bash
count=0
while true
do
  ./mitmproxy_ssh -H 10.250.250.3 -p 2223 -o /var/tmp/output${count}.txt;
  count=`expr $count + 1`
done
