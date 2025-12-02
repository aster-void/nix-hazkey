{
  lib,
  stdenv,
  callPackage,
  ...
}:
  let
    upstream = callPackage ../../internal/prebuilt/fcitx5-hazkey.nix {};
  in
stdenv.mkDerivation (finalAttrs: {
  pname = "hazkey-dictionary";
  src = upstream;
  inherit (upstream) version;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/hazkey/Dictionary
    cp -r usr/share/hazkey/Dictionary/* $out/share/hazkey/Dictionary/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Hazkey dictionary files";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.all;
  };
})
