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

  services.hazkey = {
    enable = true;
    zenzai.package = flake.packages.x86_64-linux.zenzai_v3-small;
  };
}
