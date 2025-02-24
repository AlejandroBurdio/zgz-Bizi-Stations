import Foundation
import CoreLocation

actor LocationStorage {
    private let userDefaults: UserDefaults
    private let recentLocationsKey = "recentLocations"
    private let maxStoredLocations = 5
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func saveLocation(_ location: SearchedLocation) {
        var recentLocations = getRecentLocations()
        
        // Evitar duplicados
        recentLocations.removeAll { $0.name == location.name }
        
        // Añadir nueva ubicación al principio
        recentLocations.insert(location, at: 0)
        
        // Mantener solo las últimas 5 ubicaciones
        if recentLocations.count > maxStoredLocations {
            recentLocations = Array(recentLocations.prefix(maxStoredLocations))
        }
        
        if let encoded = try? JSONEncoder().encode(recentLocations) {
            userDefaults.set(encoded, forKey: recentLocationsKey)
        }
    }
    
    func getRecentLocations() -> [SearchedLocation] {
        guard let data = userDefaults.data(forKey: recentLocationsKey),
              let locations = try? JSONDecoder().decode([SearchedLocation].self, from: data)
        else {
            return []
        }
        return locations
    }
}

struct SearchedLocation: Codable, Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    
    var coordinates: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
} 