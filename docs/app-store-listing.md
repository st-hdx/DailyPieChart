# App Store 掲載情報

App Store Connect に貼り付ける用の原稿。**バイナリ更新なしで反映できる**ので、
アプリのアップデート審査を待たずに先に差し替えてよい。

スクリーンショットは `screenshots/appstore_ja/` と `screenshots/appstore_en/` に
1290×2796（6.7インチ）で生成済み。

---

## 日本語（プライマリ）

### アプリ名（30文字以内）

```
DailyPieChart：24時間 円グラフ
```

現状の `DailyPieChart` だけだと日本語検索に一切かからない。アプリ名は検索順位への
寄与が最も大きいフィールドなので、実需のある語をここに入れる。

### サブタイトル（30文字以内）

```
一日の時間割を円グラフで可視化
```

### キーワード（100文字以内・カンマ区切り・スペース無し）

```
時間管理,タイムスケジュール,生活リズム,円グラフ,24時間,習慣,ルーティン,時間割,可視化,習慣化,生活習慣,朝活,タイムログ
```

アプリ名とサブタイトルに含めた語はキーワード欄に重複させない（無駄になる）ため、
「円グラフ」「24時間」以外を中心に構成。

### 説明文

```
自分の一日が、何にどれだけ使われているか説明できますか。

DailyPieChart は、24時間を1枚の円グラフにするアプリです。
睡眠・仕事・移動・自由時間——ブロックを並べていくだけで、
一日の使い方がそのまま形になって見えます。

■ 3タップで完成する
平日・リモートワーク・学生のテンプレートから選べば、
最初から埋まった状態でスタートできます。
もちろんゼロから自分で組み立てても構いません。

■ 歴史上の偉人の一日も収録
ダーウィン、ベートーヴェン、カフカ、キュリー、ダ・ヴィンチ……
彼らが24時間をどう配分していたかを同じ円グラフで見られます。
気に入った習慣はそのまま自分のスケジュールにコピーできます。

■ ホーム画面ウィジェット
今どの時間帯にいるのかを、ホーム画面から一目で確認できます。

■ 1枚の画像でシェア
作った一日はカード画像として書き出せます。
SNSに貼るのも、友人に送るのもワンタップです。

■ 複数の一日を使い分け
平日と休日、仕事の日と旅行の日。
生活パターンごとにスケジュールを分けて持てます。

■ ダークモード対応
夜は目にやさしい配色に自動で切り替わります。

―――
Pro（買い切り）
・収録されている偉人をすべて閲覧
・スケジュールを無制限に作成
・今後のアップデートで追加される内容も利用可能

一度購入すれば、ずっと使えます。サブスクリプションではありません。
```

### プロモーションテキスト（170文字以内・審査なしで随時変更可）

```
英語に対応しました。ホーム画面ウィジェットと、一日を1枚の画像でシェアする機能も追加。テンプレートから選べば3タップで自分の24時間が完成します。
```

---

## English

### App Name (30 chars)

```
DailyPieChart: 24h Planner
```

### Subtitle (30 chars)

```
Your whole day as one chart
```

### Keywords (100 chars, comma-separated, no spaces)

```
timemanagement,dailyroutine,schedule,timeblocking,habit,piechart,24hours,timetracker,planner,visualize,productivity
```

### Description

```
Can you say where your day actually goes?

DailyPieChart turns your 24 hours into a single pie chart.
Sleep, work, commute, free time — drop in the blocks and
the shape of your day appears.

■ Ready in three taps
Start from a Weekday, Remote work or Student template and
your chart is filled in from the start. Or build it from scratch.

■ See how history's greatest minds spent their day
Darwin, Beethoven, Kafka, Curie, da Vinci and more —
the same 24-hour chart, drawn from their documented routines.
Copy any of them straight into your own schedule.

■ Home Screen widget
Glance at your Home Screen to see exactly where you are in the day.

■ Share as a single image
Export your day as a card image and post it anywhere in one tap.

■ Keep several days side by side
Weekday and weekend, office and travel — keep a separate
schedule for each pattern of your life.

■ Dark Mode
Switches to an easier-on-the-eyes palette at night.

―――
Pro (one-time purchase)
- Every historical routine unlocked
- Unlimited schedules
- Everything added in future updates

Buy once, keep it forever. Not a subscription.
```

### Promotional Text (170 chars)

```
Now in English. New: a Home Screen widget, and one-tap sharing of your day as an image. Pick a template and your 24 hours are mapped out in three taps.
```

---

## 反映時の注意

- **iPad のスクリーンショットを撮り直すこと**。これまで iPad では NavigationView が
  スプリットビューになり画面が真っ白だった（＝配信されていたのに何も表示されて
  いなかった）。NavigationStack に置き換えて表示されるようになったので、
  App Store Connect の iPad 枠も現状に合わせて更新する。
- **アプリアイコンを差し替えた**。旧アイコンは白い単色の弧で、アプリの正体
  （色分けされた24時間の円グラフ）が伝わらずスクショとも一致していなかった。
  候補の比較は `screenshots/icon_candidates/compare.png`、生成は
  `tools/make-app-icon.swift`。配分や色を変えたくなったらそこを編集して
  `swift tools/make-app-icon.swift <出力先>` で作り直せる。
- **`05_pro.png` の価格表示は要確認**。シミュレータの StoreKit テスト環境が
  US ストアフロントで解決するため、日本語版でも `$1.99` と表示された状態で
  書き出されている。日本語の掲載物としては誤りなので、
  1. ビルド端末でストアフロントを日本にして撮り直す、
  2. または 05 を使わず4枚構成にする、
  のどちらかで対応すること。英語版はそのまま使える。


- **アプリ名の変更は審査対象**。次のバイナリ提出とまとめて申請するのが安全。
  サブタイトル・キーワード・説明文・スクリーンショットも同様にバージョンに紐づく。
  プロモーションテキストだけは審査なしでいつでも差し替えられる。
- スクリーンショットは 6.7インチ（1290×2796）で用意している。App Store Connect が
  6.9インチ（1320×2868）を要求する場合は、ビルド端末の新しいシミュレータで
  `screenshots/` の生成手順を回し直すこと。
- 現在 Localizable.strings は ja / en のみ。App Store Connect 側のローカライズも
  この2言語に揃えること（英語ロケールを追加しないと英語化の効果が出ない）。
