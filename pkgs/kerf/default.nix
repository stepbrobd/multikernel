{
  python3,
  rdtsc,
  fetchFromGitHub,
  pkgsStatic,
}:

let
  version = "0.2.0-unstable-2026-08-30";

  src = fetchFromGitHub {
    owner = "multikernel";
    repo = "kerf";
    rev = "49fd9444c2571805dd23160673c3ca4a2a3e3229";
    hash = "sha256-c7OUmEMOCeSCYudX82fDr29fBy7Chu+RZWrnuWswgpA=";
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

  # forget to monkeypatch get_valid_apic_ids_from_system and read build machines /proc/cpuinfo
  disabledTests = [
    "test_a_pooled_device_is_resolved_from_the_pool"
    "test_a_pooled_device_keeps_a_new_alias"
    "test_an_unknown_device_is_still_an_error"
  ];

  pythonImportsCheck = [ "kerf" ];
}
