#!/bin/bash

#Tree:
#├──start.sh
#└──folder
#    ├──scanner.sh
#    ├──infoAdd.sh
#    ├──list
#    │   ├──devInfoList
#    │   └──popInfoList
#    ├──log
#    │   └──$rawLog
#    └──testResult
#        └──$scanResult

fileDate=$(date +%Y%m%d%H%M)
rawLog=${fileDate}
scanResult=ConsoleCheck_${fileDate}

#Get the destination device
read -p "CHECK DEVICE [ ENTER 'all' for ALL DEVICE ]:" Dev

#count device
count=$(cat -n ./list/devInfoList | wc -l)

#'0'->no device; '1'->device verify; '2'->all device
num=1
if [ $Dev == 'all' ]; then
	jud=2
else
	while [ $num -le $count ]
	do
		Dev2=$((awk 'NR == n' n=$num ./list/devInfoList) | awk -F ',' '{print $2}')
		if [ $Dev2 == $Dev ]; then
			jud=1
			Des[0]=$((awk 'NR == n' n=$num ./list/devInfoList) | awk -F ',' '{print $1}')
			Des[1]=$Dev
			Des[2]=$((awk 'NR == n' n=$num ./list/devInfoList) | awk -F ',' '{print $3}')
			let num=num+count
		elif [ $Dev2 != $Dev ] && [ $num == $count ]; then
			jud=0
			let num++
		else
			let num++
		fi
	done
fi

#ping test funtion; ptr:ping test result
pTest(){
	count=$(ping ${Des[0]} -c 10 | grep 'received' | awk -F ',' '{print $2}' | awk '{print $1}');
	if [ $count -ge '6' ]; then
		ptr=1
	else
		ptr=0
	fi
}
	
CMJud(){
	if [ "${Des[2]}" == 'CM32' ]; then
		portE=3
	elif [ "${Des[2]}" == 'CM16' ]; then
		portE=2
	elif [ "${Des[2]}" == 'CM8' ]; then 
		portE=1
	fi
}	
	
#test funtion for CM Series
cTest(){
	CMJud
	echo -e "\n\n+++++"${Des[1]}"+++++" >> ./log/$rawLog
	port=7001
	let port2=port+portE
	
	while [ $port != $port2 ]
	do
		echo -e "\n####"$port"####" >> ./log/$rawLog
		(sleep 2; echo -e "\n"; sleep 2;)| telnet ${Des[0]} $port >> ./log/$rawLog
		port=$(($port+1))
	done
}

#test funtion for Moxa
mTest(){		
	echo -e "\n\n+++++"${Des[1]}"+++++" >> ./log/$rawLog
	port=4001
	let port2=port+3
	
	while [ $port != $port2 ]
	do
		echo -e "\n####"$port"####" >> ./log/$rawLog
		(sleep 2; echo -e "\n"; sleep 2;)| telnet ${Des[0]} $port >> ./log/$rawLog
		port=$(($port+1))
	done
}

# To get the useful info from the raw log
compAndOpt(){
	disInfo=${lineLog:0:2}
	ctInfo=${lineLog:2:3}
	idcInfo=${lineLog:5:3}	
	if [ $disInfo == "++" ]; then
		echo $lineLog >> ./testResult/$scanResult
	elif [ $disInfo == "##" ]; then
		echo $lineLog >> ./testResult/$scanResult
	elif [ $disInfo == "!!" ]; then
		echo $lineLog >> ./testResult/$scanResult
	else
		numCNO=1
		countCNO=$(cat -n ./list/popInfoList | wc -l)
		while [ $numCNO -le $countCNO ]
		do
			judInfo[0]=$((awk 'NR == n' n=$numCNO ./list/popInfoList) | awk -F ',' '{print $1}')
			judInfo[1]=$((awk 'NR == n' n=$numCNO ./list/popInfoList) | awk -F ',' '{print $2}')
			judInfo[2]=$((awk 'NR == n' n=$numCNO ./list/popInfoList) | awk -F ',' '{print $3}')
			if [ $disInfo == ${judInfo[0]} ]; then
				if [ $ctInfo == ${judInfo[1]} ];then
					if [ $idcInfo == ${judInfo[2]} ];then
						(echo $lineLog | awk '{print $1}') >> ./testResult/$scanResult
						let numCNO=numCNO+countCNO
					fi
				fi
			fi
			let numCNO++
		done
	fi
}

#Analysit funtion
ana(){
	numAna=1
	countAna=$(cat -n ./log/$rawLog | wc -l)
	while [ $numAna -le $countAna ]
	do
		lineLog=$(awk 'NR == n' n=$numAna ./log/$rawLog)
		if [ "${lineLog}" ]; then
			compAndOpt
		fi
		let numAna++
	done
}

#Test all
aTest(){
	while [ $num -le $count ]
	do
		Des[0]=$((awk 'NR == n' n=$num ./list/devInfoList) | awk -F ',' '{print $1}')
		Des[1]=$((awk 'NR == n' n=$num ./list/devInfoList) | awk -F ',' '{print $2}')
		Des[2]=$((awk 'NR == n' n=$num ./list/devInfoList) | awk -F ',' '{print $3}')
		noMean=$((awk 'NR == n' n=$num ./list/devInfoList) | awk -F '#' '{print $1}')

		#to see if there is '#'
		if [ "${noMean}" ]; then
			pTest
			if [ $ptr == '1' ]; then
				if [ ${Des[2]} == 'CM32' ] || [ ${Des[2]} == 'CM16' ] || [ ${Des[2]} == 'CM8' ]; then
					cTest
				elif [ ${Des[2]} == 'MOXA' ]; then
					mTest
				fi
			elif [ $ptr == '0' ]; then
				echo -e "\n\n!!"${Des[1]} "is Unreachable !!" >> ./log/$rawLog
			fi
		fi
		let num++
	done
	ana
}

# If no device
if [ $jud == '0' ]; then
	echo 'No such device'
# Select the test funtion
elif [ $jud == '1' ]; then
	pTest
	if [ $ptr == '1' ]; then
		if [ ${Des[2]} == 'CM32' ] || [ ${Des[2]} == 'CM16' ] || [ ${Des[2]} == 'CM8' ]; then
			cTest
			ana
		elif [ ${Des[2]} == 'MOXA' ]; then
			mTest
			ana
		fi
	elif [ $ptr == '0' ]; then
		echo -e "\n\n!!"${Des[1]} "is Unreachable"
	fi
elif [ $jud == '2' ]; then
	aTest
fi 

echo -e "Scanning complete."

# Back to menu or show the result
backJud=1
while [ $backJud == '1' ]
echo -e '[B] Back to menu;\n[S] Show the result'
read -p 'ENTER YOUR SELECTION: ' sltS
do
	if [ $sltS == 'B' ] || [ $sltS == 'b' ]; then
		let backJud++
		cd ..
		sh start.sh
		exit
	elif [ $sltS == 'S' ] || [ $sltS == 's' ]; then
		cat ./testResult/$scanResult
	else
		echo 'ILLEGAL INPUT'
	fi
done 