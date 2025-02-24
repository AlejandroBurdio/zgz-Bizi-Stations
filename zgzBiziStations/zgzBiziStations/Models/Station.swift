import Foundation
import CoreLocation

// El modelo principal que representa la respuesta de la API
struct StationsResponse: Codable {
    let totalCount: Int
    let start: Int
    let rows: Int
    let result: [Station]
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "totalCount"
        case start = "start"
        case rows = "rows"
        case result = "result"
    }
}

struct Station: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let geometry: Geometry
    let estado: String
    let bicisDisponibles: Int
    let anclajesDisponibles: Int
    let lastUpdated: String
    
    // Computed properties para facilitar el uso
    var isOperative: Bool {
        estado == "IN_SERVICE"
    }
    
    var bikes: Int { bicisDisponibles }
    var slots: Int { anclajesDisponibles }
    
    var coordinates: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: geometry.coordinates[1],
            longitude: geometry.coordinates[0]
        )
    }
    
    var formattedLastUpdated: String {
        // Crear un DateFormatter para parsear la fecha original
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        // Intentar parsear la fecha
        guard let date = inputFormatter.date(from: String(lastUpdated.prefix(19))) else {
            return lastUpdated
        }
        
        // Crear un DateFormatter para el formato deseado
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "HH:mm:ss dd-MM-yyyy"
        outputFormatter.locale = Locale(identifier: "es_ES")
        
        return outputFormatter.string(from: date)
    }
    
    // Para conformar con Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Station, rhs: Station) -> Bool {
        lhs.id == rhs.id
    }
}

struct Geometry: Codable {
    let type: String
    let coordinates: [Double]
}

enum StationState {
    case operative
    case inoperative
}

// Extensión para manejar la decodificación de las coordenadas
extension CLLocationCoordinate2D: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let coordinates = try container.decode([Double].self, forKey: .coordinates)
        self.init(latitude: coordinates[1], longitude: coordinates[0])
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode([longitude, latitude], forKey: .coordinates)
    }
    
    private enum CodingKeys: String, CodingKey {
        case coordinates = "coordinates"
    }
}
