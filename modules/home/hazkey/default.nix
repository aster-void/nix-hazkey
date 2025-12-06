{flake, ...}: {
  lib,
  pkgs,
  config,
  ...
}: let
  mkOptions = import ../../../internal/mkOptions.nix;
  cfg = config.services.hazkey;
in {
  _class = "homeManager";

  options.services.hazkey = mkOptions {inherit pkgs flake;};

  config = lib.mkIf cfg.enable (let
    common = import ../../../internal/mkConfig.nix {inherit lib pkgs config flake;};
  in {
    inherit (common) assertions;

    home.packages = common.hazkeySettingsPackages;
    i18n.inputMethod.fcitx5.addons = common.fcitx5Addons;

    systemd.user.services.hazkey-server = {
      Unit = {
        Description = "Hazkey server";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${lib.getExe common.pkg}";
        Restart = "on-failure";
        Environment = common.environmentVariables;
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  });
}
