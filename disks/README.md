## NVMe Examples

### 1

* /sys/block

```shell
# ls -alh /sys/block
../devices/pci0000:00/0000:00:03.0/nvme/nvme0/nvme0n1
```

* dts

```
	nvme_slot@1 {
		pcie_root = "00:03.0";
		port_type = "ssdcache";
	};
```

### 2

* /sys/block

```shell
# ls -alh /sys/block
nvme1n1 -> ../devices/pci0000:00/0000:00:1e.0/0000:05:01.0/0000:06:1c.0/nvme/nvme0/nvme0n1
```

* dts

```
	nvme_slot@1 {
		pcie_root = "00:1e.0,01.0,1c.0";
		port_type = "ssdcache";
	};
```

## Sata Examples

* /sys/block

```shell
# ls -alh /sys/block
sata1 -> ../devices/pci0000:00/0000:00:1e.0/0000:05:01.0/0000:06:07.0/ata7/host6/target6:0:0/6:0:0:0/block/sata1
```

* dts

```
	internal_slot@1 {
		protocol_type = "sata";

		ahci {
			pcie_root = "0000:00:1e.0,01.0,07.0";
			ata_port = <0x00>;
		};
	};
```