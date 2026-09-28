# LivePrompt 公開設計

## リポジトリ

- アプリ本体を独立した Git リポジトリにする。親の `/Users/naoki/Documents` リポジトリには変更を加えない。
- 英語を `README.md`、日本語を `README.ja.md` とし、冒頭で相互にリンクする。ライセンスは MIT。
- `.gitignore` は `.build/` と `dist/` のほか、生成アーカイブや秘密情報を除外する。

## ビルドと配布

- `script/package_app.sh` は SwiftPM のリリースビルドから `.app` を組み立て、Info.plist とローカル ad-hoc 署名を付ける。実行中アプリを停止する副作用を持たせない。
- `script/build_and_run.sh` は開発用ランチャーとして package script を呼ぶ。
- GitHub Release では GitHub の自動ソースアーカイブを Homebrew Formula の取得元とする。署名済み・公証済みバイナリは Developer ID が用意できるまで公開しない。
- `homebrew-liveprompt/Formula/liveprompt.rb` はタグのアーカイブを SHA256 で固定し、ユーザーの Mac で `.app` をビルドする。ランチャー `liveprompt` と明示した使い方を提供する。
- Homebrew の外側サンドボックス内では SwiftPM の内側サンドボックスを作れないため、Formula からのビルド時だけ `swift build --disable-sandbox` を指定する。通常の手動ビルドでは SwiftPM の既定動作を保つ。
- Formula の管理外である `/Applications` には Formula のインストール処理から書き込まない。必要なユーザーには Homebrew の安定した `opt` パスを指すシンボリックリンクを案内する。

## 検証

- クリーン clone の SwiftPM ビルド、アプリ起動、音声収録、GitHub Release のタグとアーカイブ、Formula の audit/install/test を順に確認する。
- 外部に出す前に staged diff、秘密情報、再配布不可の音声・モデル、署名状態を点検する。
