{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  fcitx5,
  ...
}:
stdenv.mkDerivation rec {
  pname = "fcitx5-hazkey";
  version = "0.2.0";

  src = fetchzip {
    url = "https://github.com/7ka-Hiira/fcitx5-hazkey/releases/download/${version}/fcitx5-hazkey-${version}-x86_64.tar.gz";
    hash = "sha256-agpqU8uVpmGJEnqQPsZBv3uSOw9pD0iri3/R/hRAACA=";
    stripRoot = false;
  };

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

      mkdir -p $out/lib/fcitx5 $out/share/fcitx5/addon $out/share/fcitx5/inputmethod $out/share/hazkey $out/share/metainfo

    # Copy only addon-related files (A/B/C)
    cp usr/lib/fcitx5/fcitx5-hazkey.so $out/lib/fcitx5/
    cp usr/share/fcitx5/addon/hazkey.conf $out/share/fcitx5/addon/
    cp usr/share/fcitx5/inputmethod/hazkey.conf $out/share/fcitx5/inputmethod/
    cp usr/share/metainfo/org.fcitx.Fcitx5.Addon.Hazkey.metainfo.xml $out/share/metainfo/
    # Keep only emoji list, drop bundled Dictionary to split packaging
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
}
