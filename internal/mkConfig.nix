# Common configuration logic shared between NixOS and Home Manager modules
{
  lib,
  pkgs,
  config,
  flake,
}: let
  inherit (pkgs.stdenv) system;
  cfg = config.services.hazkey;
  pkg = cfg.server.package.override {libllama = cfg.libllama.package;};

  environmentVariables = [
    "HAZKEY_DICTIONARY=${cfg.dictionary.package}${cfg.dictionary.path}"
    "HAZKEY_ZENZAI_MODEL=${cfg.zenzai.package}${cfg.zenzai.path}"
    "LIBLLAMA_PATH=${cfg.libllama.package}${cfg.libllama.path}"
  ];
in {
  assertions = [
    {
      assertion = cfg.installFcitx5Addon -> (config.i18n.inputMethod.enable && config.i18n.inputMethod.type == "fcitx5");
      message = "services.hazkey requires i18n.inputMethod.type = \"fcitx5\" when installFcitx5Addon is true";
    }
  ];

  fcitx5Addons = lib.optional cfg.installFcitx5Addon flake.packages.${system}.fcitx5-hazkey;

  hazkeySettingsPackages = lib.optional cfg.installHazkeySettings flake.packages.${system}.hazkey-settings;

  # Common systemd service configuration (used as serviceConfig in NixOS, Service in Home Manager)
  serviceConfig = let
    wrapper = pkgs.writeShellScript "hazkey-server-wrapper" ''
      # Discover system Vulkan ICD files on non-NixOS (no-op if already set, e.g. on NixOS)
      if [ -z "''${VK_DRIVER_FILES-}" ]; then
        VK_DRIVER_FILES=$(${pkgs.findutils}/bin/find /usr/share/vulkan/icd.d /etc/vulkan/icd.d -name '*.json' 2>/dev/null | tr '\n' ':')
        export VK_DRIVER_FILES
      fi
      exec ${lib.getExe pkg} "$@"
    '';
  in {
    ExecStart = "${wrapper}";
    Restart = "on-failure";
    Environment = environmentVariables;
  };
}
