{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  libllama,
}:
stdenv.mkDerivation rec {
  pname = "hazkey-server";
  version = "0.2.0";

  src = fetchzip {
    url = "https://github.com/7ka-Hiira/fcitx5-hazkey/releases/download/${version}/fcitx5-hazkey-${version}-x86_64.tar.gz";
    hash = "sha256-agpqU8uVpmGJEnqQPsZBv3uSOw9pD0iri3/R/hRAACA=";
    stripRoot = false;
  };

  nativeBuildInputs = [autoPatchelfHook];

  buildInputs = [
    stdenv.cc.cc.lib
    libllama
  ];

  dontBuild = true;

  patchPhase = ''
    runHook prePatch

    # Flatten upstream lib dir for consistency
    mkdir -p usr/lib
    mv usr/lib/x86_64-linux-gnu/* usr/lib/
    rmdir usr/lib/x86_64-linux-gnu

    runHook postPatch
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/hazkey

    cp -r usr/lib/hazkey/hazkey-server $out/lib/hazkey/

    # Install wrapper script
    cp usr/bin/hazkey-server $out/bin/
    runHook postInstall
  '';

  postFixup = ''
    substituteInPlace $out/bin/hazkey-server \
      --replace-fail '/usr/lib/x86_64-linux-gnu/hazkey/hazkey-server' "$out/lib/hazkey/hazkey-server"

    # Prefer dynamic selection via LD_LIBRARY_PATH over LD_PRELOAD so a
    # patchelf'ed lib can be overridden by providing another libllama.so.
    substituteInPlace $out/bin/hazkey-server \
      --replace-fail 'export LD_PRELOAD="$LIBLLAMA_PATH"' 'export LD_LIBRARY_PATH="$(dirname "$LIBLLAMA_PATH"):$LD_LIBRARY_PATH"'
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
