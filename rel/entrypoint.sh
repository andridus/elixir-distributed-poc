#!/usr/bin/env sh
set -eu

# IP roteável da task no Swarm
MY_IP="$(ip route get 1 | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')"
[ -n "${MY_IP:-}" ] || MY_IP="$(hostname -i | awk '{print $1}')"

export MY_IP

exec /app/bin/bank start
