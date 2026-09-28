# LivePrompt 公開要件

- `nanonigit/LivePrompt` を公開 GitHub リポジトリとして Git 管理する。ソース、日英 README、MIT ライセンスを含める。
- 最新タグの GitHub Release に、確認済みの内容・必要な macOS/Apple Intelligence・既知の制限を日英で記載する。
- Developer ID 署名証明書がないため、未署名のバイナリ配布を通常インストーラーとして案内しない。Homebrew は `nanonigit/homebrew-liveprompt` の個人 Tap からソースをビルドする Formula とする。
- 秘密情報、個人会議の音声、ビルド成果物、Apple の言語モデルを Git に含めない。
- 公開前にクリーンな clone でビルド・起動し、音声収録、字幕、訳文、提案、停止、再開始を確認する。Homebrew Formula は `brew audit` と実インストールを確認する。
- 音声収録の初期化待機が再現する場合は、字幕・訳文・提案と停止・再開始が通ることを確認し、初回待機と実会議未検証を明記してプレリリースとする。収録が開始しない場合は公開しない。
