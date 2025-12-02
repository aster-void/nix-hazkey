{fetchzip}: let
  version = "20251109.0";
in
  fetchzip {
    name = "libllama-vulkan-bin";
    inherit version;
    url = "https://github.com/7ka-Hiira/llama.cpp/releases/download/v${version}/llama-linux-x86_64-vulkan-v${version}.tar.gz";
    hash = "sha256-C0J5IYyKvr4MX4PU0fMu5WNnOWr2EvijdJmpGjgC3nQ=";
    stripRoot = false;
  }
