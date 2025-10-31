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
    hash = "sha256-EVw+evyziWcrDWnrD4NC44+zWFsHiuxNp2gp0wSAev0=";
  };
  swiftSdk = "${swift-toolchain}/sdk";
  cxxDirEntries = builtins.readDir "${swiftSdk}/usr/include/c++";
  cxxDirNames = lib.filter (name: cxxDirEntries.${name} == "directory") (builtins.attrNames cxxDirEntries);
  cxxVersion = lib.head cxxDirNames;
  cxxInclude = "${swiftSdk}/usr/include/c++/${cxxVersion}";
  cxxTargetEntries = builtins.readDir cxxInclude;
  cxxTargetDirs = lib.filter (name: cxxTargetEntries.${name} == "directory") (builtins.attrNames cxxTargetEntries);
  cxxTargetDirName = lib.findFirst (name: name == stdenv.hostPlatform.config) "" cxxTargetDirs;
  cxxTargetInclude = if cxxTargetDirName == "" then "" else "${cxxInclude}/${cxxTargetDirName}";
  gccLibDir = "${swiftSdk}/usr/lib/gcc/${stdenv.hostPlatform.config}";
  gccVersionEntries = builtins.readDir gccLibDir;
  gccVersionNames = lib.filter (name: gccVersionEntries.${name} == "directory") (builtins.attrNames gccVersionEntries);
  gccVersion = lib.head gccVersionNames;
  gccInclude = "${gccLibDir}/${gccVersion}/include";
  gccIncludeFixed = "${gccLibDir}/${gccVersion}/include-fixed";
  swiftExtraCxxTargetLine = if cxxTargetInclude == "" then "" else "    -Xcc -isystem -Xcc ${cxxTargetInclude}\n";
  swiftCcIncludeLines = "    -Xcc --sysroot -Xcc ${swiftSdk}\n    -Xcc -isystem -Xcc ${cxxInclude}\n" + swiftExtraCxxTargetLine + "    -Xcc -isystem -Xcc ${gccInclude}\n    -Xcc -isystem -Xcc ${gccIncludeFixed}\n    -Xcc -isystem -Xcc ${swiftSdk}/usr/include";
  fhs = buildFHSEnvBubblewrap {
    name = "fcitx5-hazkey-dev";
    meta.mainProgram = "fcitx5-hazkey-dev";
    profile = ''
      export CMAKE_PREFIX_PATH="/usr"
      export QT_ADDITIONAL_PACKAGES_PREFIX_PATHS="/usr"
      export QT_HOST_PATH="/usr"
      export Qt6LinguistTools_DIR="/usr/lib/cmake/Qt6LinguistTools"
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
    buildPhase = ''
      sed -i '/-Xswiftc -static-stdlib/d' hazkey-server/build_swift.cmake
      substituteInPlace hazkey-server/build_swift.cmake \
        --replace '    -Xlinker -L''${LLAMA_STUB_DIR}' '    -Xlinker -L''${LLAMA_STUB_DIR}\n${swiftCcIncludeLines}'
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
        export CC=${swift-toolchain}/bin/clang
        export CXX=${swift-toolchain}/bin/clang++
        export SDKROOT=${swift-toolchain}/sdk
        export CFLAGS="--sysroot=$SDKROOT"
        export CPPFLAGS="--sysroot=$SDKROOT"
        export LIBRARY_PATH=${swiftSdk}/usr/lib:${gccLibDir}/${gccVersion}
        export LD_LIBRARY_PATH=$LIBRARY_PATH
        cxx_root=$(find "$SDKROOT/usr/include/c++" -mindepth 1 -maxdepth 1 -type d | head -n1 || true)
        cxx_target_dir=""
        if [ -n "$cxx_root" ]; then
          cxx_target_dir=$(find "$cxx_root" -mindepth 1 -maxdepth 1 -type d | head -n1 || true)
        fi
        extra_isystem=""
        if [ -n "$cxx_root" ]; then
          extra_isystem="$extra_isystem -isystem $cxx_root"
        fi
        if [ -n "$cxx_target_dir" ]; then
          extra_isystem="$extra_isystem -isystem $cxx_target_dir"
        fi
        export CXXFLAGS="--sysroot=$SDKROOT$extra_isystem"
        cxx_inc_paths=$(find "$SDKROOT/usr/include/c++" -mindepth 1 -maxdepth 2 -type d 2>/dev/null | tr '\n' ':')
        gcc_inc_paths=$(find "$SDKROOT/usr/lib/gcc" -mindepth 2 -maxdepth 3 -type d \( -name include -o -name include-fixed \) 2>/dev/null | tr '\n' ':')
        include_concat="$cxx_inc_paths$gcc_inc_paths''${CPLUS_INCLUDE_PATH:+$CPLUS_INCLUDE_PATH:}"
        export CPLUS_INCLUDE_PATH=$(printf '%s' "$include_concat" | sed 's/:$//')
        export CPATH="$SDKROOT/usr/include''${CPLUS_INCLUDE_PATH:+:$CPLUS_INCLUDE_PATH}"
        mkdir -p hazkey-server/swift-build
        cp -r ${swiftDeps}/build/. hazkey-server/swift-build
        ninja
        DESTDIR=/tmp/bind/out ninja install
      '

      cp -r /tmp/bind/out $out
    '';
    dontInstall = true;
  }
