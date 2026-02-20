{fetchzip}: let
  version = "0.2.1";
in
  fetchzip {
    name = "fcitx5-hazkey-bin";
    inherit version;
    url = "https://github.com/7ka-Hiira/fcitx5-hazkey/releases/download/${version}/fcitx5-hazkey-${version}-x86_64.tar.gz";
    hash = "sha256-jwv1UTRz/FVHmeaumwP45Q4JZcSuZHTrF2/PAzrxeC8=";
    stripRoot = false;
  }
