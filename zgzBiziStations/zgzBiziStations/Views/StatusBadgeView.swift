import SwiftUI

struct StatusBadgeView: View {
    let isOperative: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(isOperative ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(isOperative ? "Activa" : "Inactiva")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }
}

#Preview {
    StatusBadgeView(isOperative: true)
} 