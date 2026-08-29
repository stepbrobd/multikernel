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

  # pkg_resources is gone from current setuptools
  postPatch = ''
    substituteInPlace src/rdtsc/__init__.py \
      --replace-fail "import pkg_resources" "import importlib.resources" \
      --replace-fail \
        "pkg_resources.resource_filename('rdtsc', sofile)" \
        "str(importlib.resources.files('rdtsc') / sofile)"
  '';

  build-system = with python3.pkgs; [ setuptools ];

  nativeCheckInputs = with python3.pkgs; [
    pytestCheckHook
    six
  ];

  pythonImportsCheck = [ "rdtsc" ];

  meta.platforms = [ "x86_64-linux" ];
}
