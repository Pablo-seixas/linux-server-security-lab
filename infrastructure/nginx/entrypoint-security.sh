#!/bin/sh
set -eu

nft --check --file /etc/nftables.conf
nft --file /etc/nftables.conf
install -d -m 0755 /run/sshd
/usr/sbin/sshd
exec nginx -g 'daemon off;'
