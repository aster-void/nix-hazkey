{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  qt6,
  ...
}:
stdenv.mkDerivation rec {
  pname = "hazkey-settings";
  version = "0.2.0";

  src = fetchzip {
    url = "https://github.com/7ka-Hiira/fcitx5-hazkey/releases/download/${version}/fcitx5-hazkey-${version}-x86_64.tar.gz";
    hash = "sha256-agpqU8uVpmGJEnqQPsZBv3uSOw9pD0iri3/R/hRAACA=";
    stripRoot = false;
  };

  nativeBuildInputs = [autoPatchelfHook qt6.wrapQtAppsHook];

  buildInputs = [stdenv.cc.cc.lib qt6.qtbase qt6.qtwayland];

  dontBuild = true;

  patchPhase = ''
    runHook prePatch

    # Flatten libs dir for consistent layout
    mkdir -p usr/lib
    mv usr/lib/x86_64-linux-gnu/* usr/lib/
    rmdir usr/lib/x86_64-linux-gnu

    # Keep only settings bits
    # Keep everything; do selective install

    runHook postPatch
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/hazkey $out/bin $out/share/applications
    cp usr/lib/hazkey/hazkey-settings $out/lib/hazkey/
    ln -s ../lib/hazkey/hazkey-settings $out/bin/hazkey-settings
    cp usr/share/applications/hazkey-settings.desktop $out/share/applications/

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://hazkey.hiira.dev/";
    description = "Hazkey settings application (Qt)";
    license = licenses.mit;
    maintainers = [];
    platforms = ["x86_64-linux"];
    mainProgram = "hazkey-settings";
  };
}
