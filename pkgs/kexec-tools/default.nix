{
  pkgs,
  pkgsPrev ? pkgs,
  fetchpatch2,
}:

pkgsPrev.kexec-tools.overrideAttrs (prev: {
  version = "2.0.32+multikernel";

  __intentionallyOverridingVersion = true;

  patches = prev.patches ++ [
    (fetchpatch2 {
      url = "https://github.com/multikernel/kexec-tools/commit/442659d61757b76eacaab23ba3becc38d3838c7d.patch";
      hash = "sha256-maUI/SeCPgyfKrp/XqpQFiwP2bQd9BEkIUEVSV/6DdQ=";
    })
  ];
})
