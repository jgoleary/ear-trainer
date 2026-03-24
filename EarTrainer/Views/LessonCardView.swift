import SwiftUI

struct LessonCardView: View {

    let lesson: Lesson
    let stars: Int           // 0–3 earned
    let isUnlocked: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.headline)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                Text(lesson.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            if isUnlocked {
                HStack(spacing: 2) {
                    ForEach(1...3, id: \.self) { i in
                        Image(systemName: i <= stars ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
}
