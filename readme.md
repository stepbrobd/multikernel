# NixOS multikernel test

Read these:

- <https://lore.kernel.org/multikernel/>
- <https://github.com/multikernel/linux>
- <https://github.com/multikernel/kexec-tools>
- <https://github.com/multikernel/kerf>

```sh
# driver
nom build .#checks.x86_64-linux.default.driverInteractive; ./result/bin/nixos-test-driver
# in VM
zcat /proc/config.gz | grep CONFIG_MULTIKERNEL=y
mountpoint /sys/fs/multikernel # mounted by the nixos module
kerf init --cpus=2-3 --memory=1GB
grep 'Multikernel Memory Pool' /proc/iomem
kerf create test --cpus=2-3 --memory=512MB
kerf load test --kernel /run/current-system/kernel --initrd /etc/spawn-initrd --cmdline console=mktty0
kerf exec test
kerf console test
kerf kill test
kerf unload test
kerf delete test
kerf init --cpus=none --memory=none
```
