{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation {
  pname = "zenzai_v3_1-xsmall";
  version = "3.1";

  src = fetchurl {
    url = "https://huggingface.co/Miwa-Keita/zenz-v3.1-xsmall-gguf/resolve/5c0c4db8c8cc66a6ef01520475bebd56b41f6236/ggml-model-Q5_K_M.gguf";
    hash = "sha256-GJY4NwxDKS/VS6XoOFSySIfd1X6JFOGQlVFOZj9gx/U=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/zenzai
    cp $src $out/share/zenzai/zenzai.gguf

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://huggingface.co/Miwa-Keita/zenz-v3.1-xsmall-gguf";
    description = "Zenzai v3.1 xsmall";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.all;
  };
}
