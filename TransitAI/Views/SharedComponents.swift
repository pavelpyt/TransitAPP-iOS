import SwiftUI

// MARK: - Line Tag Component (Shared)

struct LineTag: View {
    let line: String
    
    var color: Color {
        switch line {
        case "A": return .green
        case "B": return .yellow
        case "C": return .red
        default: return .cyan
        }
    }
    
    var body: some View {
        Text(line)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.black)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
    }
}
