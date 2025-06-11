#!/bin/bash
cleanup(){
  trap - EXIT
  [[ -n "$timer_pid" ]] && kill "$timer_pid" 2>/dev/null
}
trap cleanup EXIT


#====== declarations =====================#
# colors
bl="\e[1;34m"
yw="\e[1;33m"
gr="\e[1;32m"
rd="\e[1;31m"
r="\e[0m"

# config
gl_addspace="priv" #  controlls ip generate - g_randip <priv|pub>
user="$(id -u -n)"
time_limit=60

# DEBUG
DEBUG=false

right=0
wrong=0

# answer sheet dictonary
declare -A a_dict
declare -A q_dict

#====== userspace functions ==============#

q_sel(){
  case "$1" in
    1)
      echo "q_network"
      ;;
    2)
      echo "q_firstvalidhost"
      ;;
    3)
      echo "q_lastvalidhost"
      ;;
    4)
      echo "q_broadcast"
      ;;
  esac
}

a_check(){
  clear
  a=$1
  u_a=$2
  if [[ "$a" == "$u_a" ]]; then
    right=$((right+1))
    streak=$((streak+1))
    echo -e -n "${gr}[✓] Correct! ${right}/$((right+wrong))${r}"
    if [[ $streak -eq 5 ]]; then
      echo -e -n " ~${bl}5 in a row!${r}"
    fi
  else
    wrong=$((wrong+1))
    streak=0
    echo -e -n "${rd}[x] Incorrect! ${right}/$((right+wrong))${r}\nAnswer: ${yw}${a}${r}"
  fi
  echo -e "\n"
}

p_quesdict(){
  echo "ip_addr            : ${q_dict["ip_addr"]}"
  echo "prefix_cidr        : ${q_dict["prefix_cidr"]}"
  echo "ip_addr_maskremoved: ${q_dict["ip_addr_maskremoved"]}"
}

p_ansdict(){
  echo -e "printing answer dictionary\n-----------------------"
  echo "network  : ${a_dict["network"]}"
  echo "broadcast: ${a_dict["broadcast"]}"
  echo "first    : ${a_dict["first"]}"
  echo "last     : ${a_dict["last"]}"
}

#====== calculation functions =========#
#!/bin/bash
#=== helper ====#
dotted_to_cidr(){
  local cidr=$1
  count=0
  tmp=$1
  while [[ $tmp == *255* ]]; do
    tmp="${tmp/255/}"
    ((count++))
  done
  cidr="${cidr//255./}"
  cidr="${cidr//.0/}"
  n=$((256-cidr))
  cidr_oct=0
  while (( n > 1 )); do
    n=$((n >> 1))
    ((cidr_oct++))
  done
  echo "$(( (8 - cidr_oct) + (count * 8) ))"
}

#======= #
# examples ----
# netinfo_calc 192.168.2.4 /26
# netinfo_calc 10.0.30.52 255.255.255.240

netinfo_calc(){
  input="$*"
  ip=$(echo "$input" | awk -F'[ /]+' '{print $1}')
  cidr=$(echo "$input" | awk -F'[ /]+' '{print $2}')

  if [[ $cidr == *.* ]]; then
    cidr=$(dotted_to_cidr "$cidr")
  fi

  local net_octs=$(($cidr / 8))
  local ip_last_oct=$(cut -d. -f "$((net_octs + 1))" <<<"${ip}")


  mask_net_bits=$(( (($cidr) - ($net_octs* 8)) ))
  mask_dec=$(( 256 - 2**(8 - $mask_net_bits) ))
  network_oct=$(printf "%d\n" "$(echo "$((ip_last_oct & mask_dec))" | bc)")
  mask_interval="$((256-mask_dec))"


  network_cut=$(cut -d. -f 1-${net_octs} <<<"${ip}")
  q_dict["ip_addr_maskremoved"]="$network_cut."
  base_network=$(cut -d. -f 1-${net_octs} <<<"${ip}").${network_oct}
  network_ip=$(printf "%s.0.0.0.0" "$base_network" | cut -d. -f1-4)

  base_broadcast=$(cut -d. -f 1-${net_octs} <<<"${ip}").$((network_oct + mask_interval-1))
  broadcast_ip=$(printf "%s.255.255.255.255" "$base_broadcast" | cut -d. -f1-4)

  $DEBUG && echo -e "${yw}DEBUG: netinfo_calc - ip net addr      :  $network_ip${r}"
  $DEBUG && echo -e "${yw}DEBUG: netinfo_calc - ip broadcast     :  $broadcast_ip${r}"

  last_usable_oct=$( echo "$broadcast_ip" | awk -F. '{print $4 - 1}')
  last_usable_ip=$(cut -d. -f1-3 <<<"$broadcast_ip").${last_usable_oct}

  first_usable_oct=$( echo "$network_ip" | awk -F. '{print $4 + 1}')
  first_usable_ip=$(cut -d. -f1-3 <<<"$network_ip").${first_usable_oct}

  $DEBUG && echo -e "${yw}DEBUG: netinfo_calc - first usable ip  :  $first_usable_ip${r}"
  $DEBUG && echo -e "${yw}DEBUG: netinfo_calc - last usable ip   :  $last_usable_ip${r}"

  a_dict["network"]="$network_ip"
  a_dict["broadcast"]="$broadcast_ip"
  a_dict["first"]="$first_usable_ip"
  a_dict["last"]="$last_usable_ip"
}
#===================================

