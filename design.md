# LivePrompt 設計

## 画面設計の根拠

Lazyweb のデスクトップ画面調査では、Ava の翻訳設定例に翻訳先を明示する構成、Zoom の会議画面に発話と字幕の分離、Apollo の会議画面に会話を見ながら使う提案領域が見られた。検索の関連度は字幕で strong、提案で moderate であり、重ね表示そのものの十分な実例ではない。初版は英語原文を小さく、日本語訳を大きくし、その下に短い英語の質問・返答案を固定表示する。

## ウィンドウ

- `WindowGroup` は開始・停止、許可、モデル状態、直近の結果を示す通常の操作画面。
- AppKit の `NSPanel` は常時手前の半透明プロンプター。タイトルを隠し、ヘッダーをドラッグ領域とし、サイズ変更・閉じる・停止操作を残す。
- 表示はシステムの明暗に追随する。文字と背景のコントラストを確保し、不透明度は下の会議画面が見える程度にする。
- 原文と訳文は最新の確定発話を中心に示し、未確定の英語は控えめに表示する。提案は自動更新するが生成中に前の提案を消さない。

## データの流れ

1. `SystemAudioCapture` が Core Audio のグローバル音声タップと非公開の集約デバイスでシステム再生音声を取得し、アプリ自身の音声を除外する。集約デバイスが利用可能になるまで待ってから収録を開始する。画面内容は取得しない。
2. `LiveTranscriptionService` が英語用 `SpeechTranscriber` と `SpeechAnalyzer` を準備する。必要なモデルを `AssetInventory` で取得する。音声を適切な PCM 形式に変換して入力する。
3. 暫定の認識結果は英語字幕にだけ反映する。確定結果は会話の短いメモリに追加し、翻訳キューと提案更新へ渡す。
4. `TranslationService` は SwiftUI の `translationTask` に紐づく `TranslationSession` で英語から日本語へ順番に翻訳する。言語モデルのダウンロード許可が必要ならシステム UI に従う。
5. `SuggestionService` は利用可能な `FoundationModels` の端末内モデルに直近の確定文だけを渡す。確定文の増分があり、前回から一定時間経ったときに英語の質問案と返答案を各 1 件生成する。古い生成結果は採用しない。
6. `AppModel` が取得・認識・翻訳・提案の状態を一元管理し、両ウィンドウを更新する。

## 失敗時の動作

- 音声収録許可がない場合は開始しない。設定で許可する案内を表示する。
- 英語認識モデルが使えない、またはダウンロードに失敗した場合は理由を表示して停止する。
- 翻訳失敗時は英語字幕を残し、日本語欄にエラーを表示する。
- 文章生成モデルが使えない場合は字幕を継続し、提案欄に利用不可の理由を表示する。
- 取得停止時は各 AsyncStream、認識タスク、提案タスクを終了し、後から来た結果を無視する。

## プライバシーと境界

- 初版の音声・会話内容は保存しない。診断ログにも発話本文を記録しない。
- Apple の言語資産の初回ダウンロード以外に、独自のネットワーク送信をしない。
- 他のアプリが保護する音声や macOS が公開しない出力は取得できない。

## 主なファイル

- `App/LivePromptApp.swift`: アプリとウィンドウのライフサイクル。
- `Models/AppModel.swift`: UI 状態と処理の調停。
- `Services/SystemAudioCapture.swift`: Core Audio taps の音声入力。
- `Services/LiveTranscriptionService.swift`: 英語の逐次認識。
- `Models/AppModel.swift`: 翻訳キューと TranslationSession の実行。
- `Services/SuggestionService.swift`: 英語の質問・返答案。
- `Views/ControlView.swift`, `Views/PromptView.swift`: 通常画面と重ね表示。
- `Support/PromptPanelController.swift`: NSPanel の配置と寿命。
