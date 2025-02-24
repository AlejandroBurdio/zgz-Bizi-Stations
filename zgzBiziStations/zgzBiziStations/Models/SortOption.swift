enum SortOption: String, CaseIterable {
    case alphabetical = "Alfabético"
    case distance = "Cercanía"
    
    var icon: String {
        switch self {
        case .alphabetical: return "textformat.abc"
        case .distance: return "location.fill"
        }
    }
} 