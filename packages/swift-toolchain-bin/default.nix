{pkgs}: let
  swift-toolchain-bin = pkgs.callPackage ./package.nix {
    passthru = {
      configHook = pkgs.callPackage ./configHook.nix {};
      fetchDeps = pkgs.callPackage ./fetchDeps.nix {
        swift-toolchain = swift-toolchain-bin;
      };
    };
  };
in
  swift-toolchain-bin
