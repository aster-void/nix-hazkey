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
    libllama.package = flake.packages.x86_64-linux.libllama-vulkan;
    zenzai.package = flake.packages.x86_64-linux.zenzai_v3-small;
  };
}
