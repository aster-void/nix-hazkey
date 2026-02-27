{
  lib,
  stdenv,
  callPackage,
  autoPatchelfHook,
  vulkan-loader,
  makeWrapper,
  addDriverRunpath,
  enableVulkan ? false,
}: let
  upstream = callPackage ../../internal/prebuilt/fcitx5-hazkey.nix {};
in
  stdenv.mkDerivation {
    pname = "hazkey-server";
    src = upstream;
    inherit (upstream) version;

    nativeBuildInputs =
      [autoPatchelfHook makeWrapper]
      ++ lib.optional enableVulkan addDriverRunpath;

    buildInputs =
      [stdenv.cc.cc.lib]
      ++ lib.optional enableVulkan vulkan-loader;

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
      ${lib.optionalString (!enableVulkan) "rm -f $out/lib/hazkey/libllama/backends/libggml-vulkan.so"}

      makeWrapper $out/lib/hazkey/hazkey-server $out/bin/hazkey-server \
        --run '
          # Load user-defined environment variables
          ENV_FILE="''${XDG_CONFIG_HOME:-$HOME/.config}/hazkey/env"
          if [ -f "$ENV_FILE" ]; then
            . "$ENV_FILE"
          fi
        '

      runHook postInstall
    '';

    # Vulkan is opt-in (enableVulkan = true) because GPU drivers are linked
    # against the host glibc, which must match this flake's glibc exactly.
    # A mismatch causes SIGSEGV. See README for details.
    postFixup = lib.optionalString enableVulkan ''
      addDriverRunpath $out/lib/hazkey/libllama/backends/libggml-vulkan.so
    '';

    meta = with lib; {
      homepage = "https://hazkey.hiira.dev/";
      description = "Hazkey server component for fcitx5-hazkey";
      license = licenses.mit;
      maintainers = [];
      platforms = ["x86_64-linux"];
      mainProgram = "hazkey-server";
    };
  }
