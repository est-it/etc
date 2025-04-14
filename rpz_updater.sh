#!/bin/bash
#Download function with error handling
get_rpz() {
    echo "get zone at $2"

    /usr/bin/curl -Lfo $1 $2
    error=$?
    if (( error > 0 )); then
        echo "curl error code: $error! exiting."
        rm $1
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
master="/var/lib/named/dyn/hagezi-pro.rpz"
get_rpz $master-tmp https://raw.githubusercontent.com/hagezi/dns-blocklists/main/rpz/pro.txt
check_vers $master $master-tmp
if (( $? == 0 )); then
    echo "move $master-tmp to $master"
    mv $master-tmp $master
    reload hagezi-pro.rpz
else
    echo "removing $master-tmp"
    rm $master-tmp
fi

#get tif list
master="/var/lib/named/dyn/hagezi-tif.rpz"
get_rpz $master-tmp https://raw.githubusercontent.com/hagezi/dns-blocklists/main/rpz/tif.txt
check_vers $master $master-tmp
if (( $? == 0 )); then
    echo "move $master-tmp to $master"
    mv $master-tmp $master
    reload hagezi-tif.rpz
else
    echo "removing $master-tmp"
    rm $master-tmp
fi
