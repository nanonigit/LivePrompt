import Foundation

struct CaptionLine: Identifiable {
    let id: UUID
    let english: String
    var japanese: String?

    init(english: String) {
        self.id = UUID()
        self.english = english
    }
}

struct EnglishSuggestion {
    let question: String
    let reply: String
}

enum CaptureState: Equatable {
    case idle
    case preparing
    case listening
    case stopping
    case failed(String)
}
