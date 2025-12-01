{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zenzai_v3_1_xsmall";
  version = "3.1";

  # XSmall variant lives under zenz-v3.1-xsmall-gguf
  src = fetchurl {
    # Pin to repository commit for reproducibility
    url = "https://huggingface.co/Miwa-Keita/zenz-v${version}-xsmall-gguf/resolve/5c0c4db8c8cc66a6ef01520475bebd56b41f6236/ggml-model-Q5_K_M.gguf";
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
    description = "Zenzai v3.1 xsmall model for fcitx5-hazkey (Q5_K_M)";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.all;
  };
}
