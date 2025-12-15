{
  pkgs,
  flake,
  ...
}: let
  testUser = "testuser";
in
  pkgs.testers.nixosTest {
    name = "hazkey-cross-nixos-hm";

    nodes.machine = {
      imports = [
        flake.inputs.home-manager.nixosModules.default
      ];

      users.users.${testUser} = {
        isNormalUser = true;
        uid = 1000;
      };

      # NixOS側でfcitx5を設定
      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
      };

      home-manager.extraSpecialArgs = {inherit flake;};

      # Home Manager側でhazkey-serverを設定
      home-manager.users.${testUser} = {
        imports = [flake.homeModules.hazkey];

        home.stateVersion = "26.05";

        services.hazkey = {
          enable = true;
          installFcitx5Addon = false;
          installHazkeySettings = false;
        };
      };
    };

    testScript = ''
      machine.wait_for_unit("multi-user.target")

      machine.succeed("loginctl enable-linger ${testUser}")
      machine.wait_for_unit("user@1000.service")

      # hazkey-serverが起動することを確認
      machine.succeed("machinectl shell ${testUser}@ /run/current-system/sw/bin/systemctl --user start hazkey-server.service")
      machine.wait_for_unit("hazkey-server.service", "${testUser}")

      machine.succeed("pgrep -u ${testUser} -f hazkey-server")

      # 環境変数が設定されていることを確認
      machine.succeed("machinectl shell ${testUser}@ /run/current-system/sw/bin/systemctl --user show hazkey-server.service -p Environment | grep HAZKEY_DICTIONARY")
      machine.succeed("machinectl shell ${testUser}@ /run/current-system/sw/bin/systemctl --user show hazkey-server.service -p Environment | grep HAZKEY_ZENZAI_MODEL")
      machine.succeed("machinectl shell ${testUser}@ /run/current-system/sw/bin/systemctl --user show hazkey-server.service -p Environment | grep LIBLLAMA_PATH")
    '';
  }
