import SwiftUI

struct LessonBrowserView: View {

    @StateObject private var store = ProgressStore()
    private let curriculum = LessonCurriculum.all

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(curriculum) { lesson in
                        let unlocked = store.isUnlocked(lesson, in: curriculum)
                        let stars = store.bestStars(for: lesson.id)
                        Group {
                            if unlocked {
                                NavigationLink(destination: ExerciseView(lesson: lesson, store: store)) {
                                    LessonCardView(lesson: lesson, stars: stars, isUnlocked: true)
                                }
                                .buttonStyle(.plain)
                            } else {
                                LessonCardView(lesson: lesson, stars: stars, isUnlocked: false)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Ear Trainer")
        }
    }
}