#====== helper functions ==============#
#random prefix between 8-31
g_octclass(){
  # $1 = oct number 1-4
  [[ "$1" == "1"  ]] && echo "10."
  [[ "$1" == "2"  ]] && echo "172.16."
  [[ "$1" == "3"  ]] && echo "192.168.2."
}

g_randprefix(){
  prefix="$((RANDOM % 23 + 8 ))"
  octs=$(( ($prefix) / 8 ))
  echo $prefix $octs
}

g_randip(){
  local prefix=$1
  local octs=$2
  local addspace=$3
  local ip=""

  # if private addr is selected use rfc1918 prefix' and remove from total random
  if [[ "$addspace" == "priv" ]]; then
    ip+=$(g_octclass $octs)
    local randocts=$(( 4 - ($octs) ))
  elif [[ "$addspace" == "pub" ]]; then
    local randocts=4
  fi

  for((i = 0 ; i < $randocts ; i++)); do
    ip+="$((RANDOM % 255))."
  done

  ip="${ip::-1}"
  q_dict["ip_addr"]="$ip"
  q_dict["prefix_cidr"]="$prefix"
}

g_ip_prefix_calc (){
  # generating ip
  read p o < <(g_randprefix)
  g_randip $p $o $gl_addspace
  # calculating answer
  netinfo_calc "${q_dict["ip_addr"]}" "${q_dict["prefix_cidr"]}"
}

#====== questions =====================

q_network(){
  g_ip_prefix_calc
  local q="Network IP"
  local q_info="${bl}${q_dict["ip_addr"]}${r} ${gr}/${q_dict["prefix_cidr"]}${r}"
  local a="${a_dict["network"]}"
  local a_prefix="${q_dict["ip_addr_maskremoved"]}"
  ask_q "$q" "$q_info" "$a" "$a_prefix"
}

q_firstvalidhost(){
  g_ip_prefix_calc
  local q="First Usable IP"
  local q_info="${bl}${q_dict["ip_addr"]}${r} ${gr}/${q_dict["prefix_cidr"]}${r}"
  local a="${a_dict["first"]}"
  local a_prefix="${q_dict["ip_addr_maskremoved"]}"
  ask_q "$q" "$q_info" "$a" "$a_prefix"
}

q_lastvalidhost(){
  g_ip_prefix_calc
  local q="Last Usable IP"
  local q_info="${bl}${q_dict["ip_addr"]}${r} ${gr}/${q_dict["prefix_cidr"]}${r}"
  local a="${a_dict["last"]}"
  local a_prefix="${q_dict["ip_addr_maskremoved"]}"
  ask_q "$q" "$q_info" "$a" "$a_prefix"
}

q_broadcast(){
  g_ip_prefix_calc
  local q="Broadcast IP"
  local q_info="${bl}${q_dict["ip_addr"]}${r} ${gr}/${q_dict["prefix_cidr"]}${r}"
  local a="${a_dict["broadcast"]}"
  local a_prefix="${q_dict["ip_addr_maskremoved"]}"
  ask_q "$q" "$q_info" "$a" "$a_prefix"
}

q_range(){
  g_ip_prefix_calc
  local q="Usable IP Range"
  local q_info="${bl}${q_dict["ip_addr"]}${r} ${gr}/${q_dict["prefix_cidr"]}${r}"
  local a="${a_dict["broadcast"]}"
  local a_prefix="${q_dict["ip_addr_maskremoved"]}"
  ask_q "$q" "$q_info" "$a" "$a_prefix"
}

#== question funciton
ask_q(){
  local q=$1
  local q_info=$2
  local a=$3
  local a_prefix=$4

  echo -e "time remaining: ${bl}$((end_time-SECONDS))${r}"
  echo -e "$q_info"
  echo -e "${q}\n------------"

  read -p "${a_prefix}" ans

  kill $timer_pid 2>/dev/null
  wait $timer_pid 2>/dev/null
  echo -ne "\033[1A\033[2K"  # Clear final timer line

  ans=$a_prefix$ans
  $DEBUG && echo -e "${yw}DEBUG: ask_q - user_ans: $ans${r}"
  a_check "$a" "$ans"
}


#====== prompt / question loop =======

game_loop(){
  # question selection
  q_rand=$((RANDOM % 4 + 1))
  q_type=$(q_sel "$q_rand")
  # call question - can set to question name statically instead
  $q_type
}

startmenu() {
  clear
  while true; do
    echo -e "Subnetting Practice\n-------------"
    echo "Options:"
    echo "1: Start Normal Game"
    echo "2: Start Custom Game"
    read -p ":" option
    case $option in
      1)
        echo "normal"
        break
      ;;
      2)
        echo "custom"
        while [[ "$choice" != "priv" && "$choice" != "pub" ]]; do
          read -p "private or public ips (priv|pub): " choice
        done
        read -p "time limit (seconds): " time_limit
        gl_addspace=$choice
        break
      ;;
      *)
        echo "error"
      ;;
    esac
  done
  clear
}

p_results(){
  clear
  echo -e "${yw}[!] Time's up!${r}"
  echo -e "${bl}-----------------${r}"
  echo "User      : $user"
  echo -e "Correct   : ${gr}${right}${r}"
  echo -e "Incorrect : ${rd}${wrong}${r}"
  echo -e "${bl}-----------------${r}"
  read -p "Play again {y/n}: " replay
}

main(){
  startmenu
  while [[ replay != "n" ]]; do
    end_time=$((SECONDS + $time_limit))
    while [[ $SECONDS -lt $end_time ]]; do
      game_loop
    done
  p_results
  done
}

main
