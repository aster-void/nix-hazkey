{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  ...
}:
stdenv.mkDerivation rec {
  pname = "libllama-cpu";
  version = "20251109.0";

  src = fetchzip {
    url = "https://github.com/7ka-Hiira/llama.cpp/releases/download/v${version}/llama-linux-x86_64-cpu-v${version}.tar.gz";
    hash = "sha256-Hw96OYrd3LoePFhNk3Whk90I0pREx2gpxanIMxo+bHs=";
    stripRoot = false;
  };

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
    description = "Llama.cpp libraries (CPU version)";
    license = licenses.mit;
    maintainers = [];
    platforms = ["x86_64-linux"];
  };
}
