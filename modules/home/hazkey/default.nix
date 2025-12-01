{flake, ...}: {
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.services.hazkey;
  mkOptions = import ../../../internal/mkOptions.nix;
in {
  _class = "homeManager";

  options.services.hazkey = mkOptions {inherit pkgs flake;};

  config = lib.mkIf cfg.enable (let
    # Override hazkey-server with the libllama specified by the module option
    serverPkg = cfg.server.package.override { libllama = cfg.libllama.package; };
  in {
    systemd.user.services.hazkey-server = {
      Unit = {
        Description = "Hazkey server";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${lib.getExe serverPkg}";
        Restart = "on-failure";
        Environment = [
          "HAZKEY_DICTIONARY=${cfg.dictionary.package}${cfg.dictionary.path}"
          "HAZKEY_ZENZAI_MODEL=${cfg.zenzai.package}${cfg.zenzai.path}"
          "LIBLLAMA_PATH=${cfg.libllama.package}${cfg.libllama.path}"
        ];
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  });
}
