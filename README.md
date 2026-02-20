# nix-hazkey

## Installation

### 1. flake を `inputs` に追加

```nix
# flake.nix
{
  inputs = {
    nix-hazkey.url = "github:aster-void/nix-hazkey";
    nix-hazkey.inputs.nixpkgs.follows = "nixpkgs"; # nixpkgs の重複を排除する
  };

  outputs = { self, nixpkgs, ... } @ inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosConfiguration {
      modules = [
        {
          _module.args = {
            # この行を追加
            inherit inputs;
          };
        }
        ./configuration.nix
      ];
    };
  };
}
```

### 2. インストール

A. All-in-one (推奨)

```nix
# configuration.nix / home.nix
{inputs, pkgs, ...}: let
  inherit (pkgs.stdenv) system;
in {
  # home-manager の場合は `inputs.nix-hazkey.homeModules.hazkey` を使用
  imports = [ inputs.nix-hazkey.nixosModules.hazkey ];
  services.hazkey.enable = true;

  # `i18n.inputMethod` と同じマネージャー (NixOS or Home Manager) である必要があります
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
  };
}
```

B. Manual installation

```nix
# configuration.nix / home.nix
{pkgs, inputs, ...}: {
  # 1. hazkey-server の有効化 (上記同様)
  imports = [ inputs.nix-hazkey.nixosModules.hazkey ];
  services.hazkey = {
    enable = true;
    # 自動インストールの無効化
    installHazkeySettings = false;
    installFcitx5Addon = false;
  };

  # 2. hazkey-settings のインストール
  environment.systemPackages = [inputs.nix-hazkey.packages.${system}.hazkey-settings];

  # 3. fcitx5 の設定
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = [
      inputs.nix-hazkey.packages.${system}.fcitx5-hazkey
    ];
  };
}
```

設定を適用すると `hazkey-server` が systemd ユーザーサービスとして起動します。

### 3. 有効化

fcitx5 の設定で有効化します。

```sh
fcitx5-configtool
```

### 4. 設定

hazkey の設定を開きます。 Zenzai はデフォルトでオフになっている可能性があるので、必要に応じて有効化します。

```sh
hazkey-settings
```

## Configuration

```nix
{inputs, pkgs, ...}: let
  inherit (pkgs.stdenv) system;
in {
  services.hazkey = {
    enable = true;

    # zenzai model
    # - zenzai_v3_1-small [デフォルト]
    # - zenzai_v3_1-xsmall
    # - zenzai_v3-small
    # - zenzai_v2
    zenzai.package = inputs.nix-hazkey.packages.${system}.zenzai_v3_1-xsmall;
  };
}
```

> **Note:** 0.2.1 以降、`libllama.package` オプションは廃止されました。llama.cpp は hazkey-server に同梱されており、バックエンドデバイス（CPU / Vulkan）の選択は `hazkey-settings` の GUI から行えます。

## Contribution

Issue、Pull Request、スター、宣伝などの任意の形式のコントリビューションは歓迎です！
リポジトリ編集の詳細は [CONTRIBUTION.md](./CONTRIBUTION.md) をご確認ください。
