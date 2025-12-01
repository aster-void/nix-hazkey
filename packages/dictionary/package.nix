{
  lib,
  stdenv,
  fetchzip,
  ...
}:
stdenv.mkDerivation rec {
  pname = "hazkey-dictionary";
  version = "0.2.0";

  src = fetchzip {
    url = "https://github.com/7ka-Hiira/fcitx5-hazkey/releases/download/${version}/fcitx5-hazkey-${version}-x86_64.tar.gz";
    hash = "sha256-agpqU8uVpmGJEnqQPsZBv3uSOw9pD0iri3/R/hRAACA=";
    stripRoot = false;
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/hazkey/Dictionary
    # The archive contains directories (cb, louds, p); copy recursively
    cp -r usr/share/hazkey/Dictionary/* $out/share/hazkey/Dictionary/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Hazkey dictionary files";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.all;
  };
}
