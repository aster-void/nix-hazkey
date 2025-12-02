{
  lib,
  stdenv,
  callPackage,
  autoPatchelfHook,
  qt6,
  ...
}:
  let
    upstream = callPackage ../../internal/prebuilt/fcitx5-hazkey.nix {};
  in
stdenv.mkDerivation (finalAttrs: {
  pname = "hazkey-settings";
  src = upstream;
  inherit (upstream) version;

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

    cp usr/lib/hazkey/hazkey-settings $out/bin/hazkey-settings
    cp usr/share/applications/hazkey-settings.desktop $out/share/applications/
    cp -r usr/share/icons $out/share/

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
})
