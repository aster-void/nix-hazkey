{
  fetchzip,
}:
let
  version = "20251109.0";
in
fetchzip {
  name = "libllama-cpu-bin";
  inherit version;
  url = "https://github.com/7ka-Hiira/llama.cpp/releases/download/v${version}/llama-linux-x86_64-cpu-v${version}.tar.gz";
  hash = "sha256-Hw96OYrd3LoePFhNk3Whk90I0pREx2gpxanIMxo+bHs=";
  stripRoot = false;
}
