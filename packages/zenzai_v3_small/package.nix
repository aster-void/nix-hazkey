{
  lib,
  stdenv,
  fetchurl,
  ...
}:
stdenv.mkDerivation rec {
  pname = "zenzai_v3_small";
  version = "3.0";

  src = fetchurl {
    # Pin to repository commit for reproducibility
    url = "https://huggingface.co/Miwa-Keita/zenz-v3-small-gguf/resolve/d48369e21adb9f49903eb7c54be1a1d9723eb805/ggml-model-Q5_K_M.gguf";
    hash = "sha256-UB9gXQiPW5iHkaAK4Z7UaYXtfEgUTzZLLz8flRybIIM=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/zenzai
    cp $src $out/share/zenzai/zenzai.gguf
    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://huggingface.co/Miwa-Keita/zenz-v3-small-gguf";
    description = "Zenzai v3 small model (Q5_K_M) for fcitx5-hazkey";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.all;
  };
}
