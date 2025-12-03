{
  pkgs,
  flake,
  ...
}:
pkgs.testers.nixosTest {
  name = "hazkey-nixos-basic";

  nodes.machine = {
    imports = [flake.nixosModules.hazkey];

    # Create a test user for user services
    users.users.testuser = {
      isNormalUser = true;
      uid = 1000;
    };

    services.hazkey = {
      enable = true;
      installHazkeySettings = true;
      installFcitx5Addon = true;

      # Test custom options
      libllama.package = flake.packages.x86_64-linux.libllama-cpu;
      dictionary.package = flake.packages.x86_64-linux.dictionary;
      zenzai.package = flake.packages.x86_64-linux.zenzai_v3_1-xsmall;
    };

    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
    };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # Check that hazkey-settings is installed
    machine.succeed("test -x /run/current-system/sw/bin/hazkey-settings")

    # Check that fcitx5 addon is installed
    machine.succeed("test -f /run/current-system/sw/lib/fcitx5/libhazkey.so")

    # Start user session and check service
    machine.succeed("loginctl enable-linger testuser")
    machine.succeed("su - testuser -c 'systemctl --user start hazkey-server.service'")
    machine.wait_for_unit("hazkey-server.service", "testuser")

    # Check that hazkey-server process is running
    machine.succeed("su - testuser -c 'pgrep -f hazkey-server'")

    # Verify environment variables are set correctly
    machine.succeed("su - testuser -c 'systemctl --user show hazkey-server.service -p Environment' | grep HAZKEY_DICTIONARY")
    machine.succeed("su - testuser -c 'systemctl --user show hazkey-server.service -p Environment' | grep HAZKEY_ZENZAI_MODEL")
    machine.succeed("su - testuser -c 'systemctl --user show hazkey-server.service -p Environment' | grep LIBLLAMA_PATH")
  '';
}
