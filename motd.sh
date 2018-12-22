#!/bin/bash

clear

color() {
  echo "\e[$1m$2\e[0m"
}

extend() {
  local str="$1"
  spaces=$(( 60-${#1} ))
  while [ $spaces -gt 0 ]; do
    str="$str "
    spaces=$(( spaces-1 ))
  done
  echo "$str"
}

center() {
  local str="$1"
  spacesLeft=$(( (78-${#1})/2 ))
  spacesRight=$(( 78-spacesLeft-${#1} ))
  while [ $spacesLeft -gt 0 ]; do
    str=" $str"
    spacesLeft=$(( spacesLeft-1 ))
  done

  while [ $spacesRight -gt 0 ]; do
    str="$str "
    spacesRight=$(( spacesRight-1 ))
  done

  echo "$str"
}

sec2time() {
  local input=$1

  if [ "$input" -lt 60 ]; then
    echo "$input seconds"
  else
    ((days=input/86400))
    ((input=input%86400))
    ((hours=input/3600))
    ((input=input%3600))
    ((mins=input/60))

    local daysPlural="s"
    local hoursPlural="s"
    local minsPlural="s"

    if [ $days -eq 1 ]; then
      daysPlural=""
    fi

    if [ $hours -eq 1 ]; then
      hoursPlural=""
    fi

    if [ $mins -eq 1 ]; then
      minsPlural=""
    fi

    echo "$days day$daysPlural, $hours hour$hoursPlural, $mins minute$minsPlural"
  fi
}

getInterfaces() {
  # Capture Interfaces
  interfaces="$(ip link show | awk -F: '$1>0 {print $2}' | grep -v lo)"

  # Using captured interfaces loop through them and capture:
  # link state and ip address
  # Only if IP address is defined
  # shellcheck disable=SC2068
  ips="$(for int in ${interfaces[@]};
    do
      state="$(ip link show "$int" | awk '{print $9}')"
      ip_addr="$(ip -4 add show "$int" | grep inet | awk '{print $2}'| awk -F/ '{print $1}')"
      if [ -n "$ip_addr" ]; then
        echo "[$int/$state]:" "$ip_addr"
      fi
    done
  )"
}

# Measure DNS response time
measureDNSResponse() {
  if type dig > /dev/null 2>&1; then
    dns_response="$(dig google.com | grep 'Query time:' | awk '{print $4,$5}')"
  else
    dns_response="dig command not found, please install"
  fi
}

# Capture DNS Servers
getDNSServer() {
  dns_servers="$(grep nameserver /etc/resolv.conf | awk '{print $2}' | tr '\r\n' ' ')($dns_response)"
}

borderColor=35
headerLeafColor=32
headerRaspberryColor=31
greetingsColor=36
statsLabelColor=33

borderLine="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
borderTopLine=$(color $borderColor "┏$borderLine┓")
borderBottomLine=$(color $borderColor "┗$borderLine┛")
borderBar=$(color $borderColor "┃")
borderEmptyLine="$borderBar                                                                              $borderBar"

# Header
header="$borderTopLine\n$borderEmptyLine\n"
header="$header$borderBar$(color $headerLeafColor "          .~~.   .~~.                                                         ")$borderBar\n"
header="$header$borderBar$(color $headerLeafColor "         '. \ ' ' / .'                                                        ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "          .~ .~~~..~.                      _                          _       ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "         : .~.'~'.~. :     ___ ___ ___ ___| |_ ___ ___ ___ _ _    ___|_|      ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "        ~ (   ) (   ) ~   |  _| .'|_ -| . | . | -_|  _|  _| | |  | . | |      ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "       ( : '~'.~.'~' : )  |_| |__,|___|  _|___|___|_| |_| |_  |  |  _|_|      ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "        ~ .~ (   ) ~. ~               |_|                 |___|  |_|          ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "         (  : '~' :  )                                                        ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "          '~ .~~~. ~'                                                         ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "              '~'                                                             ")$borderBar"

me=$(whoami)

# Greetings
greetings="$borderBar$(color $greetingsColor "$(center "Welcome back, $me!")")$borderBar\n"
greetings="$greetings$borderBar$(color $greetingsColor "$(center "$(date +"%A, %d %B %Y, %T")")")$borderBar"

# System information
read -r loginFrom loginIP loginDate <<< "$(last "$me" --time-format iso -2 | awk 'NR==2 { print $2,$3,$4 }')"

# TTY login
if [[ $loginDate == - ]]; then
  loginDate=$loginIP
  loginIP=$loginFrom
fi

if [[ $loginDate == *T* ]]; then
  login="$(date -d "$loginDate" +"%A, %d %B %Y, %T") ($loginIP)"
else
  # Not enough logins
  login="None"
fi

labelHostname="$(extend "$(hostname)")"
labelHostname="$borderBar  $(color $statsLabelColor "Hostname......:") $labelHostname$borderBar"

labelLogin="$(extend "$login")"
labelLogin="$borderBar  $(color $statsLabelColor "Last Login....:") $labelLogin$borderBar"

uptime="$(sec2time "$(cut -d "." -f 1 /proc/uptime)")"
uptime="$uptime ($(date -d "@""$(grep btime /proc/stat | cut -d " " -f 2)" +"%d-%m-%Y %H:%M:%S"))"

labelUptime="$(extend "$uptime")"
labelUptime="$borderBar  $(color $statsLabelColor "Uptime........:") $labelUptime$borderBar"

labelRAM="$(extend "$(free -m | awk 'NR==2 { printf "Total: %sMB | Used: %sMB  | Free: %sMB",$2,$3,$4; }')")"
labelRAM="$borderBar  $(color $statsLabelColor "RAM...........:") $labelRAM$borderBar"

labelDisk="$(extend "$(df -h ~ | awk 'NR==2 { printf "Total:  %sB | Used: %sB | Free: %sB",$2,$3,$4; }')")"
labelDisk="$borderBar  $(color $statsLabelColor "Disk space....:") $labelDisk$borderBar"

labelTemperature="$(extend "$(/opt/vc/bin/vcgencmd measure_temp | cut -c "6-9")ºC")"
labelTemperature="$borderBar  $(color $statsLabelColor "Temperature...:") $labelTemperature$borderBar"

getInterfaces
labelIPs="$(extend "$ips")"
labelIPs="$borderBar  $(color $statsLabelColor "Local IP(s)...:") $labelIPs$borderBar"

measureDNSResponse
getDNSServer
labelDNS="$(extend "$dns_servers")"
labelDNS="$borderBar  $(color $statsLabelColor "DNS Server....:") $labelDNS$borderBar"

stats="$labelHostname\n$labelIPs\n$labelDNS\n$borderEmptyLine\n$labelLogin\n$labelUptime\n$borderEmptyLine\n$labelRAM\n$labelDisk\n$labelTemperature"

# Print motd
echo -e "$header\n$borderEmptyLine\n$greetings\n$borderEmptyLine\n$stats\n$borderEmptyLine\n$borderBottomLine"
