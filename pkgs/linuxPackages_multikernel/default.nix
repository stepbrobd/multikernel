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
  test =
    with inputs.self.nixosModules;
    testers.runNixOSTest {
      name = "multikernel";

      interactive.sshBackdoor.enable = true;

      nodes.machine.imports = [ multikernel ];

      testScript = ''
        machine.succeed("zcat /proc/config.gz | grep CONFIG_MULTIKERNEL=y")
      '';
    };
}
