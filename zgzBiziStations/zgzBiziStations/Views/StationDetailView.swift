import SwiftUI
import MapKit

struct StationDetailView: View {
    let station: Station
    
    // Estado para la región del mapa
    @State private var region: MKCoordinateRegion
    
    // Inicializador para configurar la región inicial del mapa
    init(station: Station) {
        self.station = station
        _region = State(initialValue: MKCoordinateRegion(
            center: station.coordinates,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "bicycle")
                            .font(.title)
                            .foregroundColor(.accentColor)
                        Spacer()
                        StatusBadgeView(isOperative: station.isOperative)
                    }
                    
                    Text(station.title)
                        .font(.title2)
                        .bold()
                }
                .padding(.vertical, 8)
            }
            
            Section {
                // Mapa con la ubicación
                MapView(station: station, region: $region)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .listRowInsets(EdgeInsets())
            }
            
            Section("Disponibilidad") {
                HStack {
                    StatView(
                        value: station.bikes,
                        title: "Bicis disponibles",
                        icon: "bicycle.circle.fill"
                    )
                    Spacer()
                    StatView(
                        value: station.slots,
                        title: "Anclajes libres",
                        icon: "parkingsign.circle.fill"
                    )
                }
                .padding(.vertical, 8)
            }
            
            Section("Última actualización") {
                Text(station.formattedLastUpdated)
                    .foregroundColor(.secondary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Vista del mapa
struct MapView: View {
    let station: Station
    @Binding var region: MKCoordinateRegion
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [station]) { station in
            MapAnnotation(coordinate: station.coordinates) {
                VStack {
                    Image(systemName: "bicycle.circle.fill")
                        .font(.title)
                        .foregroundColor(.accentColor)
                    
                    Text(station.title)
                        .font(.caption)
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// Preview
#Preview {
    NavigationStack {
        StationDetailView(station: Station(
            id: "1",
            title: "Estación de prueba",
            geometry: Geometry(
                type: "Point",
                coordinates: [-0.8891, 41.6488]
            ),
            estado: "activa",
            bicisDisponibles: 5,
            anclajesDisponibles: 10,
            lastUpdated: "2025-02-23T23:24:04"
        ))
    }
} 