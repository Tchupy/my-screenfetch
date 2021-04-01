#!/usr/bin/env bash

# my-screen - a CLI Bassh script to system info 

# based on ScreenFetch script from Brett Bohnenkamper <kittykatt@kittykatt.us>
# (I added IP address info & Filesystem info)

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# version=1.0
# author=Tchupy


###########################
export TERM=xterm-256color
#color printf code
red="\033[01;31m"
white="\033[01;37m"

# welcome message with hostname
	welcome="$(tput setaf 9)Welcome$(tput setaf 15) @ $(tput setaf 9)`hostname`"
	output_title_array=("Welcome ${white}@ ")
	output_txt_array=("`hostname`")
	#output_array=("$welcome")

# get date 
	day="$(tput setaf 9)`date`"
	output_title_array=("${output_title_array[@]}" "`date` ")
	output_txt_array=("${output_txt_array[@]}" " ")
	#output_array=("${output_array[@]}" "$day")

# get OS release name
	#eval $(cat /etc/os-release |grep PRETTY_NAME)
	eval $(awk '/^ID=/ {print $0} /^PRETTY_NAME/ {print $0}' /etc/os-release)
	#os_name="$(tput setaf 9)OS:    \t$(tput setaf 15)$PRETTY_NAME" 
	output_title_array=("${output_title_array[@]}" "OS:")
	output_txt_array=("${output_txt_array[@]}" "$PRETTY_NAME")
	#output_array=("${output_array[@]}" "$os_name")

# get kernel info
	kernel="$(tput setaf 9)Kernel:\t$(tput setaf 15)`uname -rms`" 
	#output_array=("${output_array[@]}" "$kernel")
	output_title_array=("${output_title_array[@]}" "Kernel:")
	output_txt_array=("${output_txt_array[@]}" "`uname -rms`")

# get machine uptime 
	uptime="$(tput setaf 9)Uptime:\t$(tput setaf 15)`uptime -p`"
	#output_array=("${output_array[@]}" "$uptime")
	output_title_array=("${output_title_array[@]}" "Uptime:")
	output_txt_array=("${output_txt_array[@]}" "`uptime -p`")

# get numer of packages installed
	#package="$(tput setaf 9)Packages:\t$(tput setaf 15)`dpkg -l | grep -c ^i`"
	package="`dpkg -l | grep -c ^i`"
	#output_array=("${output_array[@]}" "$package")
	output_title_array=("${output_title_array[@]}" "Packages:")
	output_txt_array=("${output_txt_array[@]}" "${package}")

# get CPU architecture
	cpu_arch="unknown"
	if [ -r /proc/cpuinfo ]; then
		cpu_arch=`cat /proc/cpuinfo | grep -m1 "model name" | cut -d: -f2 | sed 's/^\s//'`
	fi

	# construct output variable
	#cpu="$(tput setaf 9)CPU:    \t$(tput setaf 15)$cpu_arch "
	#output_array=("${output_array[@]}" "$cpu")
	output_title_array=("${output_title_array[@]}" "CPU:")
	output_txt_array=("${output_txt_array[@]}" "${cpu_arch}")

