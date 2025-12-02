{pkgs}:
pkgs.mkShell {
  packages = [
    pkgs.nix-update
  ];
}
