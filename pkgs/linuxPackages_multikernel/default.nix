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
        version = "7.0.0-mk2";
        modDirVersion = "7.0.0-mk2";

        src = fetchFromGitHub {
          owner = "multikernel";
          repo = "linux";
          rev = "ed3e74498f402cbe55210a9afdd8e9b0629c7714";
          hash = "sha256-fwPsQ23U01j9ngBQ0y23oRrxRTa6q12phvjFLP1LGOQ=";
        };

        structuredExtraConfig =
          lib.genAttrs [
            "BPF"
            "BPF_JIT"
            "BPF_JIT_ALWAYS_ON"
            "BPF_KPROBE_OVERRIDE"
            "FUNCTION_ERROR_INJECTION"
            "MKTTY"
            "MULTIKERNEL"
            "RUST"
          ] (_: lib.mkForce lib.kernel.yes)
          // {
            # off until https://github.com/multikernel/linux/issues/38 is addressed
            MULTIKERNEL_VSOCKETS = lib.kernel.no;
          };
      }
      // (args.argsOverride or { })
    )
  ) { }
)
// {
  test = testers.runNixOSTest {
    name = "multikernel";

    interactive.sshBackdoor.enable = true;

    nodes.machine =
      { pkgs, ... }:
      {
        imports = [ inputs.self.nixosModules.multikernel ];

        environment.etc."spawn-initrd".source =
          let
            init = pkgs.writeText "spawn-init" ''
              #!/bin/sh
              /bin/busybox mount -t devtmpfs devtmpfs /dev
              while :; do
                echo multikernel-spawn-alive > /dev/console
                /bin/busybox sleep 2
              done
            '';
          in
          pkgs.runCommand "spawn-initrd"
            {
              nativeBuildInputs = with pkgs; [ cpio ];
            }
            ''
              mkdir -p root/bin root/dev
              cp ${pkgs.pkgsStatic.busybox}/bin/busybox root/bin/busybox
              ln -s busybox root/bin/sh
              install -m755 ${init} root/init
              (cd root && find . -print0 | cpio -o0 -H newc --quiet) | gzip > $out
            '';

        # the pool is a runtime contiguous allocation
        # taken from ZONE_MOVABLE give it a movable zone
        boot.kernelParams = [ "movablecore=4G" ];

        virtualisation = {
          cores = 4;
          memorySize = 8192;
        };
      };

    testScript = ''
      machine.wait_for_unit("multi-user.target")

      with subtest("kernel provides multikernel support"):
          machine.succeed("zcat /proc/config.gz | grep CONFIG_MULTIKERNEL=y")
          machine.succeed("zcat /proc/config.gz | grep CONFIG_MKTTY=y")
          machine.succeed("mountpoint -q /sys/fs/multikernel")
          # check above linked issue
          # machine.succeed("modprobe mk_transport")

      with subtest("kerf init reserves pool cpus and memory"):
          machine.succeed("kerf init --cpus=2-3 --memory=1GB")
          machine.succeed("grep 'Multikernel Memory Pool' /proc/iomem")
          machine.succeed('[ "$(nproc)" -eq 2 ]')

      with subtest("kerf create allocates an instance"):
          machine.succeed("kerf create test --cpus=2-3 --memory=512MB")
          machine.succeed("grep -q ready /sys/fs/multikernel/instances/test/status")
          machine.succeed("kerf show test")

      with subtest("kerf dump replays an instance"):
          machine.succeed("kerf dump test -o /tmp/test.dtb")
          machine.succeed("kerf dump test --dts | grep -q 'test'")
          machine.succeed("kerf delete test")
          machine.fail("test -e /sys/fs/multikernel/instances/test")
          machine.succeed("kerf create --input /tmp/test.dtb")
          machine.succeed("grep -q ready /sys/fs/multikernel/instances/test/status")

      with subtest("kerf load stages a kernel image"):
          machine.succeed(
              "kerf load test"
              " --kernel /run/current-system/kernel"
              " --initrd /etc/spawn-initrd"
              " --cmdline console=mktty0"
          )
          machine.succeed("grep -q loaded /sys/fs/multikernel/instances/test/status")

      with subtest("kerf exec boots the spawn kernel"):
          machine.succeed("kerf exec test")
          machine.wait_until_succeeds(
              "grep -q active /sys/fs/multikernel/instances/test/status"
          )
          machine.wait_until_succeeds(
              "journalctl -k | grep -q 'Multikernel instance 1 is now active'"
          )

      with subtest("spawn userspace reaches the host over mktty"):
          machine.wait_until_succeeds(
              "exec 3<>/dev/mktty; printf '1\\n' >&3;"
              " timeout 20 grep -qam1 multikernel-spawn-alive <&3"
          )

      with subtest("kerf kill halts the spawn kernel"):
          machine.succeed("kerf kill test")
          machine.wait_until_succeeds(
              "grep -q loaded /sys/fs/multikernel/instances/test/status"
          )
          machine.wait_until_succeeds(
              "journalctl -k | grep -q 'Multikernel instance 1 halted (graceful)'"
          )

      with subtest("a halted instance boots again"):
          machine.succeed("kerf exec test")
          machine.wait_until_succeeds(
              "grep -q active /sys/fs/multikernel/instances/test/status"
          )
          machine.succeed("kerf kill test")
          machine.wait_until_succeeds(
              "grep -q loaded /sys/fs/multikernel/instances/test/status"
          )

      with subtest("kerf unload and delete tear the instance down"):
          machine.succeed("kerf unload test")
          machine.succeed("grep -q ready /sys/fs/multikernel/instances/test/status")
          machine.succeed("kerf delete test")
          machine.fail("test -e /sys/fs/multikernel/instances/test")

      with subtest("kerf init returns resources to the host"):
          machine.succeed("kerf init --cpus=none --memory=none")
          machine.wait_until_succeeds('[ "$(nproc)" -eq 4 ]')
          machine.fail("grep 'Multikernel Memory Pool' /proc/iomem")
    '';
  };
}
