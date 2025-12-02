{fetchzip}: let
  version = "0.2.0";
in
  fetchzip {
    name = "fcitx5-hazkey-bin";
    inherit version;
    url = "https://github.com/7ka-Hiira/fcitx5-hazkey/releases/download/${version}/fcitx5-hazkey-${version}-x86_64.tar.gz";
    hash = "sha256-agpqU8uVpmGJEnqQPsZBv3uSOw9pD0iri3/R/hRAACA=";
    stripRoot = false;
  }
