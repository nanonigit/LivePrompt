# LivePrompt 公開作業

1. 音声初期化の待機と権限状態を最終バイナリで確認し、必要なら修正する。
2. `README.md` と `README.ja.md`、`LICENSE`、配布用 package script を整える。
3. アプリ用の独立 Git リポジトリを作り、秘密情報・生成物を除外してコミットする。
4. クリーン clone でビルド・起動・音声テストを実施する。
5. `nanonigit/LivePrompt` を公開してタグと GitHub Release を作る。
6. `nanonigit/homebrew-liveprompt` の Formula を作り、audit と実インストールを確認して公開する。
7. リンク、インストール手順、既知の制限を日英 README と Release で最終確認する。
8. Homebrew のサンドボックス内で SwiftPM マニフェストの実行が失敗する問題を修正し、再度 Formula の audit/install/test を通す。
9. 日英 README と Release のインストール手順に、`/Applications` への任意のリンクと既存アプリを保持する条件を記載して確認する。
10. 表示設定、30日間の日時履歴、アプリアイコンを含む v0.1.3 を検証してタグ付けし、GitHub Release と Homebrew Formula を更新する。
