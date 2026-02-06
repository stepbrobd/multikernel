{
  outputs =
    inputs:
    let
      inherit (inputs.unstable) lib;
    in
    inputs.parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      flake.overlays.default =
        pkgsFinal: pkgsPrev:
        lib.genAttrs (lib.attrNames (builtins.readDir ./pkgs)) (
          name: (lib.callPackageWith (pkgsFinal // { inherit inputs pkgsPrev pkgsFinal; })) ./pkgs/${name} { }
        );

      flake.nixosModules = lib.genAttrs (lib.attrNames (builtins.readDir ./modules)) (
        name: lib.modules.importApply ./modules/${name} { inherit inputs; }
      );

      perSystem =
        {
          pkgs,
          system,
          self',
          ...
        }:
        {
          _module.args.pkgs = import inputs.unstable {
            inherit system;
            overlays = [ inputs.self.overlays.default ];
          };

          legacyPackages = lib.genAttrs (lib.attrNames (builtins.readDir ./pkgs)) (name: pkgs.${name});

          checks = lib.fix (
            self: with self; {
              default = self'.legacyPackages.linuxPackages_multikernel.test;
              interactive = default.driverInteractive;
            }
          );

          formatter = pkgs.nixfmt-tree;
        };
    };

  inputs.unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.parts.url = "github:hercules-ci/flake-parts";
  inputs.parts.inputs.nixpkgs-lib.follows = "unstable";
  inputs.systems.url = "github:nix-systems/default";
}
