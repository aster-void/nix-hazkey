# CLAUDE.md / AGENTS.md

## プロジェクト概要

nix-hazkey は fcitx5-hazkey を NixOS/Home Manager 向けにパッケージングした Nix flake です。
日本語入力システム hazkey と AI 予測変換機能（Zenzai）を提供します。

## リポジトリ構成

```
nix-hazkey/
├── packages/          # 個別パッケージ定義
│   └── <name>/
│       ├── default.nix   # 引数受け取りと override 対応
│       └── package.nix   # 実際のパッケージング定義
├── modules/           # NixOS/Home Manager モジュール
│   ├── nixos/
│   │   └── hazkey/    # NixOS 用モジュール
│   └── home/
│       └── hazkey/    # Home Manager 用モジュール
└── flake.nix          # Flake エントリーポイント
```

## 設計ゴール

1. **モジュラー構成**: サーバー、fcitx5 アドオン、AI バックエンド、モデルファイルを独立したパッケージとして管理
2. **柔軟な依存関係**: `callPackage` を使うことで、下流での依存関係の上書きが可能
3. **統一インターフェース**: NixOS と Home Manager で同じ設定インターフェースを提供

### パッケージ override パターン

依存関係を持つパッケージは `default.nix` で override を受け入れる設計：

```nix
{
  pkgs,
  flake,
}:
pkgs.callPackage ./package.nix {
  dependency = flake.packages.${system}.dependency;
}
```

下流で `package.override {dependency = dependency-replacement;}` で差し替え可能です。

## Assertion ポリシー

### Evaluation 時（パッケージ・式レベル）

```nix
# assert + lib.assertMsg - evaluation 時にエラーで即停止
{
  lib,
  stdenv,
  enableAI ? false,
  aiBackend ? null,
}:
assert lib.assertMsg (enableAI -> aiBackend != null)
  "enableAI requires aiBackend to be specified";
stdenv.mkDerivation {
  # ...
}

# lib.warnIf - evaluation 時に警告を表示
{
  lib,
  pythonVersion ? null,
}:
lib.warnIf (pythonVersion != null)
  "pythonVersion is deprecated, Python version is now auto-detected"
  {
    # パッケージ定義
  }
```

### Module system 内

```nix
{
  config,
  lib,
  ...
}: {
  options = {
    # ...
  };

  config = lib.mkIf config.programs.hazkey.enable {
    # warnings - システム構築時に警告
    warnings = lib.optional
      (!config.services.fcitx5.enable)
      "hazkey: fcitx5.enable is recommended for optimal input experience";

    # assertions - システム構築時にエラーで停止
    assertions = [
      {
        assertion = config.i18n.inputMethod.type == "fcitx5";
        message = "programs.hazkey.enable requires i18n.inputMethod.type = \"fcitx5\"";
      }
    ];
  };
}
```

## 開発コマンド

```bash
# ビルド
nix build .#<package-name>
nix flake check

# フォーマット
nix fmt
```
