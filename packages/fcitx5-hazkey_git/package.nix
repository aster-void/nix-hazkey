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
  libPath = pkgs.lib.makeLibraryPath [ stdenv.cc.cc stdenv.cc.libc ];
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
      abseil-cpp
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
      pkgs.clang
    ];
    swiftDeps = swift-toolchain.fetchDeps {
      src = "${finalAttrs.src}/hazkey-server";
      # todo: strip undeterminism
      # hash = "sha256-ufy4gJwf9AdmmwQxetEEDyTDThdzvt+FsVcCqqovmJw=";
      hash = "sha256-Fyy+tGD7pok1tSnMjFncPA9N90uvY8YhCo+/UsCysSk=";
    };
    postPatch = ''
      install -Dm644 ${./build_swift.cmake} hazkey-server/build_swift.cmake
    '';
    swiftRoot = "hazkey-server";
    dontUseCmakeConfigure = true;
    dontUseCmakeBuild = true;
    buildPhase = ''
      export HOME=$(mktemp -d)
      export XDG_CACHE_HOME=$HOME/.cache
      clangSysroot=$PWD/clang-sysroot
      cat > "$clangSysroot" <<EOF
#!${pkgs.bash}/bin/bash
exec ${swift-toolchain}/bin/clang --sysroot ${swift-toolchain}/sdk "\$@"
EOF
      chmod +x "$clangSysroot"
      clangppSysroot=$PWD/clang++-sysroot
      cat > "$clangppSysroot" <<EOF
#!${pkgs.bash}/bin/bash
exec ${swift-toolchain}/bin/clang++ --sysroot ${swift-toolchain}/sdk "\$@"
EOF
      chmod +x "$clangppSysroot"

      export CC=$clangSysroot
      export CXX=$clangppSysroot
      export SDKROOT=${swift-toolchain}/sdk
      export C_INCLUDE_PATH=${swift-toolchain}/sdk/usr/include
      export CPATH=${swift-toolchain}/sdk/usr/include
      cxxIncludeRoot=${swift-toolchain}/sdk/usr/include/c++
      if [ -d "$cxxIncludeRoot" ]; then
        cxxVersion=
        for dir in "$cxxIncludeRoot"/*; do
          if [ -d "$dir" ]; then
            cxxVersion=$(basename "$dir")
            break
          fi
        done
        if [ -n "$cxxVersion" ]; then
          export CPLUS_INCLUDE_PATH=$cxxIncludeRoot/$cxxVersion:$cxxIncludeRoot/$cxxVersion/${stdenv.hostPlatform.config}
        fi
      fi
      if [ -n "''${CPLUS_INCLUDE_PATH:-}" ]; then
        export CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:${swift-toolchain}/sdk/usr/include"
      else
        export CPLUS_INCLUDE_PATH="${swift-toolchain}/sdk/usr/include"
      fi
      export CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:${pkgs.abseil-cpp}/include"
      export LIBRARY_PATH=${swift-toolchain}/sdk/usr/lib:${stdenv.cc.cc.lib}/lib:${stdenv.cc.libc}/lib
      export NIX_CFLAGS_COMPILE="''${NIX_CFLAGS_COMPILE:-} -D__HAVE_FLOAT128=0 -D__HAVE_FLOAT64X=0"
      export NIX_CXXFLAGS_COMPILE="''${NIX_CXXFLAGS_COMPILE:-} -isystem ${pkgs.abseil-cpp}/include -D__HAVE_FLOAT128=0 -D__HAVE_FLOAT64X=0"
      export NIX_LDFLAGS="''${NIX_LDFLAGS:-} -L${libPath}"

      mkdir build
      cd build
      mkdir -p hazkey-server/swift-build
      cp -r ../hazkey-server/.build/. hazkey-server/swift-build/

      cmake \
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=$out \
        -DSWIFT_CC=$clangSysroot \
        -DSWIFT_CXX=$clangppSysroot \
        -DSWIFT_SDKROOT=${swift-toolchain}/sdk \
        -DSWIFT_LIBRARY_PATH=${swift-toolchain}/sdk/usr/lib:${stdenv.cc.cc.lib}/lib:${stdenv.cc.libc}/lib \
        -DSWIFT_LINK_PATH="${swift-toolchain}/sdk/usr/lib;${stdenv.cc.cc.lib}/lib;${stdenv.cc.libc}/lib" \
        -G Ninja ..
      ninja
    '';
  })
