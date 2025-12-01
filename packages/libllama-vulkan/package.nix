{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  vulkan-loader,
  ...
}:
stdenv.mkDerivation rec {
  pname = "libllama-vulkan";
  version = "20251109.0";

  src = fetchzip {
    url = "https://github.com/7ka-Hiira/llama.cpp/releases/download/v${version}/llama-linux-x86_64-vulkan-v${version}.tar.gz";
    hash = "sha256-C0J5IYyKvr4MX4PU0fMu5WNnOWr2EvijdJmpGjgC3nQ=";
    stripRoot = false;
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    vulkan-loader
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
    description = "Llama.cpp libraries (Vulkan version)";
    license = licenses.mit;
    maintainers = [];
    platforms = ["x86_64-linux"];
  };
}
