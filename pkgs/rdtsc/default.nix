{ python3, fetchFromGitHub }:

python3.pkgs.buildPythonPackage {
  pname = "rdtsc";
  version = "0.2.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "roguelazer";
    repo = "rdtsc";
    tag = "rdtsc-0.2.1";
    hash = "sha256-wY15Oc6xEkU6bfucDgbom/aHHswPn6nXIYV/jKT36bc=";
  };

  dependencies = with python3.pkgs; [
    setuptools
  ];

  nativeCheckInputs = with python3.pkgs; [
    pytestCheckHook
    six
  ];

  pythonImportsCheck = [ "rdtsc" ];

  meta.platforms = [ "x86_64-linux" ];
}
