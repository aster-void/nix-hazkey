{pkgs}:
pkgs.callPackage ./package.nix {
  swift-toolchain = pkgs.callPackage ../swift-toolchain-bin {};
  qtbase = pkgs.qt6.qtbase;
  qttools = pkgs.qt6.qttools;
}
