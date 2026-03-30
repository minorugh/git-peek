# git-peek.el

git 管理下のファイルの過去バージョンを ivy で選択し、
左右分割のサイドバーUIでプレビューしながら `~/Dropbox/backup/tmp/` に保存するツール。

> Created by Minoru Yamada and Claude (Anthropic)

## 概要

- git リポジトリ内のファイルを ivy で選択
- 選択したファイルのコミット履歴を**左サイドバー**に一覧表示
- **カーソル移動に連動して右側にリアルタイムプレビュー**
- プレビューバッファは `RET` でフォーカス移動、自由にスクロール可能
- プレビューにフォーカスがあるときはモードラインの色が変わる
- `s` で `YYYYMMDD_ファイル名` 形式で `~/Dropbox/backup/tmp/` に保存
- `q` で全バッファを閉じ、元のウィンドウ配置に戻る
- **削除済みファイルの過去バージョンも取り出せる**（`git-peek-deleted`）
- **起動コンテキストを自動判定**してファイル選択をプリセット（前方一致）
- サイドバー上部に `?:help` の案内表示、`?` でキーガイドをミニバッファに表示

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
2. ivy でファイルを選択（現在のバッファや dired のカーソル下ファイルが自動プリセット）
3. 画面が左右に分割され、左サイドバーにコミット一覧、右にプレビューが表示される
4. カーソル移動に連動して右側のプレビューがリアルタイム更新される
5. `RET` でプレビューバッファにフォーカス移動して内容を精読
6. `s` で保存、`q` でキャンセル

### 削除済みファイルの取り出し

`M-x git-peek-deleted` で削除済みファイルの一覧を表示して同様に操作できる。

### キー操作

#### サイドバー（*git-peek-commits*）

| キー         | 動作                               |
|--------------|------------------------------------|
| `↓` / `SPC` | 次のコミットへ移動＋プレビュー更新  |
| `↑` / `b`   | 前のコミットへ移動＋プレビュー更新  |
| `RET`        | プレビューバッファへフォーカス移動  |
| `s`          | 選択したバージョンを保存            |
| `C-d`        | 全文表示 ↔ diff 表示をトグル        |
| `?`          | キーガイドをミニバッファに表示      |
| `q` / `C-g` | キャンセル（元のウィンドウに戻る）  |

#### プレビュー（*git-peek-preview*）

| キー         | 動作                        |
|--------------|-----------------------------|
| `RET` / `f` | サイドバーへフォーカス復帰   |
| `s`          | 選択したバージョンを保存     |
| `?`          | キーガイドをミニバッファに表示 |
| `q` / `C-g` | キャンセル（元のウィンドウに戻る） |
| その他       | 通常のスクロール操作（自由） |

## カスタマイズ

```elisp
;; サイドバーの幅（デフォルト: 30）
(setq git-peek-sidebar-width 30)

;; 保存先ディレクトリ（デフォルト: ~/Dropbox/backup/tmp/）
(setq git-peek-save-dir (expand-file-name "~/Dropbox/backup/tmp/"))

;; diff トグルのキー（デフォルト: C-d）
(setq git-peek-toggle-diff-key (kbd "C-d"))

;; 起動時から diff 表示にする場合
(setq git-peek-show-diff t)

;; 追加の移動キー（デフォルト: nil = 無効）
(setq git-peek-next-key (kbd "n"))
(setq git-peek-prev-key (kbd "p"))

;; プレビューにフォーカスがあるときのモードライン色（デフォルト: "#852941"）
(setq git-peek-preview-modeline-color "#852941")
```

## プレビューバッファについて

プレビューバッファ `*git-peek-preview*` は `buffer-read-only` で保護されています。
`RET` でフォーカスを移動すると自由にスクロール・検索ができ、
モードラインの色が変わることで現在位置を視覚的に確認できます。
`RET` または `f` でサイドバーに戻り、次のコミットの選択を続けられます。

evil-mode 環境ではコミットバッファ・プレビューバッファともに
`evil-local-mode` を無効化するため、キーバインドの競合が起きません。

## 保存ファイル名の形式

```
~/Dropbox/backup/tmp/YYYYMMDD_filename
```

例: `20260328_init.el`（2026-03-28 のコミット時点の `init.el`）

## 仕組み

- `ivy-read` でファイルを選択後、`split-window` で画面を左右に分割
- 左サイドバー（`*git-peek-commits*`）に `git log --oneline` の結果を表示
- カーソル移動のたびに `git show` でファイル内容を取得して右側のプレビューバッファを更新
- プレビューバッファは `buffer-read-only` で保護、グローバルマップ継承のローカルキーマップで操作
- プレビューフォーカス時は `set-face-background` でモードライン全体を着色
- `q/C-g` では `set-window-configuration` で元のウィンドウ配置をそのまま復元
- コンテキスト判定: dired では `dired-get-filename`、通常バッファでは `buffer-file-name` で自動プリセット
- `file-truename` でリポジトリルートを正規化（`~/` 略記・シンボリックリンクを解決）
- mozc が有効な場合は起動時に自動で無効化
- dimmer-mode が有効な場合は git-peek 中に自動で一時停止
