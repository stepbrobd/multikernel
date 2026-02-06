{
  python3,
  rdtsc,
  fetchFromGitHub,
}:

python3.pkgs.buildPythonPackage {
  pname = "kerf";
  version = "0.1.0-unstable-2026-01-24";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "multikernel";
    repo = "kerf";
    rev = "57018c5f909dc40ac192f2375ddd371ec4f06bb0";
    hash = "sha256-EvVwRKfy1au8DxXhLPJwXN5+7uC6kRUfmQsp93rsqVQ=";
  };

  dependencies = with python3.pkgs; [
    click
    poetry-core
    libfdt
    pyudev
    pyyaml
    rdtsc
  ];

  nativeCheckInputs = with python3.pkgs; [ pytestCheckHook ];

  pythonImportsCheck = [ "kerf" ];
}
