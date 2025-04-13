#!/bin/bash
cleanup() {
    if (( $error > 0 )); then rm $tmpfile; fi
}
trap cleanup EXIT
#Download function with error handling
get_rpz() {
    echo "get zone at $2"
    
    curl -Lfo $1 $2
    error=$?
    if (( error > 0 )); then
        echo "curl error code: $error! exiting."
        exit $error
    fi
}
#check version difference
check_vers() {
    old=$(grep '^@ SOA' $1 | cut -d " " -f 5)
    new=$(grep '^@ SOA' $2 | cut -d " " -f 5)
    echo "old version: $old"
    echo "new version: $new"
    if (( $new > $old )); then
       echo "new version downloaded!"
       return 0
    else
       echo "new version is not newer than old version"
       return 1
    fi
}
#reload function
reload() {
    echo "reloading $1 with rndc"
    /usr/sbin/rndc reload $1
}

error=0

#get pro list
tmpfile=$(mktemp)
master="/var/lib/named/master/hagezi-pro.rpz"
get_rpz $tmpfile https://raw.githubusercontent.com/hagezi/dns-blocklists/main/rpz/pro.txt
check_vers $master $tmpfile
if (( $? == 0 )); then
    echo "move $tmpfile to $master"
    mv $tmpfile $master
    reload hagezi-pro.rpz
else
    echo "removing $tmpfile"
    rm $tmpfile
fi

#get tif list
tmpfile=$(mktemp)
master="/var/lib/named/master/hagezi-tif.rpz"
get_rpz $tmpfile https://raw.githubusercontent.com/hagezi/dns-blocklists/main/rpz/tif.txt
check_vers $master $tmpfile
if (( $? == 0 )); then
    echo "move $tmpfile to $master"
    mv $tmpfile $master
    reload hagezi-tif.rpz
else
    echo "removing $tmpfile"
    rm $tmpfile
fi
