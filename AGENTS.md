# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

nix-hazkey は fcitx5-hazkey を NixOS/Home Manager でパッケージングした Nix flake です。
日本語入力システム hazkey の AI 予測変換機能（Zenzai）を提供します。

## アーキテクチャ

### パッケージ構成

- **hazkey-server**: メインサーバーアプリケーション（systemd ユーザーサービス）
- **fcitx5-hazkey**: fcitx5 アドオン
- **hazkey-settings**: 設定 GUI
- **libllama-cpu / libllama-vulkan**: AI モデル推論バックエンド
- **zenzai_v2 / zenzai_v3-small / zenzai_v3_1-small / zenzai_v3_1-xsmall**: AI モデルファイル
- **dictionary**: 辞書ファイル

### モジュールシステム

`modules/nixos/hazkey/` と `modules/home/hazkey/` は NixOS と Home Manager 用の同じインターフェースを提供します：

- `services.hazkey.enable`: サービス有効化
- `services.hazkey.libllama.package`: AI バックエンド選択（CPU/Vulkan）
- `services.hazkey.zenzai.package`: AI モデル選択
- `services.hazkey.installHazkeySettings`: 設定 GUI のインストール（デフォルト: true）
- `services.hazkey.installFcitx5Addon`: fcitx5 アドオンのインストール（デフォルト: true）

環境変数でパスを渡す仕組み：
- `HAZKEY_DICTIONARY`: 辞書パス
- `HAZKEY_ZENZAI_MODEL`: AI モデルパス
- `LIBLLAMA_PATH`: libllama.so のパス

### パッケージ override パターン

hazkey-server は libllama に依存するため、`default.nix` で override を受け入れる：

```nix
{
  pkgs,
  libllama ? pkgs.callPackage ../libllama-cpu {},
  ...
}:
pkgs.callPackage ./package.nix {
  inherit libllama;
}
```

モジュールは `cfg.server.package.override {libllama = cfg.libllama.package;}` で実行時に差し替えます。

## 開発コマンド

### ビルド

```bash
# 特定パッケージをビルド
nix build .#hazkey-server
nix build .#fcitx5-hazkey
nix build .#libllama-vulkan

# 全パッケージのビルドチェック
nix flake check
```

### フォーマット

```bash
# Nix ファイルをフォーマット (alejandra)
nix fmt
```

### 開発シェル

```bash
# devShell に入る（現在は空）
nix develop
```

### flake 情報の確認

```bash
# flake の出力を確認
nix flake show

# flake メタデータを確認
nix flake metadata
```

## パッケージング規約

- 各パッケージは `packages/<name>/default.nix` と `packages/<name>/package.nix` で構成
- `default.nix`: 引数の受け取りと override 対応
- `package.nix`: 実際のパッケージング定義
- Zenzai モデルと dictionary は大容量のため、fetchurl でダウンロード
