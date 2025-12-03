{flake, ...}: {
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (pkgs.stdenv) system;
  mkOptions = import ../../../internal/mkOptions.nix;
  cfg = config.services.hazkey;
in {
  _class = "homeManager";

  options.services.hazkey = mkOptions {inherit pkgs flake;};

  config = lib.mkIf cfg.enable (let
    pkg = cfg.server.package.override {libllama = cfg.libllama.package;};
  in {
    assertions = [
      {
        assertion = !cfg.installFcitx5Addon || (config.i18n.inputMethod.enabled or null) == "fcitx5";
        message = "services.hazkey requires i18n.inputMethod.type = \"fcitx5\" when installFcitx5Addon is true";
      }
    ];

    home.packages = lib.optional cfg.installHazkeySettings flake.packages.${system}.hazkey-settings;
    i18n.inputMethod.fcitx5.addons = lib.optional cfg.installFcitx5Addon flake.packages.${system}.fcitx5-hazkey;

    systemd.user.services.hazkey-server = {
      Unit = {
        Description = "Hazkey server";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${lib.getExe pkg}";
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
