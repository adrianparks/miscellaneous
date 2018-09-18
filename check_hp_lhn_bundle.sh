#!/bin/bash
#
# Check for RAID corruption on HPE StoreVirtual nodes
#
# Copy this script and the extracted LHN management group bundle 
# into their own directory. Then run this script with the bundle
# as a parameter
# Anything higher than 0x9 such as 0x19 or 0x39 is bad news
# this script only works with SANiq 11.5 and higher

if [ $# -eq 0 ];
  then
    echo "No arguments supplied"
    exit 1
fi

if [ ! -e $1];
  then
    echo "Could not locate file $1"
    exit 1
fi

unzip $1

for i in $(ls *.tar.gz); do 
 mkdir $i.dir
 cd $i.dir
 tar -xvzf ../$i
 cd mnt/logs
 tar -xvf vendorLogs.tar
 cd ../../..
done

echo
echo "Logs extracted; checking for the creeping death:"
echo
echo
find . -name ADUReport.txt -exec grep "^   Surface Analysis Status" {} \;

