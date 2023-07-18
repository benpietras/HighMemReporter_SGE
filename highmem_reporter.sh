#!/bin/bash
# highmem_reporter.sh
# B.Pietras, UoM RIT Jan 2023
# This script checks memory usage of high memory SGE jobs for the last 30 days

qacction () {
	tempo2=$(mktemp)
	tempo3=$(mktemp)
        tempo4=$(mktemp)
        tempo5=$(mktemp)
        grep "u $1" -B 43 $tempo  > $tempo2
 	egrep 'qname|jobnumber|slots|maxvmem|category' $tempo2 |  grep -A 4 vbigmem.q  | sed 's/--//g' | sed '/./!d' > $tempo3
	num_vbigmem="$(grep vbigmem.q $tempo3 | wc -l)"

		for (( j=0; j<$num_vbigmem; j++ )); do
		let start=($j*5)+1
		let end=($j*5)+5
		sed -n "${start},${end}p" $tempo3 > $tempo4
		memtest $tempo4 >> $tempo5 
		done

		if [ -s "${tempo5}" ]; then
		echo -e '---------------------------------------------------------------------'
		echo -e $1', last '$days' days vbigmem:'
		sed -i '1 s/^/jobno|node|maxvmem|slots|mem_perc|recommended\n/' $tempo5
		column $tempo5 -t -s "|"
		fi
		rm $tempo2 $tempo3 $tempo4 $tempo5
}

memtest () {
		maxvmem=$(grep maxvmem $1| awk '{print $2}')              
		slots=$(grep slots $1 | awk '{print $2}')
		maxvmem_num=$(echo $maxvmem | sed 's/[^[:digit:].]\+//g')
		jobnumber=$(grep jobnumber $1 | awk '{print $2}')
		maxvmem_num_per_core=$(echo "scale=3; $maxvmem_num/$slots" | bc)
		maxvmem_num_per_core_int=$(echo "scale=0; $maxvmem_num/$slots" | bc)
		mem_units=$(echo $maxvmem | sed 's/[0-9.]//g')
		node=$(grep TRUE $1 | awk '{print $7}' | cut -d '=' -f 1)

		if [[ ${maxvmem} != *"GB"* ]] || [[ ${maxvmem} != *"TB"* ]]; then
 		suited='standard'
		fi

		if [[ ${maxvmem} == *"GB"* ]]; then
		suited=$(suitable $maxvmem_num_per_core_int)
		mem_units='GB'
		fi

	        if [[ ${maxvmem} == *"TB"* ]]; then	
	        maxvmem_per_core_in_gb=$(echo $maxvmem_num_per_core 1000 |  awk '{print $1*$2}')
		suited=$(suitable $maxvmem_per_core_in_gb)
		mem_units='TB'
		fi
		
		maxvmem_num_per_core0=$(echo $maxvmem_num_per_core | sed -E 's/(^|[^0-9])\./\10./g')

		if [[ $suited != "$node" ]] && [[ $maxvmem_num_per_core != 0 ]]; then
                echo $jobnumber'|'$node'|'$maxvmem'|'$slots'|'$maxvmem_num_per_core0$mem_units'|'$suited 
		fi
}

suitable () {
                if [[ $1 -lt 5 ]]; then 
                suit='standard'
                elif [[ $1 -ge 5 ]]  && [[ $1 -lt 16 ]]; then
                suit='mem256'
                elif [[ $1 -ge 16 ]] && [[ $1 -lt 32 ]]; then
                        suit='mem512'
                        elif [[ $1 -ge 32 ]] && [[ $1 -lt 48 ]]; then
                        suit='mem1500'
                        elif [[ $1 -ge 48 ]] && [[ $1 -lt 51 ]]; then
                        suit='mem1024'
                        elif [[ $1 -ge 51 ]] && [[ $1 -lt 64 ]]; then
                        suit='mem2000'
                        elif [[ $1 -ge 64 ]] && [[ $1 -lt 128 ]]; then
                        suit='mem4000'
                        elif [[ $1 -ge 128 ]]; then
                        suit='OOM'
                        fi
			echo $suit
}	

days=7

tempo=$(mktemp)
tempo1024=$(mktemp)
tempo1500=$(mktemp)
tempo2000=$(mktemp)
tempo4000=$(mktemp)
tempoC=$(mktemp)

# The below two needed for cron
export SGE_ROOT=/opt/site/sge
export PATH=/opt/site/sge/bin/lx-amd64:${PATH}

qacct -d $days -j > $tempo

trap 'rm -rf "$tempo" "$tempo1024" "$tempo1500" "$tempo2000" "$tempo4000" "$tempoC"; exit' ERR EXIT  
SGE_SINGLE_LINE=1 qconf -su mem1024.userset | awk '/^entries/ {print $2}' | tr , '\n' > $tempo1024
SGE_SINGLE_LINE=1 qconf -su mem1500.userset | awk '/^entries/ {print $2}' | tr , '\n' > $tempo1500
SGE_SINGLE_LINE=1 qconf -su mem2000.userset | awk '/^entries/ {print $2}' | tr , '\n' > $tempo2000
SGE_SINGLE_LINE=1 qconf -su mem4000.userset | awk '/^entries/ {print $2}' | tr , '\n' > $tempo4000

cat $tempo1024 $tempo1500 $tempo2000 $tempo4000 | sort -u > $tempoC
mapfile -t UsersArray < $tempoC

# ---

len=${#UsersArray[@]}
for (( i=0; i<$len; i++ )); do 
qacction ${UsersArray[$i]};
done
