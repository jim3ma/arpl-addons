#!/usr/bin/env ash

if [ "${1}" = "early" ]; then
  if grep -qF /opt/etc/profile /etc/profile; then
	  echo "Confirmed: Entware Profile in Global Profile"
  else
	  echo "Adding: Entware Profile in Global Profile"
    cat >> /etc/profile <<"EOF"

# Load Entware Profile
[ -r "/opt/etc/profile" ] && . /opt/etc/profile
EOF
  fi
fi

if [ "${1}" = "late" ]; then
  echo "Copying EntWare to HD"
  if [ -e /tmpRoot/opt ]; then
    echo /tmpRoot/opt exists, skip copy EntWare files
    exit 0
  fi
  cp -vfr /opt /tmpRoot/opt
  if grep -qF /opt/etc/profile /tmpRoot/etc/profile; then
	  echo "Confirmed: Entware Profile in Global Profile"
  else
	  echo "Adding: Entware Profile in Global Profile"
    cat >> /tmpRoot/etc/profile <<"EOF"

# Load Entware Profile
[ -r "/opt/etc/profile" ] && . /opt/etc/profile
EOF
  fi
fi
