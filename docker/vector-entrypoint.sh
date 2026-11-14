#!/bin/sh
set -eu

lab_user="${LAB_TELNET_USER}"
lab_password="${LAB_TELNET_PASSWORD}"

if ! id "$lab_user" >/dev/null 2>&1; then
  adduser -D -s /bin/ash "$lab_user"
fi

printf '%s:%s\n' "$lab_user" "$lab_password" | chpasswd

if [ -S /var/run/docker.sock ]; then
  socket_gid="$(stat -c '%g' /var/run/docker.sock)"
  socket_group="$(awk -F: -v gid="$socket_gid" '$3 == gid { print $1; exit }' /etc/group)"

  if [ -z "$socket_group" ]; then
    socket_group="docker-host"
    addgroup -g "$socket_gid" "$socket_group"
  fi

  addgroup "$lab_user" "$socket_group" >/dev/null 2>&1 || true
fi

telnetd -p 23 -l /bin/login

exec vector --config /etc/vector/vector.yaml
