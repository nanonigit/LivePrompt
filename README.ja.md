# LivePrompt

[English](README.md) | [日本語](README.ja.md)

LivePrompt は、Mac で再生される音声を英語字幕にし、日本語訳と英語の質問・返答案を半透明のプロンプターに表示する macOS アプリです。会議アプリの上に重ねて使えます。

## 動作条件

- macOS 26 以降の Apple Silicon Mac
- システムオーディオ録音の許可
- 質問・返答案には Apple Intelligence が必要
- 初回の Apple 言語モデル取得にはインターネット接続が必要

## インストール

Homebrew Formula は、この Mac でソースからアプリをビルドします。未署名のアプリバイナリはダウンロードしません。

```sh
brew install nanonigit/liveprompt/liveprompt
liveprompt
```

Swift 6.4 と Xcode Command Line Tools で手動ビルドする場合:

```sh
./script/package_app.sh --release
open dist/LivePrompt.app
```

開発時は `./script/build_and_run.sh --verify` でデバッグ版のビルド、起動、プロセス確認を行えます。再ビルドする前に LivePrompt を終了してください。

## 使い方

1. LivePrompt を開き、通常画面かメニューバーのアイコンから「開始」を押します。
2. 初回は macOS の「システムオーディオ録音」を許可し、英語認識・翻訳の言語モデルの準備を待ちます。
3. Zoom、Meet、Teams、ブラウザーなどで英語音声を再生します。英語字幕の後に日本語訳が現れ、英語の質問・返答案も会話に合わせて更新されます。
4. プロンプターは移動・サイズ変更できます。終了時は通常画面、プロンプター、またはメニューバーから「停止」を押します。通常画面を閉じても、メニューバーから再表示できます。

「表示と起動」でプロンプター背景の透明度を 0〜80% に設定できます。字幕の文字は薄くならず、選択値は次回の起動後も保持されます。「ログイン時に起動」をオンにするとサインイン時にアプリが開きます。macOS のログイン項目で承認が必要な場合があります。音声収録は自動開始しません。

権限は「システム設定 → プライバシーとセキュリティ → 画面収録とシステムオーディオ録音 → システムオーディオ録音のみ」で確認できます。LivePrompt は画面内容を取得しません。以前の試作版に画面収録を許可していた場合は、不要ならシステム設定で解除できます。

## プライバシーと制限

- Apple の端末内 Speech、Translation、Foundation Models を使用します。録音や文字起こしをディスクに保存せず、独自のサーバーにも送信しません。初回は macOS が言語資産を取得する場合があります。
- マイク音声、DRM などで保護された音声、話者分離、会議への自動返答は対象外です。
- 英語の提案は下書きです。会話だけでは事実に基づく返答を作れない場合、事実や約束を足さず確認の質問を提示します。発話や送信は自動で行いません。
- ローカルビルド後の初回起動では、macOS 27 で Core Audio の登録に数分かかる場合があります。「音声・言語モデルを準備中…」が完了しない場合はアプリを終了し、システムオーディオ録音の許可を確認して再起動してください。ローカルテストでは2回目以降の開始は速やかでした。

## 開発と確認状況

SwiftPM と Apple の Core Audio taps、SpeechAnalyzer、Translation、Foundation Models、SwiftUI、AppKit を使用します。開発機は macOS 27 の Apple M2。リリースビルドで、Mac の合成英語音声から字幕・訳文・提案・停止と再開始を確認しました。初回の Core Audio 準備には数分かかる場合がありました。Zoom、Meet、Teams の実会議音声ではまだ確認していません。

[要件](requirements.md)、[設計](design.md)、[作業計画](tasks.md)と[公開要件](release-requirements.md)も参照してください。

## ライセンス

MIT。詳しくは [LICENSE](LICENSE) を参照してください。
