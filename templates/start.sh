#!/bin/sh

set -Eeuo pipefail
trap "exit" INT

function start () {
  for i; do
    sudo virsh start "$i" || true
  done
}

function wait_for_ip () {
  echo "Waiting for $1 to come online..."
  while ! ping -n -c4 -i.2 $2 -q &>/dev/null; do
    sleep 1
  done
}

%{for host, ip in others~}
start "${host}"
wait_for_ip "${host}" "${ip}"
%{endfor~}

%{for host, ip in masters~}
start "${host}"
%{endfor~}

%{for host, ip in workers~}
start "${host}"
%{endfor~}
