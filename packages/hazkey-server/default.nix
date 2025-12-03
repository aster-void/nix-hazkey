{
  pkgs,
  flake,
  libllama ? flake.packages.${pkgs.stdenv.system}.libllama-cpu,
}:
pkgs.callPackage ./package.nix {
  inherit libllama;
}
