{
  lib,
  stdenv,
  callPackage,
  autoPatchelfHook,
  vulkan-loader,
}: let
  upstream = callPackage ../../internal/prebuilt/fcitx5-hazkey.nix {};
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "hazkey-server";
    src = upstream;
    inherit (upstream) version;

    nativeBuildInputs = [autoPatchelfHook];

    buildInputs = [
      stdenv.cc.cc.lib
      vulkan-loader
    ];

    dontBuild = true;

    patchPhase = ''
      runHook prePatch

      # Flatten upstream lib dir for consistency
      mv usr/lib/x86_64-linux-gnu/* usr/lib/
      rmdir usr/lib/x86_64-linux-gnu

      runHook postPatch
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib/hazkey/libllama/backends

      cp usr/lib/hazkey/hazkey-server $out/lib/hazkey/

      # Install bundled libllama libraries
      cp usr/lib/hazkey/libllama/libggml-base.so $out/lib/hazkey/libllama/
      cp usr/lib/hazkey/libllama/libggml.so $out/lib/hazkey/libllama/
      cp usr/lib/hazkey/libllama/libllama.so $out/lib/hazkey/libllama/
      cp usr/lib/hazkey/libllama/backends/*.so $out/lib/hazkey/libllama/backends/

      # Install wrapper script
      cp usr/bin/hazkey-server $out/bin/

      runHook postInstall
    '';

    fixupPhase = ''
      runHook preFixup

      substituteInPlace $out/bin/hazkey-server \
        --replace-fail '/usr/lib/x86_64-linux-gnu/hazkey/hazkey-server' "$out/lib/hazkey/hazkey-server"

      patchShebangs $out/bin/hazkey-server

      runHook postFixup
    '';

    meta = with lib; {
      homepage = "https://hazkey.hiira.dev/";
      description = "Hazkey server component for fcitx5-hazkey";
      license = licenses.mit;
      maintainers = [];
      platforms = ["x86_64-linux"];
      mainProgram = "hazkey-server";
    };
  })
