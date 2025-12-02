{
  lib,
  stdenv,
  callPackage,
  autoPatchelfHook,
  ...
}: let
  upstream = callPackage ../../internal/prebuilt/libllama-cpu.nix {};
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "libllama-cpu";
    src = upstream;
    inherit (upstream) version;

    nativeBuildInputs = [
      autoPatchelfHook
    ];

    buildInputs = [
      stdenv.cc.cc.lib
    ];

    installPhase = ''
      runHook preInstall

        mkdir -p $out/lib
        # The archive contains .so files at the root, not under ./lib
        cp -v ./*.so $out/lib/

      runHook postInstall
    '';

    meta = with lib; {
      homepage = "https://github.com/7ka-Hiira/llama.cpp";
      description = "llama.cpp CPU";
      license = licenses.mit;
      maintainers = [];
      platforms = ["x86_64-linux"];
    };
  })
