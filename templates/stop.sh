#!/bin/sh

set -Eeuo pipefail
trap "exit" INT

function stop_group () {
  for i; do
    sudo virsh shutdown "$i" --mode=agent || true
  done

  for i; do
    echo "Waiting for $i to shutdown..."
    while sudo virsh list --name | egrep -q "^$i\$"; do
      sleep 1
      continue
    done
  done
}

stop_group %{for host in workers}"${host}" %{endfor}
stop_group %{for host in masters}"${host}" %{endfor}
stop_group "${lb}" "${storage}"
