{
  lib,
  stdenv,
  callPackage,
  autoPatchelfHook,
  fcitx5,
  ...
}: let
  upstream = callPackage ../../internal/prebuilt/fcitx5-hazkey.nix {};
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "fcitx5-hazkey";
    src = upstream;
    inherit (upstream) version;

    nativeBuildInputs = [autoPatchelfHook];

    buildInputs = [fcitx5 stdenv.cc.cc.lib];

    dontBuild = true;

    patchPhase = ''
      runHook prePatch

      # Flatten x86_64-linux-gnu layout expected by upstream
      mkdir -p usr/lib
      mv usr/lib/x86_64-linux-gnu/* usr/lib/
      rmdir usr/lib/x86_64-linux-gnu

      runHook postPatch
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/fcitx5 $out/share/metainfo $out/share/icons $out/share/hazkey $out/share/locale

      # copy lib/
      cp usr/lib/fcitx5/fcitx5-hazkey.so $out/lib/fcitx5/

      # copy share/
      cp -r usr/share/fcitx5/ $out/share/
      cp usr/share/metainfo/org.fcitx.Fcitx5.Addon.Hazkey.metainfo.xml $out/share/metainfo/
      cp -r usr/share/icons/* $out/share/icons
      cp -r usr/share/locale/* $out/share/locale

      # Keep only emoji list, drop bundled Dictionary into another (packages/dictionary)
      cp -r usr/share/hazkey/emoji_all_E16.0.txt $out/share/hazkey/

      runHook postInstall
    '';

    meta = with lib; {
      homepage = "https://hazkey.hiira.dev/";
      description = "Fcitx5 addon for Hazkey (no server, no GUI, no model)";
      license = licenses.mit;
      maintainers = [];
      platforms = ["x86_64-linux"];
    };
  })
