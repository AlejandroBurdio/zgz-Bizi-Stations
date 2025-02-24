import SwiftUI
import MapKit

struct AllStationsMapView: View {
    let stations: [Station]
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: StationsViewModel
    
    // Estado para la región del mapa
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.6488, longitude: -0.8891), // Valor por defecto
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        NavigationStack {
            Map(coordinateRegion: $region, annotationItems: stations) { station in
                MapAnnotation(coordinate: station.coordinates) {
                    NavigationLink(destination: StationDetailView(station: station)) {
                        Image(systemName: "bicycle.circle.fill")
                            .font(.title)
                            .foregroundColor(station.isOperative ? .accentColor : .red)
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .shadow(radius: 2)
                            )
                    }
                }
            }
            .navigationTitle("Mapa de Estaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let location = viewModel.userLocation {
                    region = MKCoordinateRegion(
                        center: location,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                }
            }
        }
    }
} 