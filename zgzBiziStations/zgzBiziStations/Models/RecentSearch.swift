import Foundation

struct RecentSearch: Identifiable, Codable {
    let id: UUID
    let stationTitle: String
    let date: Date
    
    init(stationTitle: String) {
        self.id = UUID()
        self.stationTitle = stationTitle
        self.date = Date()
    }
} 