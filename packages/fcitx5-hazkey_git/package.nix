{
  swift-toolchain,
  buildFHSEnvBubblewrap,
  fetchFromGitHub,
  qtbase,
  qttools,
  stdenvNoCC,
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
    hash = "sha256-k2GqYArnKgSZ8PctxyeHk6cVYbbTnxap3wxj8es9R5A=";
  };
  # Compute C++ include paths from Swift SDK
  swiftSdk = "${swift-toolchain}/sdk";
  cxxDirEntries = builtins.readDir "${swiftSdk}/usr/include/c++";
  cxxDirNames = lib.filter (name: cxxDirEntries.${name} == "directory") (builtins.attrNames cxxDirEntries);
  cxxVersion = lib.head cxxDirNames;
  cxxInclude = "${swiftSdk}/usr/include/c++/${cxxVersion}";
  cxxTargetEntries = builtins.readDir cxxInclude;
  cxxTargetDirs = lib.filter (name: cxxTargetEntries.${name} == "directory") (builtins.attrNames cxxTargetEntries);
  cxxTargetDirName = lib.findFirst (name: name == stdenvNoCC.hostPlatform.config) "" cxxTargetDirs;
  cxxTargetInclude = if cxxTargetDirName == "" then "" else "${cxxInclude}/${cxxTargetDirName}";
  cxxFlags =
    "--sysroot=${swiftSdk} -isystem ${cxxInclude}" +
    lib.optionalString (cxxTargetInclude != "") " -isystem ${cxxTargetInclude}" +
    " -isystem /usr/include";
  fhs = buildFHSEnvBubblewrap {
    name = "fcitx5-hazkey-dev";
    meta.mainProgram = "fcitx5-hazkey-dev";

    targetPkgs = pkgs: [
      pkgs.git
      pkgs.cmake
      pkgs.ninja
      swift-toolchain  # Provides clang/clang++ and SDK
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

      # Install Swift SDK into /usr so it's the default
      mkdir -p $out/usr/include
      ln -s ${swiftSdk}/usr/include/c++ $out/usr/include/c++

      # Link Swift SDK libraries recursively into /usr/lib
      cp -rs ${swiftSdk}/usr/lib/* $out/usr/lib/ 2>/dev/null || true

      # Make clang wrapper scripts with sysroot in /usr/local/bin (higher priority)
      mkdir -p $out/usr/local/bin
      cat > $out/usr/local/bin/clang << EOF
#!/usr/bin/env bash
exec ${swift-toolchain}/bin/clang --sysroot=${swiftSdk} "\$@"
EOF
      cat > $out/usr/local/bin/clang++ << EOF
#!/usr/bin/env bash
exec ${swift-toolchain}/bin/clang++ --sysroot=${swiftSdk} ${cxxFlags} "\$@"
EOF
      chmod +x $out/usr/local/bin/clang $out/usr/local/bin/clang++
    '';
  };
in
  stdenvNoCC.mkDerivation {
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
        cmake -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=/usr -G Ninja ..
        mkdir -p hazkey-server/llama-stub
        clang -std=c11 -shared -fPIC \
          -I../hazkey-server/llama-stub \
          -o hazkey-server/llama-stub/libllama.so \
          ../hazkey-server/llama-stub/llama.c
        mkdir -p hazkey-server/swift-build
        cp -r ${swiftDeps}/build/. hazkey-server/swift-build
        ninja
        DESTDIR=/tmp/bind/out ninja install
      '

      # Flatten the structure - move from /usr to root
      mkdir -p $out
      if [ -d /tmp/bind/out/usr ]; then
        cp -r /tmp/bind/out/usr/* $out/
      fi
    '';
    dontInstall = true;
  }
