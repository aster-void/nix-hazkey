{
  pkgs,
  flake,
  ...
}: let
  testUser = "testuser";
in
  pkgs.testers.nixosTest {
    name = "hazkey-home-manager-basic";

    nodes.machine = {
      imports = [flake.inputs.home-manager.nixosModules.default];

      users.users.${testUser} = {
        isNormalUser = true;
        uid = 1000;
      };

      home-manager.users.${testUser} = {
        imports = [flake.homeModules.hazkey];

        services.hazkey = {
          enable = true;

          # Test custom options
          libllama.package = flake.packages.x86_64-linux.libllama-vulkan;
          zenzai.package = flake.packages.x86_64-linux.zenzai_v3_1-xsmall;
        };

        i18n.inputMethod = {
          enable = true;
          type = "fcitx5";
        };

        home.stateVersion = "26.05";
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

      # Verify that libllama-vulkan is being used (not libllama-cpu)
      machine.succeed("machinectl shell ${testUser}@ /run/current-system/sw/bin/systemctl --user show hazkey-server.service -p Environment | grep LIBLLAMA_PATH | grep libllama-vulkan")
    '';
  }
