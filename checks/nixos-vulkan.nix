{
  pkgs,
  flake,
  ...
}:
pkgs.testers.nixosTest {
  name = "hazkey-nixos-vulkan";

  nodes.machine = {
    imports = [flake.nixosModules.hazkey];

    users.users.testuser = {
      isNormalUser = true;
      uid = 1000;
    };

    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
    };

    services.hazkey = {
      enable = true;
      server.package = flake.packages.x86_64-linux.hazkey-server.override {enableVulkan = true;};
      zenzai.package = flake.packages.x86_64-linux.zenzai_v2;
    };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # Check that hazkey-settings is installed
    machine.succeed("test -x /run/current-system/sw/bin/hazkey-settings")

    # Check that fcitx5 addon is installed
    machine.succeed("test -f /run/current-system/sw/lib/fcitx5/fcitx5-hazkey.so")

    # Start user session and check service
    machine.succeed("loginctl enable-linger testuser")
    machine.wait_for_unit("user@1000.service")
    machine.succeed("machinectl shell testuser@ /run/current-system/sw/bin/systemctl --user start hazkey-server.service")
    machine.wait_for_unit("hazkey-server.service", "testuser")

    # Check that hazkey-server process is running
    machine.succeed("pgrep -u testuser -f hazkey-server")

    # Verify zenzai_v2 model is used
    machine.succeed("machinectl shell testuser@ /run/current-system/sw/bin/systemctl --user show hazkey-server.service -p Environment | grep HAZKEY_ZENZAI_MODEL | grep zenzai_v2")
  '';
}
