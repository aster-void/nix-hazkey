{
  pkgs,
  flake,
  ...
}: {
  imports = [flake.homeModules.hazkey];

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
  };

  home.stateVersion = "26.05";

  # it should install everything
  services.hazkey.enable = true;
}
