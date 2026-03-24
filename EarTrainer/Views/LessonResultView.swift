import SwiftUI

struct LessonResultView: View {

    let lesson: Lesson
    let phraseScores: [Double]
    let store: ProgressStore

    @Environment(\.dismiss) private var dismiss

    private var averageScore: Double {
        PitchGrader.lessonScore(phraseScores: phraseScores)
    }

    private var stars: Int {
        PitchGrader.stars(forAverageScore: averageScore)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(lesson.title)
                .font(.title.bold())

            // Star display
            HStack(spacing: 12) {
                ForEach(1...3, id: \.self) { i in
                    Image(systemName: i <= stars ? "star.fill" : "star")
                        .font(.system(size: 44))
                        .foregroundColor(.yellow)
                }
            }

            Text("\(Int(averageScore * 100))% average")
                .font(.title2)
                .foregroundColor(.secondary)

            if stars < 3 {
                Text("3 stars required to unlock the next lesson.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            HStack(spacing: 16) {
                Button("Try Again") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                if stars == 3 {
                    Button("Next Lesson") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .onAppear {
            store.record(lessonID: lesson.id, stars: stars)
        }
    }
}
