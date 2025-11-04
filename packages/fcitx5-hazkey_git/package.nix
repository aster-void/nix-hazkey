{
  swift-toolchain,
  buildFHSEnvBubblewrap,
  fetchFromGitHub,
  qtbase,
  qttools,
  stdenvNoCC,
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
    hash = "sha256-Ms42VhkIk/3YvOSYP/r9O0n4+9dy6OD5Yk5T5nw1Paw=";
  };

  # FHS environment to provide standard Linux filesystem layout
  # This replicates the environment you get with: apt install build-essential cmake ninja-build
  fhs = buildFHSEnvBubblewrap {
    name = "fcitx5-hazkey-build";
    targetPkgs = pkgs: [
      pkgs.git
      pkgs.cmake
      pkgs.ninja
      swift-toolchain
      swift-toolchain.sdk
      qtbase
      qtbase.dev
      qttools
      pkgs.fcitx5
      pkgs.gettext
      pkgs.protobuf
      pkgs.protobufc
      pkgs.abseil-cpp
      pkgs.libGL
      pkgs.libGL.dev
      pkgs.vulkan-loader
    ];
    runScript = "bash";
    profile = ''
      # Set up C++ include paths for standard clang++ usage
      export CPLUS_INCLUDE_PATH="/usr/include/c++/14.3.0:/usr/include/c++/14.3.0/x86_64-unknown-linux-gnu"
    '';
    extraBuildCommands = ''
      # Install Qt mkspecs for Qt6
      ln -s ${qtbase}/mkspecs $out/usr/mkspecs
    '';
  };
in
  stdenvNoCC.mkDerivation {
    pname = "fcitx5-hazkey";
    version = rev;
    inherit src;

    nativeBuildInputs = [autoPatchelfHook];
    buildInputs = [swift-toolchain qtbase qttools protobuf];

    postPatch = ''
      # Patch Swift build to link with llama
      substituteInPlace hazkey-server/build_swift.cmake \
        --replace-fail '    -Xlinker -L''${LLAMA_STUB_DIR}' \
          '    -Xlinker -L''${LLAMA_STUB_DIR}
        -Xlinker -lllama'

      substituteInPlace hazkey-server/Package.swift \
        --replace-fail '.unsafeFlags(["-L", "llama-stub"]),' \
          '.unsafeFlags(["-L", "llama-stub"]),
                .unsafeFlags(["-Xlinker", "-lllama"]),'
    '';

    # Build using standard commands inside FHS environment
    buildPhase = ''
      runHook preBuild

      # Set up temporary directory for build
      export BUILDDIR=$(mktemp -d)
      cp -r . $BUILDDIR/src
      cd $BUILDDIR/src

      # Run the standard build commands inside FHS environment
      ${fhs}/bin/fcitx5-hazkey-build << 'BUILD_SCRIPT'
        set -euo pipefail

        # Set up Swift cache
        export HOME=$PWD/home
        mkdir -p "$HOME/.cache"
        cp -r ${swiftDeps}/cache/. "$HOME/.cache"
        export XDG_CACHE_HOME="$HOME/.cache"

        # Standard build commands - exactly like the upstream instructions
        mkdir build && cd build
        cmake -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=/usr -G Ninja ..

        # Build llama stub
        mkdir -p hazkey-server/llama-stub
        clang -std=c11 -shared -fPIC \
          -I../hazkey-server/llama-stub \
          -o hazkey-server/llama-stub/libllama.so \
          ../hazkey-server/llama-stub/llama.c

        # Set up Swift build with cached dependencies
        mkdir -p hazkey-server/swift-build
        cp -r ${swiftDeps}/build/. hazkey-server/swift-build

        ninja
BUILD_SCRIPT

      # Copy artifacts to output
      BUILD=$BUILDDIR/src/build

      # Install binaries
      install -Dm755 $BUILD/hazkey-server/swift-build/release/hazkey-server $out/lib/hazkey/hazkey-server
      install -Dm755 $BUILD/hazkey-settings/hazkey-settings $out/lib/hazkey/hazkey-settings

      # Install libraries
      install -Dm644 $BUILD/fcitx5-hazkey/src/fcitx5-hazkey.so $out/lib/fcitx5/fcitx5-hazkey.so
      cp -r $BUILD/hazkey-server/llama-stub $out/lib/hazkey/

      # Create symlinks
      mkdir -p $out/bin
      ln -s ../lib/hazkey/hazkey-server $out/bin/hazkey-server
      ln -s ../lib/hazkey/hazkey-settings $out/bin/hazkey-settings

      # Copy share data if it exists
      if [ -d $BUILDDIR/src/fcitx5-hazkey/share ]; then
        cp -r $BUILDDIR/src/fcitx5-hazkey/share/. $out/share/
      fi

      runHook postBuild
    '';

    dontWrapQtApps = true;
    dontInstall = true;

    postFixup = ''
      # Add lib/hazkey to RPATH so hazkey-server can find libllama.so
      patchelf --add-rpath '$ORIGIN/../lib/hazkey/llama-stub' $out/lib/hazkey/hazkey-server || true
    '';

    meta = {
      mainProgram = "hazkey-server";
    };
  }
