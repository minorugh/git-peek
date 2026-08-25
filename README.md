# git-peek.el

![Alt Text](https://minorugh.github.io/img/git-peek.png) 


git 管理下のファイルの過去バージョンを ivy で選択し、
左右分割のサイドバーUIでプレビューしながら `~/Dropbox/backup/tmp/` に保存するツール。

> Created by Minoru Yamada and Claude (Anthropic)

## 概要

- git リポジトリ内のファイルを ivy で選択（現在のバッファが候補に一致する場合は ivy をスキップして直接起動）
- 選択したファイルのコミット履歴を**左サイドバー**に一覧表示
- **カーソル移動に連動して右側にリアルタイムプレビュー**
- プレビューバッファは `RET` でフォーカス移動、自由にスクロール可能
- プレビューにフォーカスがあるときはモードラインの色が変わる（サイドバー・プレビュー共通色）
- `s` で `YYYYMMDD_ファイル名` 形式で `~/Dropbox/backup/tmp/` に保存
- `q` で全バッファを閉じ、元のウィンドウ配置に戻る
- **削除済みファイルの過去バージョンも取り出せる**（`git-peek-deleted`）
- **起動コンテキストを自動判定**してファイル選択をプリセット（前方一致）
- サイドバー先頭行に選択ファイル名を表示（背景色付き）、`?` でキーガイドをミニバッファに表示

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
2. ivy でファイルを選択（現在のバッファが候補に完全一致する場合は ivy をスキップして直接起動）
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

## tig 連携（my-tig-bridge.el）

tig で diff を眺めながら目的のコミットを探し、そのまま git-peek へ渡せる仕組み。

### フロー

1. Emacs でファイルを開いている（or dired でカーソル位置）
2. `my-open-tig` で gnome-terminal に tig を起動
3. tig で diff を眺めながら目的のコミットを発見
4. tig 上で `E` を押す → emacsclient 経由で git-peek が該当コミット位置から開く
5. git-peek で保存、または `q` で閉じて `my-open-tig` で tig を再起動して探し直す

### セットアップ

`~/.emacs.d/elisp/my-tig-bridge.el` を配置して `(require 'my-tig-bridge)`。

`~/.config/tig/config` に追記：

```
bind generic E !sh -c "emacsclient --eval '(git-peek-from-hash \"%(commit)\")'; xdotool getactivewindow windowminimize"
```

### 仕組み

- `my-open-tig` 起動時に対象ファイルパスを `/tmp/tig-peek-context` に上書き保存
- tig 上で `E` → `git-peek-from-hash` がコンテキストファイルを読んで git-peek を起動
- xsrv 配下かどうかはパスを見て自動判定（`my-git-peek-smart` 相当）
- `/tmp/tig-peek-context` は常に上書き1ファイルのみ保持

## カスタマイズ

```elisp
;; サイドバーの幅（デフォルト: 30）
(setq git-peek-sidebar-width 30)

;; 保存先ディレクトリ（デフォルト: ~/Dropbox/backup/tmp/）
(setq git-peek-save-dir (expand-file-name "~/Dropbox/backup/tmp/"))

;; 追加の移動キー（デフォルト: nil = 無効）
(setq git-peek-next-key (kbd "n"))
(setq git-peek-prev-key (kbd "p"))

;; プレビューにフォーカスがあるときのモードライン色（サイドバー・プレビュー共用）
(setq git-peek-preview-modeline-color "#852941")

;; サイドバー先頭のファイル名行のフェイス（defface で定義済み、customize で変更可）
(custom-set-faces
 '(git-peek-filename-face ((t :foreground "#aaaaaa" :background "#2a3a5a" :weight bold :extend t))))
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

- `git ls-files` で候補を取得し、`buffer-file-name` が完全一致する場合は ivy をスキップして直接起動
- `ivy-read` でファイルを選択後（または ivy スキップ後）、`split-window` で画面を左右に分割
- 左サイドバー（`*git-peek-commits*`）に `git log --oneline` の結果を表示
- カーソル移動のたびに `git show` でファイル内容を取得して右側のプレビューバッファを更新
- プレビューバッファは `buffer-read-only` で保護、グローバルマップ継承のローカルキーマップで操作
- サイドバー・プレビューどちらがアクティブでも `set-face-background` で同じ色をモードラインに適用
- `q/C-g` では `set-window-configuration` で元のウィンドウ配置をそのまま復元
- コンテキスト判定: dired では `dired-get-filename`、通常バッファでは `buffer-file-name` で自動プリセット
- `file-truename` でリポジトリルートを正規化（`~/` 略記・シンボリックリンクを解決）
- サイドバー先頭のファイル名行は `defface` + overlay + 行末スペース詰めで行全体に背景色を適用
- mozc が有効な場合は起動時に自動で無効化
