{
  swift-toolchain,
  buildFHSEnvBubblewrap,
  fetchFromGitHub,
  qtbase,
  qttools,
  stdenvNoCC,
  lib,
  autoPatchelfHook,
  protobuf,
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
    hash = "sha256-k2GqYArnKgSZ8PctxyeHk6cVYbbTnxap3wxj8es9R5A=";
  };
  # Use Swift SDK package exposed by swift-toolchain
  swiftSdkPkg = swift-toolchain.sdk;

  # Compute C++ include paths from Swift SDK for postPatch
  swiftSdk = "${swift-toolchain}/sdk";
  cxxDirEntries = builtins.readDir "${swiftSdk}/usr/include/c++";
  cxxDirNames = lib.filter (name: cxxDirEntries.${name} == "directory") (builtins.attrNames cxxDirEntries);
  cxxVersion = lib.head cxxDirNames;
  fhs = buildFHSEnvBubblewrap {
    name = "fcitx5-hazkey-dev";
    meta.mainProgram = "fcitx5-hazkey-dev";

    targetPkgs = pkgs: [
      pkgs.git
      pkgs.cmake
      pkgs.ninja
      swift-toolchain  # Provides clang/clang++
      swiftSdkPkg      # Provides SDK (headers, libraries, crt*.o, libgcc)
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
    ];
    extraArgs = [
      "--bind"
      "/tmp/bind"
      "/tmp/bind"
    ];

    runScript = "bash";
    profile = ''
      # Put wrapper scripts in PATH before swift-toolchain's bin
      export PATH="/usr/local/bin:$PATH"
    '';
    extraBuildCommands = ''
      # Install Qt mkspecs
      ln -s ${qtbase}/mkspecs $out/usr/mkspecs

      # Make clang wrapper scripts with -B and -L to use SDK in /usr
      # SDK is provided by swiftSdkPkg in targetPkgs
      mkdir -p $out/usr/local/bin
      cat > $out/usr/local/bin/clang << EOF
#!/usr/bin/env bash
exec ${swift-toolchain}/bin/clang -B/usr/lib -L/usr/lib "\$@"
EOF
      cat > $out/usr/local/bin/clang++ << EOF
#!/usr/bin/env bash
exec ${swift-toolchain}/bin/clang++ -B/usr/lib -L/usr/lib -isystem /usr/include/c++/${cxxVersion} "\$@"
EOF
      chmod +x $out/usr/local/bin/clang $out/usr/local/bin/clang++
    '';
  };
in
  stdenvNoCC.mkDerivation {
    passthru.builder = fhs;
    pname = "fcitx5-hazkey";
    version = rev;

    nativeBuildInputs = [autoPatchelfHook];
    buildInputs = [
      swift-toolchain
      qtbase
      qttools
      protobuf
    ];

    src = src;
    postPatch = ''
      # Patch Swift build to link with llama
      substituteInPlace hazkey-server/build_swift.cmake \
        --replace-fail '-Xswiftc -static-stdlib' "" \
        --replace-fail '    -Xlinker -L''${LLAMA_STUB_DIR}' \
          '    -Xlinker -L''${LLAMA_STUB_DIR}
        -Xlinker -lllama'

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
        cmake -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=/usr -G Ninja ..
        mkdir -p hazkey-server/llama-stub
        clang -std=c11 -shared -fPIC \
          -I../hazkey-server/llama-stub \
          -o hazkey-server/llama-stub/libllama.so \
          ../hazkey-server/llama-stub/llama.c
        mkdir -p hazkey-server/swift-build
        cp -r ${swiftDeps}/build/. hazkey-server/swift-build
        ninja
      '

      # Copy build artifacts directly without ninja install
      mkdir -p $out/bin $out/lib/hazkey $out/lib/fcitx5 $out/share
      cp /tmp/bind/src/build/hazkey-server/swift-build/release/hazkey-server $out/lib/hazkey/
      cp /tmp/bind/src/build/hazkey-settings/hazkey-settings $out/lib/hazkey/
      cp -r /tmp/bind/src/build/hazkey-server/llama-stub $out/lib/hazkey/
      cp /tmp/bind/src/build/fcitx5-hazkey/src/fcitx5-hazkey.so $out/lib/fcitx5/
      ln -s ../lib/hazkey/hazkey-server $out/bin/hazkey-server
      ln -s ../lib/hazkey/hazkey-settings $out/bin/hazkey-settings

      # Copy share data
      if [ -d /tmp/bind/src/fcitx5-hazkey/share ]; then
        cp -r /tmp/bind/src/fcitx5-hazkey/share/* $out/share/ 2>/dev/null || true
      fi
    '';

    # Set up RPATH for autoPatchelfHook
    postFixup = ''
      # Add lib/hazkey to RPATH so hazkey-server can find libllama.so
      patchelf --add-rpath '$ORIGIN/../lib/hazkey/llama-stub' $out/lib/hazkey/hazkey-server || true
    '';

    dontWrapQtApps = true;
    dontInstall = true;

    meta = {
      mainProgram = "hazkey-server";
    };
  }
