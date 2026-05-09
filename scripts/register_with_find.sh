#!/bin/bash
host=`/bin/hostname`
ip=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`
wanip=`wget http://checkip.homeseer.com:8245 -q -O -`
re="[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"
if [[ $wanip =~ $re ]]; then
    wanip=${BASH_REMATCH[0]}
fi

while [[ $x -le 5 ]]
do
x=$(( $x + 1 ))
sleep 5
done

url=http://find.homeseer.com/findhomeseer/default.aspx?srcip=$wanip\&localip=$ip\&machine=$host\&tools=true\&port=911
sudo wget $url --spider -q -O -

