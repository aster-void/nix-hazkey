{
  swift-toolchain,
  buildFHSEnvBubblewrap,
  fetchFromGitHub,
  qtbase,
  qttools,
  stdenv,
  lib,
  CMAKE_BUILD_TYPE ? "Release",
}: let
  rev = "15b4c08ac2532d4384230324cc85d5c1ce354e99";
  src = fetchFromGitHub {
    owner = "7ka-Hiira";
    repo = "fcitx5-hazkey";
    inherit rev;
    hash = "sha256-mjFUtqeVRm2kxLRrT8uWAe6buwKe7sTwopWQOm6AUFY=";
    fetchSubmodules = true;
  };
  swiftDeps = swift-toolchain.fetchDeps {
    src = "${src}/hazkey-server";
    hash = "sha256-AbjkWQb+NotF643YjLJainHoqqTAOcitNgXirlpu24I=";
  };
  # Compute C++ include paths from Swift SDK
  swiftSdk = "${swift-toolchain}/sdk";
  cxxDirEntries = builtins.readDir "${swiftSdk}/usr/include/c++";
  cxxDirNames = lib.filter (name: cxxDirEntries.${name} == "directory") (builtins.attrNames cxxDirEntries);
  cxxVersion = lib.head cxxDirNames;
  cxxInclude = "${swiftSdk}/usr/include/c++/${cxxVersion}";
  cxxTargetEntries = builtins.readDir cxxInclude;
  cxxTargetDirs = lib.filter (name: cxxTargetEntries.${name} == "directory") (builtins.attrNames cxxTargetEntries);
  cxxTargetDirName = lib.findFirst (name: name == stdenv.hostPlatform.config) "" cxxTargetDirs;
  cxxTargetInclude = if cxxTargetDirName == "" then "" else "${cxxInclude}/${cxxTargetDirName}";
  cxxFlags =
    "--sysroot=${swiftSdk} -isystem ${cxxInclude}" +
    lib.optionalString (cxxTargetInclude != "") " -isystem ${cxxTargetInclude}" +
    " -isystem /usr/include";
  fhs = buildFHSEnvBubblewrap {
    name = "fcitx5-hazkey-dev";
    meta.mainProgram = "fcitx5-hazkey-dev";
    profile = ''
      export CMAKE_PREFIX_PATH="/usr"
      export QT_ADDITIONAL_PACKAGES_PREFIX_PATHS="/usr"
      export QT_HOST_PATH="/usr"
      export Qt6LinguistTools_DIR="/usr/lib/cmake/Qt6LinguistTools"

      # Set up Swift toolchain compiler environment
      export CC=${swift-toolchain}/bin/clang
      export CXX=${swift-toolchain}/bin/clang++
      export SDKROOT=${swiftSdk}
      export CFLAGS="--sysroot=$SDKROOT"
      export CPPFLAGS="--sysroot=$SDKROOT"
      export CXXFLAGS="${cxxFlags}"
      export LIBRARY_PATH=${swiftSdk}/usr/lib
      export LD_LIBRARY_PATH=$LIBRARY_PATH
    '';

    targetPkgs = pkgs: [
      pkgs.git
      pkgs.cmake
      pkgs.ninja
      pkgs.clang
      qtbase
      qtbase.dev
      qttools
      pkgs.libGL
      pkgs.libGL.dev
      pkgs.fcitx5
      pkgs.gettext
      pkgs.protobuf
      pkgs.protobufc
      pkgs.abseil-cpp
      pkgs.vulkan-loader
      swift-toolchain
    ];
    extraArgs = [
      "--bind"
      "/tmp/bind"
      "/tmp/bind"
    ];

    runScript = "bash";
    extraBuildCommands = ''
      ln -s ${qtbase}/mkspecs $out/usr/mkspecs
      mkdir -p $out/usr/include
      ln -s ${swift-toolchain}/sdk/usr/include/c++ $out/usr/include/c++
    '';
  };
in
  stdenv.mkDerivation {
    passthru.builder = fhs;
    pname = "fcitx5-hazkey";
    version = rev;

    src = src;
    postPatch = ''
      # Patch Swift build to use correct sysroot and include paths
      substituteInPlace hazkey-server/build_swift.cmake \
        --replace-fail '-Xswiftc -static-stdlib' "" \
        --replace-fail '    -Xlinker -L''${LLAMA_STUB_DIR}' \
          '    -Xlinker -L''${LLAMA_STUB_DIR}
        -Xlinker -lllama
        -Xcc --sysroot -Xcc ${swiftSdk}
        -Xcc -isystem -Xcc ${cxxInclude}${lib.optionalString (cxxTargetInclude != "") "
        -Xcc -isystem -Xcc ${cxxTargetInclude}"}
        -Xcc -isystem -Xcc ${swiftSdk}/usr/include'

      substituteInPlace hazkey-server/Package.swift \
        --replace-fail '.unsafeFlags(["-L", "llama-stub"]),' \
          '.unsafeFlags(["-L", "llama-stub"]),
                .unsafeFlags(["-Xlinker", "-lllama"]),'
    '';
    buildPhase = ''
      mkdir -p /tmp/bind/src
      cp -r ./* /tmp/bind/src

      ${fhs}/bin/fcitx5-hazkey-dev -euc '
        set -euo pipefail
        export HOME=/tmp/bind/home
        mkdir -p "$HOME/.cache"
        cp -r ${swiftDeps}/cache/. "$HOME/.cache"
        export XDG_CACHE_HOME="$HOME/.cache"

        mkdir -p /tmp/bind/src/build
        cd /tmp/bind/src/build
        cmake -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=/usr -G Ninja ..
        mkdir -p hazkey-server/llama-stub
        $CC -std=c11 -shared -fPIC \
          --sysroot=$SDKROOT \
          -I../hazkey-server/llama-stub \
          -o hazkey-server/llama-stub/libllama.so \
          ../hazkey-server/llama-stub/llama.c
        mkdir -p hazkey-server/swift-build
        cp -r ${swiftDeps}/build/. hazkey-server/swift-build
        ninja
        DESTDIR=/tmp/bind/out ninja install
      '

      cp -r /tmp/bind/out $out
    '';
    dontInstall = true;
  }
