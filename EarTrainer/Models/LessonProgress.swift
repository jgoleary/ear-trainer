struct LessonProgress: Codable {
    let lessonID: String
    var bestStars: Int {      // clamped to 0–3
        didSet { bestStars = max(0, min(3, bestStars)) }
    }
}
