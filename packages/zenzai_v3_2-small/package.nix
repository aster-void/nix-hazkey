{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation {
  pname = "zenzai_v3-small";
  version = "3.0";

  src = fetchurl {
    # the hash after /resolve/ is commit ID - derive from main branch (we don't just use `main` for better reproducibility)
    url = "https://huggingface.co/Miwa-Keita/zenz-v3-2-small-gguf/resolve/d48369e21adb9f49903eb7c54be1a1d9723eb805/ggml-model-Q5_K_M.gguf";
    hash = "";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/zenzai
    cp $src $out/share/zenzai/zenzai.gguf
    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://huggingface.co/Miwa-Keita/zenz-v3-2-small-gguf";
    description = "Zenzai v3.2 small";
    license = licenses.asl20;
    maintainers = [];
    platforms = platforms.all;
  };
}
