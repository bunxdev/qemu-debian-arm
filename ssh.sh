#!/bin/sh
set -eu
vm_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec ssh -i "$vm_dir/id_ed25519" -p "${VM_SSH_PORT:-2222}" \
    -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=30 \
    -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
    -o ControlMaster=auto -o ControlPersist=120 -o ControlPath="$vm_dir/ssh.sock" \
    -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$vm_dir/known_hosts" \
    root@127.0.0.1 "$@"
