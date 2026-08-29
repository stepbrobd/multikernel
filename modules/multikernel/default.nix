{ inputs, ... }:

{ lib, pkgs, ... }:

with inputs.self.legacyPackages.${pkgs.stdenv.hostPlatform.system};
{
  boot.kernelPackages = lib.mkForce linuxPackages_multikernel;

  environment.systemPackages = [
    kerf
    kexec-tools
  ];

  systemd.mounts = [
    {
      wantedBy = [ "multi-user.target" ];
      what = "none";
      where = "/sys/fs/multikernel";
      type = "multikernel";
    }
  ];
}
