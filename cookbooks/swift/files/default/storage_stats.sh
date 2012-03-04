#!/bin/bash
hostname
echo -n 'account files '
find /srv -type f | grep account | wc -l
echo -n 'container files '
find /srv -type f | grep container | wc -l
echo -n 'object files '
find /srv -type f | grep object | wc -l
echo
echo -n 'rsync procs: '; ps -ef | grep -c 'rsync'
echo -n 'swift procs: '; ps -ef | grep -c 'swift'
echo -n 'chef procs:  ' ; ps -ef | grep -c 'chef' 
echo
#echo -n "Packages installed: "
#aptitude -s search '~i~nswift' -F '%p' | xargs echo
ls -l /etc/swift
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

