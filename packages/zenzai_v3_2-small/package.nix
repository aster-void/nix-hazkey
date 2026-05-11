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
    # the hash after /resolve/ is a commit ID - why is it failing to download?
    url = "https://huggingface.co/Miwa-Keita/zenz-v3.2-small-gguf/resolve/c67e03e07d215c869f591b274c1631170d3e11fe/ggml-model-Q5_K_M.gguf";
    hash = "sha256-KcIj1MIzJ7gP0T67WrJVUFekYxeZfV2jkVhP++8NtnM=";
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
