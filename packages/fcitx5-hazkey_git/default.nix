{pkgs}:
pkgs.callPackage ./package.nix {
  swift-toolchain = pkgs.callPackage ../swift-toolchain-bin {};
}
