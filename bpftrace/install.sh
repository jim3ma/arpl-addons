#!/usr/bin/env ash

if [ "${1}" = "late" ]; then
  echo "Copying bpftrace to HD"
  cp -vf /usr/sbin/bpftrace /tmpRoot/usr/sbin/bpftrace
  cp -vf /usr/sbin/*.bt /tmpRoot/usr/sbin/
fi
