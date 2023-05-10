# Patch list

| No | Description | |
| --- | --- | --- |
| 1 | Enable create M2 storage pool | |
| 2 | Patch scemd to list installable disks for M2 NVMe disks | Please use patch 2, 3, 4 together |
| 3 | Patch libhwcontrol.so to show M2 NVMe disks in Storage Manager even there is no sata disks | Please use patch 2, 3, 4 together |
| 4 | Patch storage_panel.js to list M2 NVMe disks in Storage Manager | Please use patch 2, 3, 4 together |

# How to generate a patch

```
orignal=libhwcontrol.so.1
pateched=libhwcontrol.so.1.patched
  
diff=$(diff <(xxd "$orignal") <(xxd "$pateched"))
source=$(echo -n "$diff" | grep -oP '(?<=<).*' | awk 'NF{NF--};1' | sed -z 's/\n/\\n/g')
target=$(echo -n "$diff" | grep -oP '(?<=>).*' | awk 'NF{NF--};1' | sed -z 's/\n/\\n/g')

echo "    source: \"$source\""
echo "    target: \"$target\""
```

# How to apply a patch

```
shadow=scemd.to.patch
patch=""
echo "$patch" | xxd -r - $shadow
```