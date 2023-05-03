#!/usr/bin/env ash

if [ "${1}" = "late" ]; then
  echo "Copying bpftrace to HD"
  cp -vf /usr/sbin/bpftrace /tmpRoot/usr/sbin/bpftrace
fi
