{
  pkgs,
  flake,
}: let
  inherit (pkgs) lib;
  self = flake.packages.${pkgs.stdenv.system};
in {
  enable = lib.mkEnableOption "Hazkey server";
  installHazkeySettings = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Install program hazkey-settings";
  };
  installFcitx5Addon = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Install fcitx5 addon fcitx5-hazkey";
  };

  server.package = lib.mkOption {
    type = lib.types.package;
    default = self.hazkey-server;
    description = "Package providing the hazkey-server binary";
  };

  libllama.package = lib.mkOption {
    type = lib.types.package;
    default = self.libllama-cpu;
    description = "Package providing libllama.so";
  };
  libllama.path = lib.mkOption {
    type = lib.types.str;
    default = "/lib/libllama.so";
    description = "Path inside the libllama.package that points to libllama.so";
  };

  dictionary.package = lib.mkOption {
    type = lib.types.package;
    default = self.dictionary;
    description = "Package providing share/hazkey/Dictionary";
  };
  dictionary.path = lib.mkOption {
    type = lib.types.str;
    default = "/share/hazkey/Dictionary";
    description = "Path inside the dictionary.package that points to the dictionary folder";
  };

  zenzai.package = lib.mkOption {
    type = lib.types.package;
    default = self.zenzai_v3_1-small;
    description = "Package providing zenzai.gguf";
  };
  zenzai.path = lib.mkOption {
    type = lib.types.str;
    default = "/share/zenzai/zenzai.gguf";
    description = "Path inside the zenzai.package that points to the GGUF file";
  };
}
