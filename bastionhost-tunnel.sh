#!/bin/bash
# How to set up Tunnel
# generate keys on host
# ssh-keygen -t ed25519
# copy pub key to pi
# ssh-copy-id sys1@1.2.3.4
#===== COLORS =====#
R="\e[1;31m"
B="\e[34m"
G="\e[1;32m"
Y="\e[1;33m"
C="\e[0m"

#==== Config =====#
tunpidf="/tmp/tun.pid"
remote="sys1@10.0.20.99"
routes="10.0.10.0/24"
log="/tmp/bhtun.log"

command -v sshuttle &> /dev/null || {
  echo -e "${R}[!] sshuttle not available${C}\n${Y}Install with apt install sshuttle${C}"; 
  exit 1;
}

case "$1" in
  on)
    if [ -f "$tunpidf" ] && kill -0 "$(cat "$tunpidf")" 2>/dev/null; then
      echo -e "tunnel is already running ${G}(PID $(cat $tunpidf)${C}"
    else
      echo "[i] starting tunnel"
      sshuttle --daemon \
        --pidfile="$tunpidf" \
        --ssh-cmd "ssh -o StrictHostKeyChecking=no" \
        -r "$remote" $routes >> "$log" 2>&1
      PID=$(cat "$tunpidf")
      remoteip=$(cut -d@ -f2 <<<$remote)
      echo -e "[✓] ${G}tunnel started${C}\n----------------\nPID: $PID\n$remoteip -> $routes"
    fi
    ;;
  off)
    if [ -f "$tunpidf" ]; then
      PID=$(cat "$tunpidf")
      echo "[i] stopping tunnel (PID $PID)..."
      kill "$PID" && rm -f "$tunpidf"
      echo -e "${R}[!] tunnel stopped${C}"
    else
      echo "[i] tunnel is not running"
    fi
    ;;
  status)
      echo "[i] checking tunnel status"
    if [ -f "$tunpidf" ] && kill -0 "$(cat "$tunpidf")" 2>/dev/null; then
      PID=$(cat "$tunpidf")
      echo -e "${G}[i] tunnel is running (PID $PID)${C}"
    else
      echo -e "${Y}[i] tunnel is not running${Y}"
    fi
    ;;
  *)
    echo "usage bhtun {on|off|status}"
    ;;
esac
