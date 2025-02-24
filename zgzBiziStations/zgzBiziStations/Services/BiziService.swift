import Foundation
import CoreLocation

class BiziService {
    private let baseURL = "https://www.zaragoza.es/sede/servicio/urbanismo-infraestructuras/estacion-bicicleta"
    
    // Obtener todas las estaciones
    func fetchAllStations() async throws -> [Station] {
        var components = URLComponents(string: baseURL + ".json")
        components?.queryItems = [
            URLQueryItem(name: "rf", value: "html"),
            URLQueryItem(name: "srsname", value: "wgs84"),
            URLQueryItem(name: "rows", value: "1000")
        ]
        
        return try await performRequest(with: components?.url)
    }
    
    // Buscar una estación específica por ID o título
    func searchStation(query: String) async throws -> [Station] {
        var components = URLComponents(string: baseURL + ".json")
        components?.queryItems = [
            URLQueryItem(name: "rf", value: "html"),
            URLQueryItem(name: "srsname", value: "wgs84"),
            URLQueryItem(name: "q", value: query)
        ]
        
        return try await performRequest(with: components?.url)
    }
    
    private func performRequest(with url: URL?) async throws -> [Station] {
        guard let url = url else {
            throw URLError(.badURL)
        }
        
        print("Requesting URL: \(url.absoluteString)") // Para debug
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Para debug
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Response JSON: \(jsonString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError(message: errorResponse.mensaje)
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let stationsResponse = try decoder.decode(StationsResponse.self, from: data)
        return stationsResponse.result
    }
}

// Estructuras para manejar errores de la API
struct APIErrorResponse: Codable {
    let status: Int
    let mensaje: String
}

struct APIError: LocalizedError {
    let message: String
    
    var errorDescription: String? {
        message
    }
} 