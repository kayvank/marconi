# TODO(std) DUP(almost, list of suffices in src differs)

{ inputs, cell }:

let
  inherit (cell.library) pkgs;
in

pkgs.stdenv.mkDerivation {
  name = "read-the-docs-site";

  src = pkgs.lib.sourceFilesBySuffices
    (inputs.self + /doc/read-the-docs-site)
    [ ".py" ".rst" ".md" ".hs" ".png" ".svg" ".bib" ".csv" ".css" ".html" "txt" ];

  buildInputs = [
    cell.packages.sphinx-toolchain
    # We need this here in order to get the `plantuml` executable in PATH.
    # Unfortunately `python3.withPackages` (used by cell.packages.sphinx-toolchain above)
    # won't do it automatically.
    pkgs.python3Packages.sphinxcontrib_plantuml
  ];

  dontInstall = true;

  buildPhase = ''
    sphinx-build -W -n . $out
  '';
}

