{ inputs, ... }:

{ pkgs, ... }:

with inputs.self.legacyPackages.${pkgs.stdenv.hostPlatform.system};
{
  boot.kernelPackages = linuxPackages_multikernel;

  environment.systemPackages = [
    kerf
    kexec-tools
  ];
}
