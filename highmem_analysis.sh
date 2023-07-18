#!/bin/bash
# highmem_analysis.sh
# B.Pietras, UoM RIT Jul 2023
# runs on output of highmem_reporter.sh
# to divide by user 
# $ ./highmem_analysis.sh last7.txt 

trap 'rm -rf $tempo1 $tempo2 $tempo3 $tempo4 $dir $zippo' EXIT

dir=highmem_misuse-"`date +"%Y-%m-%d"`"
misuse="${dir}.txt"
zippo="${dir}.zip"

> $misuse

tempo1=$(mktemp)
tempo2=$(mktemp)
tempo3=$(mktemp)
tempo4=$(mktemp)

grep vbigmem $1 | cut -d ',' -f 1 > $tempo1
mapfile -t UsersArray < $tempo1
len=${#UsersArray[@]}
csplit $1 -s -n 1 -f highmem_ '%vbigmem%' '/vbigmem/' '{*}'

for (( i=0; i<$len; i++ )); do 
mv highmem_$i ${UsersArray[$i]}_highmem.txt;
groupie=$(groups ${UsersArray[$i]} | awk '{print $3}')
mailo=$(/mnt/iusers01/ri-sysadmin/scripts/csf3/bin/ldapu.sh ${UsersArray[$i]} | grep 'mail:' | cut -d ' ' -f2)
words=$(wc -l < ${UsersArray[$i]}_highmem.txt)
word=$(echo $(($words-2)))
echo -e ${UsersArray[$i]} "\t" $groupie "\t" $mailo "\t" $word >> $tempo2
done

sort -nr -k4 $tempo2 > $tempo3
sed -i '1s/^/username group email jobno\n/' $tempo3
cat $tempo3 | column -t > $tempo4
cat $tempo4 > $misuse
mkdir $dir
mv *highmem*txt $dir
cp last*.txt $dir
zip -q -T -m -r $zippo $dir

text1="Hi, 

This is a weekly report on misuse of the high memory nodes. 

Below is an overview, the zip attached has nicer columns (no o365 meddling). 
There's in-depth per-user info too, with the recommended node type for each job.

"

text2=`cat ""$tempo4""`

text3="

A suggestion of an email to relevant users may be found here:
https://ri.itservices.manchester.ac.uk/sysadmin/csf3/misc-sysadmin/high-memory-node-reporter

Cheers,
Ben

-----------------------------------------------------
Dr Ben Pietras <ben.pietras@manchester.ac.uk>
Research Infrastructure, IT Services
University of Manchester, UK
IT Services Research Infrastructure Team
-----------------------------------------------------"
#emailto=ben.pietras@manchester.ac.uk
emailto=hpcsysadmins@listserv.manchester.ac.uk # redacted
echo -e "$text1$text2$text3" | mail -s "High memory node misuse, weekly report" -a $zippo $emailto "${emailto}"