# GET MEMORY USAGE
	mem_info=$(cat /proc/meminfo |grep -i -E "memtotal|shmem|MemFree|Buffers|cached|sreclaimable")
	# suppress space (expect ones between lines)
	# suppress "kB"
	mem_info=$(echo  $mem_info | sed -e 's/: /:/g' -e 's/ kB//g')

	for m in $mem_info; do
	#case "${m//:*}" in
		case "${m%%:*}" in
			"MemTotal") usedmem=$((usedmem+=${m#*:})); totalmem=${m#*:} ;;
			"ShMem") usedmem=$((usedmem+=${m#*:})) ;;
			"MemFree"|"Buffers"|"Cached"|"SReclaimable") usedmem=$((usedmem-=${m#*:})) ;;
		esac
	done
	usedmem=$((usedmem / 1024))
	totalmem=$((totalmem / 1024))
	memory="${usedmem}MB / ${totalmem}MB"
	
	# construct output variable
	#ram="$(tput setaf 9)RAM:     \t$(tput setaf 15)$memory "
	#output_array=("${output_array[@]}" "$ram")
	output_title_array=("${output_title_array[@]}" "RAM usage:")
	output_txt_array=("${output_txt_array[@]}" "${memory}")

# GET IPV4 ADDRESS
        # display all global IPv4 addresses
	ipv4_priv=$(ip -4 address show primary scope global | awk '/inet/ {printf $NF "@" $2 "@\n"}')
	for line in $ipv4_priv; do 
		#printf "line = %s" "$line"
		readarray -d@ -t ipv4 <<< ${line}
		output_title_array=("${output_title_array[@]}" "IPv4(${ipv4[0]}):")
		output_txt_array=("${output_txt_array[@]}" "${ipv4[1]}")
		unset ipv4
	done
	

	# try to get public IPv4 address
	if [ -x /usr/bin/curl ]; then
		ipv4_pub=`curl --silent --max-time 1 4.20102020.xyz/ip`
	fi

	if ! [ -z $ipv4_pub ]; then
		# we catch the public IP address
		output_title_array=("${output_title_array[@]}" "IPv4(public):")
		output_txt_array=("${output_txt_array[@]}" "$ipv4_pub")
	fi
	
# GET IPV6 ADDRESSES
	# search for static IPv6 if exist
	ipv6_global_static=`ip -6 address show primary scope global -dynamic`

	if [ -n "$ipv6_global_static" ]; then
		#there is an IPv6 address
		extract=$(awk '/inet6/ {printf $2"@"} /state/ {nameif=$2; sub(":","@",nameif); printf nameif}' <<< "$ipv6_global_static")
		readarray -d@ -t ipv6_static <<< ${extract[@]}
		output_title_array=("${output_title_array[@]}" "IPv6(static-${ipv6_static[0]}):")
		output_txt_array=("${output_txt_array[@]}" "${ipv6_static[1]}")

	fi

	# search for SLAAC address 
	ipv6_slaac="$(ip -6 address show primary scope global dynamic)" 
	if [ -n "$ipv6_slaac" ]; then
		#there is an SLAAC IPv6 address
		extract=$(awk '/inet6/ {printf $2"@"} /state/ {nameif=$2; sub(":","@",nameif); printf nameif}' <<< "$ipv6_slaac")
		readarray -d@ -t ipv6_slaac <<< ${extract[@]}
		output_title_array=("${output_title_array[@]}" "IPv6(slaac-${ipv6_slaac[0]}):")
		output_txt_array=("${output_txt_array[@]}" "${ipv6_slaac[1]}")
	fi

	# search for temporary IPv6 address (IPv6 privacy extension enabled)
	# extract only addresses that are not deprecated
	# extract first address (if there is many temp address, 1st one may be the oldest & so it is used)
	ipv6_tmp=`ip -6 address show primary scope global temporary -deprecated `
	if [ -n "$ipv6_tmp" ]; then
		#there is an temporary IPv6 address
		# extract interface name & IP address
		extract=$(awk '/inet6/ {printf $2"@"} /state/ {nameif=$2; sub(":","@",nameif); printf nameif}' <<< "$ipv6_tmp")
		readarray -d@ -t ipv6_tmp <<< ${extract[@]}
		output_title_array=("${output_title_array[@]}" "IPv6(tmp-${ipv6_tmp[0]}):")
		output_txt_array=("${output_txt_array[@]}" "${ipv6_tmp[1]}")
	fi


# GET HDD space
	# get all filesystem but temp FS
	hdd_menu=$(df -h -x tmpfs -x devtmpfs -x squashfs |
	   awk -v red=$red -v white=$white '
	   	NR==1 { printf("%s%-15s%s \t %s \t %s \t %s \t%s\n", red, $1, $2, $3, $4, $5, $6) }
	   	NR!=1 {
	   	  if (length($1)< 18)
	   		printf("%s%-15s%s%s \t %s \t %s \t %s \t%s\n", red, $1, white, $2, $3, $4, $5, $6)
	     	  else {
	       		printf("%s%s\n", red, $1)
	       		printf("%s%19s\t%s\t %s \t %s \t%s\n", white, $2, $3, $4, $5, $6)
	     	  }
	     	}
	   '
	)

	# set separator as '\n' character
	IFS=$'\n'
	i=1; 
	for item in $hdd_menu;
		do
			output_title_array=("${output_title_array[@]}" "$item")
			i=$((i+1))
		done
	# unset separator to use default one
	unset IFS

# find color codes here : https://misc.flogisoft.com/bash/tip_colors_and_formatting
green="\033[01;32m"
red="\033[01;31m"
white="\033[01;37m"
yellow="\033[01;33m"
blue="\033[38;5;68m"

# ID from /etc/os-release
case $ID in
	"raspbian")
		# Define color 
		c1=$green
		c2=$red

		output=(
		"${c1}                                %-30b%b"
		"${c1}    .',;:cc;,'.    .,;::c:,,.   %-30b%b"
		"${c1}   ,ooolcloooo:  'oooooccloo:   %-30b%b"
		"${c1}   .looooc;;:ol  :oc;;:ooooo'   %-30b%b"
		"${c1}     ;oooooo:      ,ooooooc.    %-30b%b"
		"${c1}     .,:;'.       .;:;'.        %-30b%b"
		"${c2}       .... ..'''''. ....       %-30b%b"
		"${c2}     .''.   ..'''''.  ..''.     %-30b%b"
		"${c2}     ..  .....    .....  ..     %-30b%b"
		"${c2}    .  .'''''''  .''''''.  .    %-30b%b"
		"${c2}  .'' .''''''''  .'''''''. ''.  %-30b%b"
		"${c2}  '''  '''''''    .''''''  '''  %-30b%b"
		"${c2}  .'    ........... ...    .'.  %-30b%b"
		"${c2}    ....    ''''''''.   .''.    %-30b%b"
		"${c2}    '''''.  ''''''''. .'''''    %-30b%b"
		"${c2}     '''''.  .'''''. .'''''.    %-30b%b"
		"${c2}      ..''.     .    .''..      %-30b%b"
		"${c2}            .'''''''            %-30b%b"
		"${c2}             ......             %-30b%b"
		);;

	"ubuntu")
		# Define color 
		c1=$white
		c2=$red
		c3=$yellow

		output=("\n"
		"${c2}                          ./+o+-      %b"
		"${c1}                  yyyyy- ${c2}-yyyyyy+     %b"
		"${c1}               ${c1}://+//////${c2}-yyyyyyo     %b"
		"${c3}           .++ ${c1}.:/++++++/-${c2}.+sss/\`     %b"
		"${c3}         .:++o:  ${c1}/++++++++/:--:/-     %b"
		"${c3}        o:+o+:++.${c1}\`..\`\`\`.-/oo+++++/    %b"
		"${c3}       .:+o:+o/.${c1}          \`+sssoo+/   %b"
		"${c1}  .++/+:${c3}+oo+o:\`${c1}             /sssooo.  %b"
		"${c1} /+++//+:${c3}\`oo+o${c1}               /::--:.  %b"
		"${c1} \+/+o+++${c3}\`o++o${c2}               ++////.  %b"
		"${c1}  .++.o+${c3}++oo+:\`${c2}             /dddhhh.  %b"
		"${c3}       .+.o+oo:.${c2}          \`oddhhhh+   %b"
		"${c3}        \+.++o+o\`${c2}\`-\`\`\`\`.:ohdhhhhh+    %b"
		"${c3}         \`:o+++ ${c2}\`ohhhhhhhhyo++os:     %b"
		"${c3}           .o:${c2}\`.syhhhhhhh/${c3}.oo++o\`     %b"
		"${c2}               /osyyyyyyo${c3}++ooo+++/    %b"
		"${c2}                   \`\`\`\`\` ${c3}+oo+++o\:    %b"
		"${c3}                          \`oo++.      %b"
		);;

	"debian")
		# Define color 
		c1=$white
		c2=$red

		output=("\n"
		"${c1}         _,met\$\$\$\$\$gg.          %b"
		"${c1}      ,g\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$P.       %b"
		"${c1}    ,g\$\$P\"\"       \"\"\"Y\$\$.\".     %b"
		"${c1}   ,\$\$P'              \`\$\$\$.     %b"
		"${c1}  ',\$\$P       ,ggs.     \`\$\$b:   %b"
		"${c1}  \`d\$\$'     ,\$P\"\'   ${c2}.${c1}    \$\$\$    %b"
		"${c1}   \$\$P      d\$\'     ${c2},${c1}    \$\$P    %b"
		"${c1}   \$\$:      \$\$.   ${c2}-${c1}    ,d\$\$'    %b"
		"${c1}   \$\$\;      Y\$b._   _,d\$P'     %b"
		"${c1}   Y\$\$.    ${c2}\`.${c1}\`\"Y\$\$\$\$P\"'         %b"
		"${c1}   \`\$\$b      ${c2}\"-.__              %b"
		"${c1}    \`Y\$\$                        %b"
		"${c1}     \`Y\$\$.                      %b"
		"${c1}       \`\$\$b.                    %b"
		"${c1}         \`Y\$\$b.                 %b"
		"${c1}            \`\"Y\$b._             %b"
		"${c1}                \`\"\"\"\"           %b"
		"${c1}                                %b"
		);;
	"osmc")
		# Define color
		c1=$blue
		output=("\n"
		"${c1}              -+shdmNNNNmdhs+-             %b"
		"${c1}          .+hMNho/:..``..:/ohNMh+.           %b"
		"${c1}        :hMdo.                .odMh:       %b"
		"${c1}      -dMy-                      -yMd-     %b"
		"${c1}     sMd-                          -dMs    %b"
		"${c1}    hMy       +.            .+       yMh   %b"
		"${c1}   yMy        dMs.        .sMd        yMy  %b"
		"${c1}  :Mm         dMNMs\`    \`sMNMd        \`mM: %b"
		"${c1}  yM+         dM//mNs\`\`sNm//Md         +My %b"
		"${c1}  mM-         dM:  +NNNN+  :Md         -Mm %b"
		"${c1}  mM-         dM: \`oNN+    :Md         -Mm %b"
		"${c1}  yM+         dM/+NNo\`     :Md         +My %b"
		"${c1}  :Mm\`        dMMNs\`       :Md        \`mM: %b"
		"${c1}   yMy        dMs\`         -ms        yMy  %b"
		"${c1}    hMy       +.                     yMh   %b"
		"${c1}     sMd-                          -dMs    %b"
		"${c1}      -dMy-                      -yMd-     %b"
		"${c1}        :hMdo.                .odMh:       %b"
		"${c1}          .+hMNho/:..\`\`..:/ohNMh+.         %b"
		"${c1}              -+shdmNNNNmdhs+-             %b"
		);;
	
esac

# search fo longest array
(( ${#output[@]} > ${#output_title_array[@]}  )) && index=${#output[@]}  || index=${#output_title_array[@]}

padding="${c1}                                %-30b%b"

for ((i=0; i<$index; i++));do
	if (( $i < ${#output[@]} )); then
		printf  "${output[$i]}" "${red}${output_title_array[$i]}" "${white}${output_txt_array[$i]}\n"
	else
		printf  "${padding}\n" "${red}${output_title_array[$i]}" "${white}${output_txt_array[$i]}" 
	fi
done

# reset color terminal to default
printf "$(tput sgr0)\n"

if [ -e /var/run/reboot-required ]; then
	echo "*** System restart required ***"
fi


