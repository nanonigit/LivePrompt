# LivePrompt 作業計画

1. SwiftPM の macOS GUI アプリ骨組み、Info.plist、起動スクリプトを作る。
2. Core Audio taps のシステム音声取得と SpeechAnalyzer の英語逐次認識を実装する。
3. Apple Translation の逐次翻訳とエラー表示を実装する。
4. FoundationModels で短い英語の質問・返答案を自動生成し、更新間隔と古い結果の破棄を実装する。
5. 通常ウィンドウと半透明のプロンプターを実装し、開始・停止・コピー操作を結ぶ。
6. SwiftPM でビルドし、音声入力なしでの起動・停止・失敗表示を確認する。可能なら英語再生音声で字幕と訳文を確認する。
7. 差分と権限・保存・終了処理を点検し、未検証の点を README に明記する。
