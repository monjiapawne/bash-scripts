#!/bin/bash
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

#=========================
# example call ./netinfo 192.168.2.4 /26

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

  base_network=$(cut -d. -f 1-${net_octs} <<<"${ip}").${network_oct}
  network_ip=$(printf "%s.0.0.0.0" "$base_network" | cut -d. -f1-4)

  base_broadcast=$(cut -d. -f 1-${net_octs} <<<"${ip}").$((network_oct + mask_interval-1))
  broadcast_ip=$(printf "%s.255.255.255.255" "$base_broadcast" | cut -d. -f1-4)

  echo " ip net addr      :  $network_ip"
  echo " ip broadcast     :  $broadcast_ip"

  last_usable_oct=$( echo "$broadcast_ip" | awk -F. '{print $4 - 1}')
  last_usable_ip=$(cut -d. -f1-3 <<<"$broadcast_ip").${last_usable_oct}

  first_usable_oct=$( echo "$network_ip" | awk -F. '{print $4 + 1}')
  first_usable_ip=$(cut -d. -f1-3 <<<"$network_ip").${first_usable_oct}

  echo " first usable ip  :  $first_usable_ip"
  echo " last usable ip   :  $last_usable_ip"
}
#===================================
netinfo_calc "$*"

