# Patch list

| No | Description | |
| --- | --- | --- |
| 1 | Enable create M2 storage pool | |
| 2 | Patch scemd to list installable disks for M2 NVMe disks | Please use patch 2, 3, 4 together |
| 3 | Patch libhwcontrol.so to show M2 NVMe disks in Storage Manager even there is no sata disks | Please use patch 2, 3, 4 together |
| 4 | Patch storage_panel.js to list M2 NVMe disks in Storage Manager | Please use this patch with 2, 3 together, valid for SA6400 64551, 64561 and 64570 |
| 5 | AME CodecPack license patches | |
| 6 | Patch storage_panel.js to list M2 NVMe disks in Storage Manager | Please use this patch with 2, 3 together, valid for SA6400 69057 |

# How to generate a patch

```
orignal=libhwcontrol.so.1
pateched=libhwcontrol.so.1.patched

diff=$(diff <(xxd "$orignal") <(xxd "$pateched"))
source=$(echo -n "$diff" | grep -oP '(?<=<).*' | awk 'NF{NF--};1' | sed -z 's/\n/\\n/g')
target=$(echo -n "$diff" | grep -oP '(?<=>).*' | awk 'NF{NF--};1' | sed -z 's/\n/\\n/g')

echo -e source: \|-\\n$source
echo -e target: \|-\\n$target
```

# How to apply a patch

```
shadow=scemd.to.patch
patch=""
echo "$patch" | xxd -r - $shadow
```

# How to use this addon

```
ramdiskpatch=/opt/rr/ramdisk-patch.sh
if [ -e /opt/arpl ]; then
  ramdiskpatch=/opt/arpl/ramdisk-patch.sh
fi

sed -i "/Reassembly ramdisk/a sed -i 's\/WithInternal=0\/WithInternal=1\/' \/tmp\/ramdisk\/linuxrc.syno.impl" ${ramdiskpatch}

cd /mnt/p3/addons

rm -rf patches patches.addon
mkdir -p patches

curl https://cdn.jim.plus/synology/arpl-addons/patches.addon -ko patches.addon
tar -xvf patches.addon -C patches
```