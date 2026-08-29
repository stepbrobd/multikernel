{
  python3,
  rdtsc,
  fetchFromGitHub,
  pkgsStatic,
}:

let
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "multikernel";
    repo = "kerf";
    rev = "8b72b3e9b266f8d32e707e2c1743ad7afc50b1ec";
    hash = "sha256-feP1fO7A6ARdth05Eo6PltzWkAC3UKdzZ1vtM0bg7hY=";
  };

  kerf-init = pkgsStatic.stdenv.mkDerivation {
    pname = "kerf-init";
    inherit version src;

    sourceRoot = "source/src/init";

    buildPhase = ''
      runHook preBuild
      make CC="$CC"
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 kerf-init $out/bin/kerf-init
      runHook postInstall
    '';
  };
in

python3.pkgs.buildPythonPackage {
  pname = "kerf-multikernel";
  inherit version src;
  pyproject = true;

  postPatch = ''
    install -m755 ${kerf-init}/bin/kerf-init src/kerf/data/kerf-init
  '';

  build-system = with python3.pkgs; [ poetry-core ];

  dependencies = with python3.pkgs; [
    click
    libfdt
    pyudev
    pyyaml
    rdtsc
    zstandard
  ];

  nativeCheckInputs = with python3.pkgs; [ pytestCheckHook ];

  pythonImportsCheck = [ "kerf" ];
}
