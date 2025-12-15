{
  pkgs,
  flake,
  ...
}: let
  testUser = "testuser";
in
  pkgs.testers.nixosTest {
    name = "hazkey-home-manager-vulkan";

    nodes.machine = {
      imports = [flake.inputs.home-manager.nixosModules.default];

      users.users.${testUser} = {
        isNormalUser = true;
        uid = 1000;
      };

      home-manager.extraSpecialArgs = {inherit flake;};

      home-manager.users.${testUser} = {
        imports = [../checks-lib/home/vulkan.nix];
      };
    };

    testScript = ''
      machine.wait_for_unit("multi-user.target")

      # Enable user lingering for systemd user services
      machine.succeed("loginctl enable-linger ${testUser}")
      machine.wait_for_unit("user@1000.service")

      # Check that hazkey-settings is in user's PATH
      machine.succeed("machinectl shell ${testUser}@ /run/current-system/sw/bin/sh -c 'command -v hazkey-settings'")

      # Check that fcitx5 addon is installed in user's profile
      machine.succeed("machinectl shell ${testUser}@ /run/current-system/sw/bin/sh -c 'test -f ~/.nix-profile/lib/fcitx5/fcitx5-hazkey.so || test -f /etc/profiles/per-user/${testUser}/lib/fcitx5/fcitx5-hazkey.so'")

      # Start and check hazkey-server service
      machine.succeed("machinectl shell ${testUser}@ /run/current-system/sw/bin/systemctl --user start hazkey-server.service")
      machine.wait_for_unit("hazkey-server.service", "${testUser}")

      # Check that hazkey-server process is running
      machine.succeed("pgrep -u ${testUser} -f hazkey-server")

      # Verify environment variables are set correctly
      machine.succeed("machinectl shell ${testUser}@ /run/current-system/sw/bin/systemctl --user show hazkey-server.service -p Environment | grep HAZKEY_DICTIONARY")
      machine.succeed("machinectl shell ${testUser}@ /run/current-system/sw/bin/systemctl --user show hazkey-server.service -p Environment | grep HAZKEY_ZENZAI_MODEL")
      machine.succeed("machinectl shell ${testUser}@ /run/current-system/sw/bin/systemctl --user show hazkey-server.service -p Environment | grep LIBLLAMA_PATH")

      # Verify Vulkan backend is used
      machine.succeed("machinectl shell ${testUser}@ /run/current-system/sw/bin/systemctl --user show hazkey-server.service -p Environment | grep LIBLLAMA_PATH | grep libllama-vulkan")

      # Verify zenzai_v3-small model is used
      machine.succeed("machinectl shell ${testUser}@ /run/current-system/sw/bin/systemctl --user show hazkey-server.service -p Environment | grep HAZKEY_ZENZAI_MODEL | grep zenzai_v3-small")
    '';
  }
