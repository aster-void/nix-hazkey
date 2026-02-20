# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

nix-hazkey は fcitx5-hazkey を NixOS/Home Manager 向けにパッケージングした Nix flake。
日本語入力システム hazkey と AI 予測変換機能（Zenzai）を提供する。

## 開発コマンド

```bash
nix build .#<package-name>   # 特定パッケージのビルド
nix flake check              # 全パッケージ + checks のビルド検証
nix fmt                      # alejandra によるフォーマット
```

開発シェル (`devshell.nix`) は `nix-update`, `alejandra`, `lefthook` を提供。`direnv allow` で自動有効化。

## アーキテクチャ

### パッケージの二層構造

各パッケージは `default.nix` と `package.nix` のペアで構成される:

- **`default.nix`**: flake レベルの引数（`pkgs`, `flake`, 依存パッケージ）を受け取り、`callPackage ./package.nix` に渡す。下流で `.override {}` による依存差し替えが可能。
- **`package.nix`**: 実際の derivation 定義。nixpkgs の慣習に従った引数のみを受け取る。

例: `hazkey-server/default.nix` は `libllama` をデフォルト引数として受け取り、`package.nix` に渡す。

### モジュールの共通ロジック

NixOS モジュール (`modules/nixos/`) と Home Manager モジュール (`modules/home/`) は `internal/` の共通コードを使う:

- **`internal/mkOptions.nix`**: `services.hazkey.*` のオプション定義を生成
- **`internal/mkConfig.nix`**: assertions, fcitx5 addons, systemd service config を共通生成

両モジュールの差異は systemd サービスの定義方法（NixOS: `systemd.user.services`, Home Manager: `systemd.user.services` + Unit/Service/Install 構造）とパッケージインストール先（`environment.systemPackages` vs `home.packages`）のみ。

### prebuilt バイナリ

`internal/prebuilt/` に上流の `.deb` パッケージを `fetchurl` + `dpkg-deb` で展開する定義がある。`fcitx5-hazkey`, `libllama-cpu`, `libllama-vulkan` が該当。バージョン更新時はここのハッシュを更新する。

### checks

`checks/` に NixOS VM テスト (`pkgs.testers.nixosTest`) がある。モジュールの設定バリエーション（base, cpu, vulkan, minimal, cross）を検証する。`checks-lib/` は Home Manager テスト用のヘルパー。

## Assertion ポリシー

- **パッケージ・式レベル**: `assert lib.assertMsg` で evaluation 時にエラー停止。`lib.warnIf` で警告。
- **Module system 内**: `assertions` リストで `nixos-rebuild` 時にエラー。`warnings` リストで警告。

## 注意点

- `main` ブランチにコミットを作成しても、ブランチポリシーによりプッシュすることはできません。
- 対応プラットフォーム: `x86_64-linux`, `aarch64-linux`
- フォーマッタは `alejandra`（`nix fmt` で実行）
- ライセンス: Unlicense
