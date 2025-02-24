import Foundation
import CoreLocation
import Combine

@MainActor
class StationsViewModel: NSObject, ObservableObject {
    @Published var stations: [Station] = []
    @Published var favoriteStations: Set<String> = []  // Guardamos los IDs
    @Published var searchText = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var recentSearches: [RecentSearch] = []
    @Published var filteredStations: [Station] = []
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var currentLocationString: String = "Buscando ubicación..."
    @Published var sortOption: SortOption = .alphabetical
    
    private let biziService = BiziService()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        loadFavorites()
        loadRecentSearches()
        setupLocationManager()
        Task {
            await fetchAllStations()
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func fetchAllStations() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await Task.sleep(nanoseconds: 500_000_000)
            stations = try await biziService.fetchAllStations()
            filteredStations = sortStations(stations)
        } catch {
            errorMessage = "Error al cargar las estaciones: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func sortStations(_ stations: [Station]) -> [Station] {
        switch sortOption {
        case .alphabetical:
            return stations.sorted { $0.title < $1.title }
        case .distance:
            guard let userLocation = userLocation else {
                return stations.sorted { $0.title < $1.title }
            }
            
            return stations.sorted { station1, station2 in
                let location1 = CLLocation(latitude: station1.coordinates.latitude,
                                         longitude: station1.coordinates.longitude)
                let location2 = CLLocation(latitude: station2.coordinates.latitude,
                                         longitude: station2.coordinates.longitude)
                let userCLLocation = CLLocation(latitude: userLocation.latitude,
                                              longitude: userLocation.longitude)
                
                return location1.distance(from: userCLLocation) < location2.distance(from: userCLLocation)
            }
        }
    }
    
    func filterStations() {
        if searchText.isEmpty {
            filteredStations = sortStations(stations)
        } else {
            filteredStations = sortStations(
                stations.filter { station in
                    station.title.localizedCaseInsensitiveContains(searchText)
                }
            )
        }
    }
    
    func addRecentSearch(_ station: Station) {
        let newSearch = RecentSearch(stationTitle: station.title)
        recentSearches.insert(newSearch, at: 0)
        if recentSearches.count > 3 {
            recentSearches.removeLast()
        }
        saveRecentSearches()
    }
    
    private func loadRecentSearches() {
        if let data = UserDefaults.standard.data(forKey: "RecentSearches"),
           let searches = try? JSONDecoder().decode([RecentSearch].self, from: data) {
            recentSearches = searches
        }
    }
    
    private func saveRecentSearches() {
        if let encoded = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(encoded, forKey: "RecentSearches")
        }
    }
    
    private func updateLocationString(for location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                self.currentLocationString = "No se pudo obtener la ubicación"
                print("Error geocoding: \(error)")
                return
            }
            
            if let placemark = placemarks?.first {
                let address = [
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.postalCode
                ].compactMap { $0 }.joined(separator: ", ")
                
                Task { @MainActor in
                    self.currentLocationString = "Tu ubicación: \(address)"
                }
            }
        }
    }
    
    func updateLocation() {
        currentLocationString = "Buscando ubicación..."
        locationManager.startUpdatingLocation()
    }
    
    func toggleFavorite(for station: Station) {
        if favoriteStations.contains(station.id) {
            favoriteStations.remove(station.id)
        } else {
            favoriteStations.insert(station.id)
        }
        saveFavorites()
    }
    
    func isFavorite(_ station: Station) -> Bool {
        favoriteStations.contains(station.id)
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "FavoriteStations"),
           let favorites = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favoriteStations = favorites
        }
    }
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteStations) {
            UserDefaults.standard.set(encoded, forKey: "FavoriteStations")
        }
    }
}

extension StationsViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            userLocation = location.coordinate
            updateLocationString(for: location)
            filterStations()
        }
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        currentLocationString = "No se pudo obtener la ubicación"
    }
} 