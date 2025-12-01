# nix-hazkey

## 使い方

### 1. インストール

NixOS の場合:

`flake.nix` の `inputs` に追加し、モジュールを読み込んで有効化します。

```nix
# flake.nix
{
  inputs.nix-hazkey.url = "github:aster-void/nix-hazkey";

  outputs = { self, nixpkgs, ... } @ inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosConfiguration {
      modules = [
        {
          _module.args = {
            inherit inputs;
          };
        }
        ./configuration.nix
      ];
    };
  };
}
```

```nix
# configuration.nix
{inputs, pkgs, ...}: let
  inherit (pkgs.stdenv) system;
in {
  imports = [
    inputs.nix-hazkey.nixosModules.hazkey
  ];

  services.hazkey.enable = true;

  # `services.hazkey` と同じ module system (NixOS/HM) である必要はありません
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = [
      inputs.nix-hazkey.packages.${system}.fcitx5-hazkey
    ];
  };
}
```

Home Manager:

Home Manager でも同様にモジュールを読み込み、有効化します。

```nix
# home.nix
{ config, pkgs, inputs, ... }:
{
  imports = [ inputs.nix-hazkey.homeModules.hazkey ];

  services.hazkey.enable = true;

  # `services.hazkey` と同じ module system (NixOS/HM) である必要はありません
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = [
      inputs.nix-hazkey.packages.${system}.fcitx5-hazkey
    ];
  };
}
```

設定を適用すると `hazkey-server` がユーザーサービスとして起動します。

### 2. 有効化

fcitx5 の設定で有効化します。

```sh
fcitx5-configtool
```

### 3. 設定

hazkey の設定を開きます。 Zenzai の設定がオフになっている場合は、有効化します。

```sh
hazkey-settings
```

## 設定

```nix
# services.hazkey の最小設定例（NixOS/HM 共通）
# - `system` は通常 `inherit (pkgs.stdenv) system;` から取得します
# - `inputs` は flake の inputs を参照します
services.hazkey = {
  enable = true;

  # llama backend
  # - 既定: libllama-cpu
  # - GPU(Vulkan) を使う場合: libllama-vulkan
  libllama.package = inputs.nix-hazkey.packages.${system}.libllama-vulkan;

  # zenzai model
  # - 既定: zenzai (v3.1 small)
  # - 他: zenzai_v3_1_xsmall, zenzai_v2 など
  zenzai.package = inputs.nix-hazkey.packages.${system}.zenzai_v3_1_xsmall;
};
```
