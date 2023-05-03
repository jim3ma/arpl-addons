#!/usr/bin/env ash

function saveLogs() {
  modprobe vfat
  echo 1 > /proc/sys/kernel/syno_install_flag
  mount /dev/synoboot1 /mnt
  mkdir -p /mnt/logs/jr
  cp /var/log/* /mnt/logs/jr
  dmesg > /mnt/logs/jr/dmesg
  umount /mnt
}

if [ "${1}" = "early" ]; then
  echo "Starting ttyd..."
  /usr/sbin/ttyd /usr/bin/ash -l &
elif [ "${1}" = "jrExit" ]; then
  saveLogs
elif [ "${1}" = "rcExit" ]; then
  saveLogs
elif [ "${1}" = "late" ]; then
  echo "Killing ttyd..."
  /usr/bin/killall ttyd
  echo "Copying utils"
  cp -vf /usr/bin/dtc    /tmpRoot/usr/bin/
  cp -vf /usr/bin/lsscsi /tmpRoot/usr/bin/
  cp -vf /usr/bin/nano   /tmpRoot/usr/bin/
  cp -vf /usr/bin/strace /tmpRoot/usr/bin/
  cp -vf /usr/bin/lsof   /tmpRoot/usr/bin/
  cp -vf /usr/sbin/ttyd  /tmpRoot/usr/sbin/
  ln -sf /usr/bin/kmod   /tmpRoot/usr/sbin/modinfo
  saveLogs
  DEST="/tmpRoot/lib/systemd/system/savelogs.service"

  # Save logs
  echo "[Unit]"                                                                  >${DEST}
  echo "Description=ARPL save logs for debug"                                   >>${DEST}
  echo                                                                          >>${DEST}
  echo "[Service]"                                                              >>${DEST}
  echo "Type=oneshot"                                                           >>${DEST}
  echo "RemainAfterExit=true"                                                   >>${DEST}
  echo "ExecStop=/sbin/modprobe vfat"                                           >>${DEST}
  echo "ExecStop=/bin/sh -c '/bin/echo 1 > /proc/sys/kernel/syno_install_flag'" >>${DEST}
  echo "ExecStop=/bin/mount /dev/synoboot1 /mnt"                                >>${DEST}
  echo "ExecStop=/bin/mkdir -p /mnt/logs/dsm"                                   >>${DEST}
  echo "ExecStop=/bin/sh -c '/bin/cp /var/log/* /mnt/logs/dsm || true'"         >>${DEST}
  echo "ExecStop=/bin/sh -c '/bin/dmesg > /mnt/logs/dsm/dmesg'"                 >>${DEST}
  echo "ExecStop=/bin/sh -c '/bin/journalctl > /mnt/logs/dsm/journalctl.log'"   >>${DEST}
  echo "ExecStop=/bin/umount /mnt"                                              >>${DEST}
  echo                                                                          >>${DEST}
  echo "[Install]"                                                              >>${DEST}
  echo "WantedBy=multi-user.target"                                             >>${DEST}

  mkdir -p /tmpRoot/etc/systemd/system/multi-user.target.wants
  ln -sf /lib/systemd/system/savelogs.service /tmpRoot/lib/systemd/system/multi-user.target.wants/savelogs.service

  # Change root password for debug
  DEST="/tmpRoot/usr/lib/systemd/system/change-root-password.service"
  echo "[Unit]"                                                                  >${DEST}
  echo "Description=Change root password for debug"                             >>${DEST}
  echo "After=multi-user.target"                                                >>${DEST}
  echo "IgnoreOnIsolate=true"                                                   >>${DEST}
  echo                                                                          >>${DEST}
  echo "[Service]"                                                              >>${DEST}
  echo "Type=oneshot"                                                           >>${DEST}
  echo "RemainAfterExit=true"                                                   >>${DEST}
  echo "ExecStart=/usr/syno/sbin/synouser --setpw root sa6400"                  >>${DEST}
  echo                                                                          >>${DEST}
  echo "[Install]"                                                              >>${DEST}
  echo "WantedBy=multi-user.target"                                             >>${DEST}

  if [ -f /tmpRoot/.disable.change-root-password.service]; then
    echo skip to change root password
    rm -f /tmpRoot/etc/systemd/system/multi-user.target.wants/change-root-password.service
  else
    ln -sf /usr/lib/systemd/system/change-root-password.service /tmpRoot/etc/systemd/system/multi-user.target.wants/change-root-password.service
  fi
fi
