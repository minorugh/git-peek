# git-peek.el

git 管理下のファイルの過去バージョンを ivy で検索・プレビューして
`~/Dropbox/backup/tmp/` に保存するツール。

> Created by Minoru Higuchi and Claude (Anthropic)

## 概要

- git リポジトリ内のファイルを一覧表示して選択
- 選択したファイルのコミット履歴を一覧表示
- **カーソル移動に連動してリアルタイムプレビュー**
- プレビューバッファは自動的に `view-mode`（read-only）で表示
- `RET` で `YYYYMMDD_ファイル名` 形式で `~/Dropbox/backup/tmp/` に保存
- **削除済みファイルの過去バージョンも取り出せる**（`git-peek-deleted`）
- **起動コンテキストを自動判定**してファイル選択をプリセット（完全一致）

## 必要要件

- Emacs 27.1 以上
- [ivy](https://github.com/abo-abo/swiper)
- git

## インストール

```
~/.emacs.d/elisp/git-peek/git-peek.el
```

に配置し、`init.el` または `inits/` の該当ファイルに以下を追加：

```elisp
(leaf git-peek
  :load-path "~/.emacs.d/elisp/git-peek"
  :require t)
```

## 使い方

### 基本操作

1. git リポジトリ配下のバッファまたは dired で `M-x git-peek`
2. ファイルを ivy で選択（現在のバッファや dired のカーソル下ファイルが自動プリセット）
3. コミット一覧が表示され、カーソル移動に連動して上部にプレビュー表示
4. 目的のバージョンが見つかったら `RET` で保存
5. 保存先 `~/Dropbox/backup/tmp/` の dired が開く

### 削除済みファイルの取り出し

`M-x git-peek-deleted` で削除済みファイルの一覧を表示して同様に操作できる。

### コミット選択画面でのキー操作

| キー  | 動作                                      |
|-------|-------------------------------------------|
| `RET` | 選択したバージョンを保存                  |
| `C-d` | 全文表示 ↔ diff 表示をトグル              |
| `C-g` | キャンセル（元のバッファに戻る）          |

## カスタマイズ

```elisp
;; プレビューウィンドウの高さ（デフォルト: 0.5）
(setq git-peek-preview-height 0.5)

;; 保存先ディレクトリ（デフォルト: ~/Dropbox/backup/tmp/）
(setq git-peek-save-dir (expand-file-name "~/Dropbox/backup/tmp/"))

;; diff トグルのキー（デフォルト: C-d）
(setq git-peek-toggle-diff-key (kbd "C-d"))

;; 起動時から diff 表示にする場合
(setq git-peek-show-diff t)
```

| 値    | 用途                                        |
|-------|---------------------------------------------|
| `1.0` | 全画面（dired 等から使うとき）              |
| `0.8` | 汎用                                        |
| `0.5` | 上下分割（現在ファイルと過去版を対比したいとき）|

## プレビューバッファについて

プレビューバッファ `*git-peek-preview*` は自動的に `view-mode`（read-only）で表示されます。
プレビューバッファに移動してカーソル移動は可能ですが、誤って編集することはありません。
`C-x o` 等で ivy ミニバッファに戻れば引き続きコミット選択が続けられます。

evil-mode 環境では `evil-default-state` が `emacs` に設定されるため、
ivy の状態に影響しません。

## 保存ファイル名の形式

```
~/Dropbox/backup/tmp/YYYYMMDD_filename
```

例: `20260328_init.el`（2026-03-28 のコミット時点の `init.el`）

## 仕組み

- `advice-add` で `ivy-next-line` / `ivy-previous-line` にフックし、
  カーソル移動のたびに `git show` でファイル内容を取得してプレビューバッファを更新
- プレビューは `display-buffer-in-side-window` で上部に固定表示（`1.0` 指定時は全画面）
- プレビューバッファは `view-mode` + `buffer-read-only` で保護。`write-file-functions`
  に abort フックを登録して `super-save` 等の自動保存を静かに抑制
- `RET` 後はプレビューバッファを自動クリーンアップ、`C-g` で元のバッファに復帰
- コンテキスト判定: dired では `dired-get-filename`、通常バッファでは
  `buffer-file-name` でファイル名を自動プリセット（`^...$` 完全一致で同名ファイルの誤選択を防止）
- `file-truename` でリポジトリルートを正規化（`~/` 略記・シンボリックリンクを解決）
- mozc が有効な場合は起動時に自動で無効化
