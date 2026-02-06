{
  inputs,
  lib,
  callPackage,
  linuxPackagesFor,
  testers,
}:

linuxPackagesFor (
  callPackage (
    { buildLinux, fetchFromGitHub, ... }@args:
    buildLinux (
      args
      // {
        version = "6.19.0-rc5+multikernel";
        modDirVersion = "6.19.0-rc5";

        src = fetchFromGitHub {
          owner = "multikernel";
          repo = "linux";
          rev = "483192c3889ca357f8b9cdf5342e747dc456b8f1";
          hash = "sha256-w6yAqoqGK+Yr37v+ciaFP7djl7jw6wW5MNJseRgmTnE=";
        };

        structuredExtraConfig = lib.genAttrs [
          "BPF"
          "BPF_JIT"
          "BPF_JIT_ALWAYS_ON"
          "BPF_KPROBE_OVERRIDE"
          "FUNCTION_ERROR_INJECTION"
          "MULTIKERNEL"
        ] (_: lib.mkForce lib.kernel.yes);
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
