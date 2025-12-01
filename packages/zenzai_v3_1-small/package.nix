{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation {
  pname = "zenzai_v3_1-small";
  version = "3.1";

  src = fetchurl {
    url = "https://huggingface.co/Miwa-Keita/zenz-v3.1-small-gguf/resolve/ddf6e44b2e05ab7ea9a3e31559c5e7948761365c/ggml-model-Q5_K_M.gguf";
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
    description = "Zenzai v3.1 small";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.all;
  };
}
