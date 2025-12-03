{pkgs}:
pkgs.mkShell {
  packages = [
    pkgs.nix-update
    pkgs.alejandra
    pkgs.lefthook
  ];

  shellHook = ''
    lefthook install
  '';
}
