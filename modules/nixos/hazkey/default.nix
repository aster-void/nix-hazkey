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
    hazkey = import ../../../internal/mkConfig.nix {inherit lib pkgs config flake;};
  in {
    inherit (hazkey) assertions warnings;

    environment.systemPackages = hazkey.hazkeySettingsPackages;
    i18n.inputMethod.fcitx5.addons = hazkey.fcitx5Addons;

    systemd.user.services.hazkey-server = {
      description = "Hazkey server";
      wantedBy = ["default.target"];
      inherit (hazkey) serviceConfig;
    };
  });
}
