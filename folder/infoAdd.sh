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

#This script is used to add the list'

echo -e 'Add Device Info\n'

input(){
	read -p "IP Address: " ipAddr
	read -p "Device Name: " devName
	read -p "Device Module [ 1)CM32; 2)CM16; 3)CM8; 4)MOXA ]: " ModN
}

lg=0
while [ $lg == '0' ]
do
	input
	if [ $ModN == '1' ]; then
		Mod='CM32'
		let lg++
	elif [ $ModN == '2' ]; then
		Mod='CM16'
		let lg++
	elif [ $ModN == '3' ]; then
		Mod='CM8'
		let lg++
	elif [ $ModN == '4' ]; then
		Mod='MOXA'
		let lg++
	else
		echo -e 'illegal input\n'
	fi
done 

(echo -e $ipAddr ',' $devName ',' $Mod | sed 's/ //g') >> ./list/devInfoList

district=${devName:0:2}
city=${devName:2:3}
idc=${devName:5:3}

(echo -e $district ',' $city ',' $idc | sed 's/ //g') >> ./list/popInfoList

echo -e "Device add completed."

# Back to menu or show the result
backJud=1
while [ $backJud == '1' ]
read -p "Press 'B' to back to menu." back
do
	if [ $back == 'B' ] || [ $back == 'b' ]; then
		let backJud++
		cd ..
		sh start.sh
		exit
	else
		echo 'ILLEGAL INPUT'
	fi
done