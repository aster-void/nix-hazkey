{
  pkgs,
  stdenv,
  fetchFromGitHub,
  swift-toolchain,
  ninja,
  cmake,
  fcitx5,
  vulkan-loader,
  protobuf,
  protobufc,
  CMAKE_INSTALL_PREFIX ? "/usr",
  CMAKE_BUILD_TYPE ? "Release",
}: let
  rev = "15b4c08ac2532d4384230324cc85d5c1ce354e99";
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "fcitx5-hazkey";
    version = rev;
    src = fetchFromGitHub {
      owner = "7ka-Hiira";
      repo = "fcitx5-hazkey";
      inherit rev;
      hash = "sha256-mjFUtqeVRm2kxLRrT8uWAe6buwKe7sTwopWQOm6AUFY=";
      fetchSubmodules = true;
    };
    buildInputs = with pkgs; [
      fcitx5
      gettext
      protobuf
      protobufc
      kdePackages.qttools
      vulkan-loader
      stdenv.cc.cc.lib
    ];
    dontWrapQtApps = true;
    nativeBuildInputs = [
      swift-toolchain
      swift-toolchain.configHook
      ninja
      cmake
    ];
    swiftDeps = swift-toolchain.fetchDeps {
      src = "${finalAttrs.src}/hazkey-server";
      # todo: strip undeterminism
      # hash = "sha256-ufy4gJwf9AdmmwQxetEEDyTDThdzvt+FsVcCqqovmJw=";
      hash = "sha256-Fyy+tGD7pok1tSnMjFncPA9N90uvY8YhCo+/UsCysSk=";
    };
    swiftRoot = "hazkey-server";
    dontUseCmakeConfigure = true;
    dontUseCmakeBuild = true;
    buildPhase = ''
      export HOME=$(mktemp);
      mkdir build
      cd build
      cmake -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -G Ninja ..
      ninja
    '';
  })
