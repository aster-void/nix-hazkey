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
    common = import ../../../internal/mkConfig.nix {inherit lib pkgs config flake;};
  in {
    inherit (common) assertions;

    environment.systemPackages = common.hazkeySettingsPackages;
    i18n.inputMethod.fcitx5.addons = common.fcitx5Addons;

    systemd.user.services.hazkey-server = {
      description = "Hazkey server";
      wantedBy = ["default.target"];
      serviceConfig = {
        ExecStart = "${lib.getExe common.pkg}";
        Restart = "on-failure";
        Environment = common.environmentVariables;
      };
    };
  });
}
