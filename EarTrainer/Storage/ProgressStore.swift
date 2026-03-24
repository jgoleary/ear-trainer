import Foundation

@MainActor
final class ProgressStore: ObservableObject {

    private let key = "lessonProgress"
    @Published private(set) var progressByID: [String: LessonProgress] = [:]

    init() {
        load()
        // Lesson 1 is always unlocked — seed it if absent
        if progressByID["lesson-01"] == nil {
            progressByID["lesson-01"] = LessonProgress(lessonID: "lesson-01", bestStars: 0)
            save()
        }
    }

    func bestStars(for lessonID: String) -> Int {
        progressByID[lessonID]?.bestStars ?? 0
    }

    func isUnlocked(_ lesson: Lesson, in curriculum: [Lesson]) -> Bool {
        if lesson.id == "lesson-01" { return true }
        guard let idx = curriculum.firstIndex(where: { $0.id == lesson.id }), idx > 0 else { return false }
        let previous = curriculum[idx - 1]
        return bestStars(for: previous.id) >= 3
    }

    func record(lessonID: String, stars: Int) {
        let clamped = max(0, min(3, stars))   // memberwise init bypasses didSet clamp
        let current = progressByID[lessonID]?.bestStars ?? 0
        if clamped > current {
            progressByID[lessonID] = LessonProgress(lessonID: lessonID, bestStars: clamped)
            save()
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: LessonProgress].self, from: data)
        else { return }
        progressByID = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(progressByID) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
