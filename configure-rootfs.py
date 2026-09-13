#!/usr/bin/env python3
"""Configurar una raíz Debian 12 ARM64 de construcción, nunca el anfitrión."""
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
assert root != pathlib.Path('/') and (root / 'etc/debian_version').exists()

def put(name, data, mode=0o644):
    path = root / name.lstrip('/')
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(data)
    path.chmod(mode)

put('/etc/hostname', 'debian-arm64-min\n')
put('/etc/hosts', '127.0.0.1 localhost\n127.0.1.1 debian-arm64-min\n::1 localhost ip6-localhost\n')
put('/etc/fstab', '/dev/vda / ext4 defaults,noatime 0 1\n')
resolv = root / 'etc/resolv.conf'
if resolv.is_symlink():
    resolv.unlink()
put('/etc/resolv.conf', 'nameserver 10.0.2.3\n')
put('/etc/systemd/network/20-qemu.network', '[Match]\nName=en* eth*\n\n[Network]\nDHCP=ipv4\nIPv6AcceptRA=yes\n')
put('/etc/systemd/system.conf.d/90-tcg.conf', '[Manager]\nDefaultTimeoutStartSec=300s\nDefaultDeviceTimeoutSec=300s\nDefaultTimeoutStopSec=120s\nManagerEnvironment=SYSTEMD_BUS_TIMEOUT=300\nDefaultEnvironment=SYSTEMD_BUS_TIMEOUT=300\n')
put('/etc/systemd/journald.conf.d/90-minimal.conf', '[Journal]\nStorage=volatile\nRuntimeMaxUse=8M\n')
put('/etc/ssh/sshd_config.d/10-vm.conf', 'PermitRootLogin prohibit-password\nPasswordAuthentication no\nKbdInteractiveAuthentication no\nHostKey /etc/ssh/ssh_host_ed25519_key\n')
put('/usr/local/sbin/vm-prepare', '''#!/bin/sh
set -eu
/sbin/resize2fs /dev/vda
modprobe qemu_fw_cfg
mkdir -p /root/.ssh
chmod 700 /root/.ssh
cat /sys/firmware/qemu_fw_cfg/by_name/opt/vm/ssh-key/raw > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
ssh-keygen -lf /root/.ssh/authorized_keys >/dev/null
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -q -t ed25519 -N '' -f /etc/ssh/ssh_host_ed25519_key
fi
''', 0o755)
put('/etc/systemd/system/vm-prepare.service', '[Unit]\nDescription=Grow root filesystem and configure per-device SSH keys\nAfter=local-fs.target systemd-udev-trigger.service\nBefore=ssh.service\n\n[Service]\nType=oneshot\nExecStart=/usr/local/sbin/vm-prepare\nRemainAfterExit=yes\nTimeoutStartSec=300\n\n[Install]\nWantedBy=multi-user.target\n')
put('/etc/systemd/system/ssh.service.d/10-vm.conf', '[Unit]\nRequires=vm-prepare.service\nAfter=vm-prepare.service\n')
for name in ['systemd-networkd', 'ssh', 'vm-prepare']:
    unit = 'etc/systemd/system/multi-user.target.wants/' + name + '.service'
    path = root / unit
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.is_symlink():
        target = '/etc/systemd/system/' if name == 'vm-prepare' else '/lib/systemd/system/'
        path.symlink_to(target + name + '.service')
for path in (root / 'etc/ssh').glob('ssh_host_*'):
    path.unlink()
put('/etc/machine-id', '')
for name in ['.dockerenv', 'run/.containerenv', 'run/systemd/container',
             'var/lib/dbus/machine-id', 'usr/sbin/policy-rc.d']:
    path = root / name
    if path.exists() or path.is_symlink():
        path.unlink()
