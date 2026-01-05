# コントリビューションガイド

nix-hazkey へのコントリビューションをありがとうございます！このドキュメントでは、プロジェクトへの貢献方法を説明します。

## 開発環境のセットアップ

### 必要なもの

- Nix
- Git
- Nix Direnv

```sh
# 事前条件: `nix-command` `flakes` の有効化が必要
cat ~/.config/nix/nix.conf /etc/nix/nix.conf | grep "experimental-features"
experimental-features = nix-command flakes
```

```sh
git clone https://github.com/aster-void/nix-hazkey.git
cd nix-hazkey

direnv allow
```

## コマンド

```sh
# 特定パッケージのビルド
nix build .#hazkey-server

# 全パッケージのビルドチェック
nix flake check
```

## コーディング規約

### Nix フォーマット

このプロジェクトは [alejandra](https://github.com/kamadorueda/alejandra) を使用しています。

```sh
# フォーマット実行
nix fmt
```

コミット前に必ずフォーマットを実行してください。

## Issue の報告

バグ報告や機能リクエストは [GitHub Issues](https://github.com/aster-void/nix-hazkey/issues) で受け付けています。

### バグ報告

以下の情報を含めてください:

- NixOS/Home Manager のバージョン
- `nix --version` の出力
- 各パッケージのバージョン
- NixOS/Home Manager の対応部分の設定
- エラーメッセージ
- 再現手順 (可能なら)

### 機能リクエスト

- どのような機能が必要か
- なぜその機能が必要か
- 可能であれば実装案

## 質問・相談

不明点があれば Issue で気軽に質問してください。

## ライセンス

コントリビューションは Unlicense ライセンスの下で提供されます。ご注意ください。
