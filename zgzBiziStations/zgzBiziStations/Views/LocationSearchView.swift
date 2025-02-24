import SwiftUI
import MapKit

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LocationSearchViewModel()
    let onLocationSelected: (CLLocationCoordinate2D, String) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Buscar ubicación...", text: $viewModel.searchText)
                }
                
                Section {
                    ForEach(viewModel.searchResults, id: \.self) { completion in
                        Button {
                            Task {
                                if let location = await viewModel.getCoordinates(for: completion) {
                                    onLocationSelected(location, completion.title)
                                }
                            }
                        } label: {
                            VStack(alignment: .leading) {
                                Text(completion.title)
                                    .font(.headline)
                                Text(completion.subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Buscar ubicación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

@MainActor
class LocationSearchViewModel: NSObject, ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [MKLocalSearchCompletion] = []
    
    private var searchCompleter: MKLocalSearchCompleter
    
    override init() {
        searchCompleter = MKLocalSearchCompleter()
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .query
        
        // Establecer la región para Zaragoza
        let zaragozaRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.6488, longitude: -0.8891),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        searchCompleter.region = zaragozaRegion
        
        // Observar cambios en el texto de búsqueda
        Task {
            for await text in $searchText.values {
                searchCompleter.queryFragment = text
            }
        }
    }
    
    func getCoordinates(for completion: MKLocalSearchCompletion) async -> CLLocationCoordinate2D? {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        do {
            let response = try await search.start()
            return response.mapItems.first?.placemark.coordinate
        } catch {
            print("Error getting coordinates: \(error)")
            return nil
        }
    }
}

extension LocationSearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error en la búsqueda: \(error.localizedDescription)")
    }
}

#Preview {
    LocationSearchView { _, _ in }
} 