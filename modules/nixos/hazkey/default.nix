{flake, ...}: {
  lib,
  pkgs,
  config,
  ...
}: let
  mkOptions = import ../../../internal/mkOptions.nix;
  cfg = config.services.hazkey;
in {
  _class = "nixos";

  options.services.hazkey = mkOptions {inherit pkgs flake;};

  config = lib.mkIf cfg.enable (let
    # Override hazkey-server with the libllama specified by the module option
    serverPkg = cfg.server.package.override { libllama = cfg.libllama.package; };
  in {
    systemd.user.services.hazkey-server = {
      description = "Hazkey server";
      wantedBy = ["default.target"];
      serviceConfig = {
        ExecStart = "${lib.getExe serverPkg}";
        Restart = "on-failure";
        # Pass paths to model, dictionary, and libllama
        Environment = [
          "HAZKEY_DICTIONARY=${cfg.dictionary.package}${cfg.dictionary.path}"
          "HAZKEY_ZENZAI_MODEL=${cfg.zenzai.package}${cfg.zenzai.path}"
          "LIBLLAMA_PATH=${cfg.libllama.package}${cfg.libllama.path}"
        ];
      };
    };
  });
}
