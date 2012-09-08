#!/usr/local/bin/bash

#Array to hold all our ethernet devices
ethernetDevices=()

declare -A proxyTypes
proxyTypes["SOCKS"]="socksfirewall"
proxyTypes["SSL Web"]="secureweb"
proxyTypes["Web"]="web"

#Character length of the longest device name for output formatting
deviceLength=0

#COLORS!!!
txtblk='\e[0;30m' # Black - Regular
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
txtylw='\e[0;33m' # Yellow
txtblu='\e[0;34m' # Blue
txtpur='\e[0;35m' # Purple
txtcyn='\e[0;36m' # Cyan
txtwht='\e[0;37m' # White
bldblk='\e[1;30m' # Black - Bold
bldred='\e[1;31m' # Red
bldgrn='\e[1;32m' # Green
bldylw='\e[1;33m' # Yellow
bldblu='\e[1;34m' # Blue
bldpur='\e[1;35m' # Purple
bldcyn='\e[1;36m' # Cyan
bldwht='\e[1;37m' # White
unkblk='\e[4;30m' # Black - Underline
undred='\e[4;31m' # Red
undgrn='\e[4;32m' # Green
undylw='\e[4;33m' # Yellow
undblu='\e[4;34m' # Blue
undpur='\e[4;35m' # Purple
undcyn='\e[4;36m' # Cyan
undwht='\e[4;37m' # White
bakblk='\e[40m'   # Black - Background
bakred='\e[41m'   # Red
badgrn='\e[42m'   # Green
bakylw='\e[43m'   # Yellow
bakblu='\e[44m'   # Blue
bakpur='\e[45m'   # Purple
bakcyn='\e[46m'   # Cyan
bakwht='\e[47m'   # White
txtrst='\e[0m'    # Text Reset



get_devices()
{
	#Get a list of devices
	devices="$(networksetup -listallnetworkservices)"
	#Array declaration 1
	#declare -a RET_DEVICES
	#Array declaration 2
	#Set the splitting char, note the $ is *really* important
	IFS=$'\n'
	#loop over devices, keep anything with 'Wi-Fi' or 'Ethernet'
	for var in ${devices}
	do
		#some bad regex.
		if [[ ${var} =~ .*Ethernet.* || ${var} =~ .*Wi-Fi.* ]]; then
			ethernetDevices+=("$var")
			if [ ${#var} -gt $deviceLength ]; then
				deviceLength=${#var}
			fi
		fi
	done
	#echo "Found Devices: " ${ethernetDevices[@]}
}

get_status()
{
	echo "Current Proxy Status"
	for device in "${ethernetDevices[@]}"; do
		echo -e $undwht$device$txtrst
		for proxy in "${!proxyTypes[@]}"
		do
			#echo "key  : $proxy"
			#echo "value: ${proxyTypes[$proxy]}"
			#Check if the proxy is enabled
			#printf -v proxyString -- "-get%sproxy %s" ${proxyTypes[$proxy]} ${device}
			#echo "String to execute: /usr/sbin/networksetup $proxyString"
			#echo $(networksetup $proxyString)
			enabled=$(networksetup -get${proxyTypes[$proxy]}proxy ${device} | grep -e "^Enabled" | cut -d" " -f2)
			#enabled=$(networksetup ${proxyString} | grep -e "^Enabled" | cut -d" " -f2)
			#out="$device Web Proxy Enabled:\t$enabled"
			#out "%s Proxy Enabled: %*s" $proxy $deviceLength $enabled
			out="${proxy} Proxy Enabled:\t"
			if [ -z "$enabled" ]; then
				out="${out}{$txtred}Unable to determine proxy status${txtrst}"
			elif [ "Yes" == $enabled ]; then
				proxyServer=$(networksetup -get${proxyTypes[$proxy]}proxy ${device} | grep -e "^Server" | cut -d" " -f2)
				proxyPort=$(networksetup -get${proxyTypes[$proxy]}proxy ${device} | grep -e "^Port" | cut -d" " -f2)
				out="${out}${txtgrn}${enabled}\t${proxyServer}:${proxyPort}${txtrst}"
			else
				#Should bw "No"
				out=${out}${txtred}${enabled}${txtrst}
			fi
			echo -e $out
		done
		echo
	done
}
usage()
{
	echo -e "Usage: $0 {status | <socks|web> off | <socks|web> on <host:port>}"
	exit 1
}
enable_proxy()
{
	if [ -z "$1" ] || [ -z "$2" ]; then
		usage
	fi
	if [ "$1" != "web" ] && [ "$1" != "socks" ]; then
		usage
	fi
	HOST=$(echo $2 | cut -d":" -f1) 
	PORT=$(echo $2 | cut -d":" -f2)
	if [ "$1" == "web" ]; then
		for device in "${ethernetDevices[@]}"; do
			networksetup -setwebproxy $device $HOST $PORT off
			networksetup -setwebproxystate $device on
			networksetup -setsecurewebproxy $device $HOST $PORT off
			networksetup -setsecurewebproxystate $device on
		done
	else
		for device in "${ethernetDevices[@]}"; do
			networksetup -setsocksfirewallproxy $device $HOST $PORT off
			networksetup -setsocksfirewallproxystate $device on
		done
	fi
	get_status
	#command inject the hell out of this.
	#screw validation, your fault if you screw up.
	#ip:post
	#^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\:(6553[0-5]|655[0-2]\d|65[0-4]\d{2}|6[0-4]\d{3}|[1-5]\d{4}|[1-9]\d{0,3})$
}

disable_proxy()
{
	if [ -z "$1" ]; then
		usage
		exit 1
	fi
	if [ $1 == "socks" ]; then
		for device in "${ethernetDevices[@]}"; do
			networksetup -setsocksfirewallproxystate $device off
		done
	elif [ $1 == "web" ]; then
		for device in "${ethernetDevices[@]}"; do
			networksetup -setwebproxystate $device off
			networksetup -setsecurewebproxystate $device off
		done
	else 
		usage
	fi
	#networksetup -setwebproxystate $DEVICE_ETH off
	#networksetup -setwebproxystate $DEVICE_WIFI off
}
case "$2" in
	on)
		get_devices
		enable_proxy $1 $3
		;;
	off)
		get_devices
		disable_proxy $1
		get_status
		;;
	*)
		get_devices
		get_status
		usage
		exit 1
esac
