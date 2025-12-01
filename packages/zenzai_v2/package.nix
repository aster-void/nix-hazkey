{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation {
  pname = "zenzai_v2";
  version = "2.0";

  src = fetchurl {
    url = "https://huggingface.co/Miwa-Keita/zenz-v2-gguf/resolve/a4b653da54904aa8a5dfbf9e7428b1f0c6b2e50e/zenz-v2-Q5_K_M.gguf";
    hash = "sha256-IrjYGQu6jJ/sB1/7WzI7Dw1lx8X1/4IBF5mgwwSdlmI=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/zenzai
    cp $src $out/share/zenzai/zenzai.gguf
    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://huggingface.co/Miwa-Keita/zenz-v2-gguf";
    description = "Zenzai v2";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.all;
  };
}
