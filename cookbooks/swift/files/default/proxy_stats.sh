#!/bin/bash
echo -n Dispersion:
tr -s '\n' ' ' </tmp/munin-plugin-openstack-swift-dispersion 


echo RING BUILDER INFO:
swift-ring-builder /etc/swift/account.builder
#swift-ring-builder /etc/swift/container.builder
#swift-ring-builder /etc/swift/object.builder

echo

echo "LISTEN PORT, TOTAL CONNECTIONS, NUM CONNECTIONS FROM EACH HOST:"
my_lsof () {
        lsof -nPi tcp:$1 -F n -sTCP:ESTABLISHED | grep -v p | sort | uniq -c | wc -l
        lsof -nPi tcp:$1 -F n -sTCP:ESTABLISHED | grep -v p | cut -d'>' -f2 | cut -d':' -f1 | sort | uniq -c
}

for x in 873 6000 6001 6002 8080;
do
  echo -n "port $x Connections: (total) "
  my_lsof $x
done
echo

ps -ef | grep 'chef\|memca\|swift\|munin'

echo
#echo -n "Packages installed: "
#aptitude -s search  '~i~nswift' -F '%p' | xargs echo
echo

netstat -lntp | grep '11211\|8080'

echo 

ls /etc/swift/*
