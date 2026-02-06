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
mount -t multikernel none /sys/fs/multikernel; ls -d /sys/fs/multikernel/
# memory pool size set with `mem=1G` and `mkkernel_pool=1G@1G`, check /proc/cmdline
grep 'Multikernel Memory Pool' /proc/iomem
# memory pool must be allocated before running kerf init
kerf init --cpus 1
kerf create test --cpus 1 --memory 1GB
# for some reason load/unload aint working yet
kerf load test --kernel $(realpath /run/current-system/kernel) --initrd $(realpath /run/current-system/initrd)
kerf exec test
```
