{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zenzai";
  version = "3.1";

  src = fetchurl {
    # Pin to repository commit for reproducibility
    url = "https://huggingface.co/Miwa-Keita/zenz-v${version}-small-gguf/resolve/ddf6e44b2e05ab7ea9a3e31559c5e7948761365c/ggml-model-Q5_K_M.gguf";
    hash = "sha256-TekwwGvvjCY6oapAaEryBttM4bljdbO47Q6lCOCxT2w=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/zenzai
    cp $src $out/share/zenzai/zenzai.gguf

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://huggingface.co/Miwa-Keita/zenz-v3.1-small-gguf";
    description = "Zenzai v3.1 model for fcitx5-hazkey (Q5_K_M quantization, 73.9MB)";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.all;
  };
}
