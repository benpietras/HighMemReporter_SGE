#!/bin/bash
#
# This runs highmem_reporter.sh, highmem_analysis.sh

trap 'rm -rf "$tmp"; exit' ERR EXIT

tmp=$(mktemp -d)

cd $tmp
/mnt/iusers01/ri-sysadmin/scripts/csf3/bin/highmem_reporter.sh > $tmp/last7.txt 
sleep 2
/mnt/iusers01/ri-sysadmin/scripts/csf3/bin/highmem_analysis.sh $tmp/last7.txt 
sleep 2
