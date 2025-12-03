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
│   ├── nixos/hazkey/     # NixOS 用モジュール
│   └── home/hazkey/      # Home Manager 用モジュール
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

## 開発コマンド

```bash
# ビルド
nix build .#<package-name>
nix flake check

# フォーマット
nix fmt
```
