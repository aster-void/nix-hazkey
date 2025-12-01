{ pkgs, libllama ? pkgs.callPackage ../libllama-cpu {}, ... }:
pkgs.callPackage ./package.nix {
  inherit libllama;
}
