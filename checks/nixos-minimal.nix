{
  pkgs,
  flake,
  ...
}:
pkgs.testers.nixosTest {
  name = "hazkey-nixos-minimal";

  nodes.machine = {
    imports = [flake.nixosModules.hazkey];

    users.users.testuser = {
      isNormalUser = true;
      uid = 1000;
    };

    # Minimal config: no fcitx5, so addon should be disabled
    services.hazkey = {
      enable = true;
      installHazkeySettings = false;
      installFcitx5Addon = false;
    };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # Verify hazkey-settings is NOT installed
    machine.fail("test -x /run/current-system/sw/bin/hazkey-settings")

    # Verify fcitx5 addon is NOT installed
    machine.fail("test -f /run/current-system/sw/lib/fcitx5/fcitx5-hazkey.so")

    # Start user session and check service still works
    machine.succeed("loginctl enable-linger testuser")
    machine.wait_for_unit("user@1000.service")
    machine.succeed("machinectl shell testuser@ /run/current-system/sw/bin/systemctl --user start hazkey-server.service")
    machine.wait_for_unit("hazkey-server.service", "testuser")

    # Check that hazkey-server process is running
    machine.succeed("pgrep -u testuser -f hazkey-server")

    # Verify environment variables are still set correctly
    machine.succeed("machinectl shell testuser@ /run/current-system/sw/bin/systemctl --user show hazkey-server.service -p Environment | grep HAZKEY_DICTIONARY")
    machine.succeed("machinectl shell testuser@ /run/current-system/sw/bin/systemctl --user show hazkey-server.service -p Environment | grep HAZKEY_ZENZAI_MODEL")
  '';
}
