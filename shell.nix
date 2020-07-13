{ pkgs ? import <nixpkgs> {}
}:
pkgs.mkShell {
  name = "dev-shell";
  buildInputs = [
    pkgs.sbcl
    pkgs.lispPackages.quicklisp
    pkgs.lispPackages.hunchentoot
  ];
}
