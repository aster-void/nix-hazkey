{
  pkgs,
  flake,
}:
pkgs.callPackage ./package.nix {
  libllama = flake.packages.${pkgs.stdenv.system}.libllama-cpu;
}
