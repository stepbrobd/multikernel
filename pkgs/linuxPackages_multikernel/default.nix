{
  inputs,
  lib,
  callPackage,
  linuxPackagesFor,
  testers,
}:

linuxPackagesFor (
  callPackage (
    {
      buildLinux,
      fetchzip,
      fetchurl,
      ...
    }@args:
    buildLinux (
      args
      // {
        version = "6.19.0+multikernel";
        modDirVersion = "6.19.0";

        src = fetchzip {
          url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.19.tar.xz";
          hash = "sha256-Mq1NVGL7Y7NtEEPdVvskGhG6CeIscTA6YYXdwtEqFG0=";
        };

        kernelPatches = [
          {
            name = "multikernel";
            patch = fetchurl {
              url = "https://lore.kernel.org/multikernel/20251019061631.2235405-1-xiyou.wangcong@gmail.com/t.mbox.gz";
              hash = "sha256-4FVMbzgEqbPUHJnNLDIYkB7pmvmYSJo6damDZanHqbw=";
            };
            structuredExtraConfig = lib.genAttrs [
              "MULTIKERNEL"
            ] (_: lib.mkForce lib.kernel.yes);
          }
          {
            name = "build";
            patch = null;
            structuredExtraConfig = lib.genAttrs [
              "BPF"
              "BPF_JIT"
              "BPF_JIT_ALWAYS_ON"
              "BPF_KPROBE_OVERRIDE"
              "FUNCTION_ERROR_INJECTION"
              "RUST"
            ] (_: lib.mkForce lib.kernel.yes);
          }
        ];
      }
      // (args.argsOverride or { })
    )
  ) { }
)
// {
  test = testers.runNixOSTest {
    name = "multikernel";

    interactive.sshBackdoor.enable = true;

    nodes.machine = {
      imports = [ inputs.self.nixosModules.multikernel ];

      # reserved for multikernel, check with /proc/iomem
      boot.kernelParams = [
        "mem=1G"
        "mkkernel_pool=1G@1G"
      ];

      boot.kernelModules = [ "edd" ];

      virtualisation = {
        cores = 2;
        memorySize = 2048;
      };
    };

    testScript = ''
      machine.succeed("zcat /proc/config.gz | grep CONFIG_MULTIKERNEL=y")
      machine.succeed("mount -t multikernel none /sys/fs/multikernel")
      machine.succeed("ls -d /sys/fs/multikernel/")
      machine.succeed("grep 'Multikernel Memory Pool' /proc/iomem")
      machine.succeed("kerf init --cpus 1")
      machine.succeed("kerf create test --cpus 1 --memory 1GB")
      # loading and unloading currently does not work
      # machine.succeed("kerf load test --kernel $(realpath /run/current-system/kernel) --initrd $(realpath /run/current-system/initrd)")
    '';
  };
}
