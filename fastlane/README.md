# fastlane でのメタデータ反映

App Store Connect のブラウザ画面は入力欄が多く、手入力だと時間がかかるうえミスも
起きやすい。名前・サブタイトル・キーワード・説明文・新機能・プロモーションテキスト・
スクリーンショットは、このリポジトリの `fastlane/metadata/` と `fastlane/screenshots/`
を正としてコマンド一発で反映する。

**ビルド（バイナリ）のアップロードはここに含めない。** それは Xcode か Xcode Cloud
で行い、App Store Connect の画面でバージョンに紐付けること。**審査への提出もしない**
（`submit_for_review: false` を設定済み）。反映後、内容を目視で確認してから
「審査へ提出」は人の手で押す。

## 初回だけ必要な準備

### 1. Ruby と bundler

macOS には Ruby が入っているはずだが、`fastlane` は Gemfile 経由で入れる。

```bash
cd /path/to/DailyPieChart
bundle install
```

### 2. App Store Connect API キー

Apple ID とパスワードでのログインは二要素認証が絡んで自動化に向かない。
API キーを使うと毎回の認証を省ける。

1. App Store Connect → ユーザとアクセス → 統合 → App Store Connect API
2. キーを発行し、`.p8` ファイルをダウンロード（**一度しかダウンロードできない**）
3. Key ID と Issuer ID をメモする
4. `.p8` ファイルはこのリポジトリの外（例: `~/.appstoreconnect/`）に保管する。
   **絶対にコミットしない**（`.gitignore` で `*.p8` を除外済みだが、念のため
   保存場所自体をリポジトリ外にすること）

環境変数として渡す（シェルの起動ファイルか、実行のたびに指定する）:

```bash
export APP_STORE_CONNECT_API_KEY_KEY_ID="XXXXXXXXXX"
export APP_STORE_CONNECT_API_KEY_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export APP_STORE_CONNECT_API_KEY_KEY_FILEPATH="$HOME/.appstoreconnect/AuthKey_XXXXXXXXXX.p8"
```

このリポジトリは public なので `fastlane/Appfile` に Apple ID を直書きしていない。
実行前に環境変数として渡すこと（API キー認証では認証自体には使われず、
一部の警告メッセージに使われるだけ）:

```bash
export FASTLANE_APPLE_ID="あなたの Apple ID メールアドレス"
```

## 実行

```bash
bundle exec fastlane update_metadata
```

これで以下が ASC の **バージョン 1.2**（すでに ASC 上で作成済み）に反映される。

- 名前・サブタイトル・キーワード（`fastlane/metadata/<locale>/`）
- 説明文・新機能・プロモーションテキスト
- スクリーンショット（iPhone 6.7インチ・iPad 12.9インチ、日英）
- 英語（en-US）ロケールが無ければ自動で作成される

初回は fastlane が変更内容を要約して確認を求める（`Deliverfile` で `force(true)`
にしているため実際にはスキップされる）。心配なら一時的に `force(false)` に
戻して差分を確認してから実行してもよい。

## 実行後にやること

1. App Store Connect を開いて、反映された内容を目視で確認する
2. 「アプリ情報」で名前・サブタイトル・セカンダリカテゴリ・年齢制限指定の
   ソーシャルメディア設問を確認する（`update_metadata` はここには触れない —
   `deliver` はバージョン単位の情報しか扱わないため）
3. ビルドをアップロードしてバージョンに紐付ける
4. 内容に問題なければ「審査へ提出」を押す（これは自動化していない）

## 日本語版のスクリーンショットが4枚しかない理由

`05_pro.png`（買い切りの案内画面）は、シミュレータの StoreKit テスト環境が
US ストアフロントで解決するため、日本語版でも価格が `$1.99` と表示された状態で
書き出されている。差し替えるには、実機かストアフロントを日本に設定した環境で
撮り直し、`swift tools/make-screenshots.swift <素材> fastlane/screenshots/ja ja iphone67`
のように出力先を直接 `fastlane/screenshots/ja` にして生成し直すこと。
英語版はそのまま使える。
