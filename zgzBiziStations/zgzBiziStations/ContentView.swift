//
//  ContentView.swift
//  zgzBiziStations
//
//  Created by Alejandro Burdio on 23/2/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = StationsViewModel()
    @State private var showingMap = false
    @State private var showingOnlyFavorites = false
    
    var filteredAndFavoriteStations: [Station] {
        let filtered = viewModel.filteredStations
        return showingOnlyFavorites ? filtered.filter { viewModel.isFavorite($0) } : filtered
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if viewModel.isLoading {
                    LoadingView()
                } else {
                    VStack(spacing: 0) {
                        // Buscador
                        SearchBar(text: $viewModel.searchText)
                            .padding()
                            .onChange(of: viewModel.searchText) { _ in
                                viewModel.filterStations()
                            }
                        
                        // Ubicación actual
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.accentColor)
                            Text(viewModel.currentLocationString)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button {
                                viewModel.updateLocation()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        
                        // Búsquedas recientes
                        if viewModel.searchText.isEmpty && !viewModel.recentSearches.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Búsquedas recientes")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.recentSearches) { search in
                                            Button {
                                                viewModel.searchText = search.stationTitle
                                                viewModel.filterStations()
                                            } label: {
                                                HStack {
                                                    Image(systemName: "clock.arrow.circlepath")
                                                    Text(search.stationTitle)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(Color(.systemGray6))
                                                .cornerRadius(20)
                                            }
                                            .foregroundColor(.primary)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.bottom)
                        }
                        
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredAndFavoriteStations) { station in
                                    NavigationLink(destination: StationDetailView(station: station)) {
                                        StationCardView(station: station, viewModel: viewModel)
                                    }
                                    .onTapGesture {
                                        viewModel.addRecentSearch(station)
                                    }
                                }
                            }
                            .padding()
                        }
                        .refreshable {
                            await viewModel.fetchAllStations()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Estaciones Zaragoza Bici")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Botón de ordenación
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button {
                                    viewModel.sortOption = option
                                } label: {
                                    Label(option.rawValue, systemImage: option.icon)
                                }
                                .disabled(option == viewModel.sortOption)
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.white)
                        }
                        
                        // Menú de opciones
                        Menu {
                            Button {
                                showingOnlyFavorites.toggle()
                            } label: {
                                Label(
                                    showingOnlyFavorites ? "Ver todas" : "Ver favoritas",
                                    systemImage: showingOnlyFavorites ? "star.fill" : "star"
                                )
                            }
                            
                            Button {
                                showingMap = true
                            } label: {
                                Label("Mapa", systemImage: "map")
                            }
                            
                            Button {
                                Task {
                                    await viewModel.fetchAllStations()
                                }
                            } label: {
                                Label("Actualizar", systemImage: "arrow.clockwise")
                            }
                            .disabled(viewModel.isLoading)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingMap) {
                AllStationsMapView(stations: viewModel.stations, viewModel: viewModel)
            }
            .toolbarBackground(Color.accentColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onChange(of: viewModel.sortOption) { _ in
            viewModel.filterStations()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Buscar estación...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct StationCardView: View {
    let station: Station
    @ObservedObject var viewModel: StationsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bicycle")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text(station.title)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                
                Spacer()
                
                Button {
                    viewModel.toggleFavorite(for: station)
                } label: {
                    Image(systemName: viewModel.isFavorite(station) ? "star.fill" : "star")
                        .foregroundColor(viewModel.isFavorite(station) ? .yellow : .gray)
                }
                .padding(.horizontal, 4)
                
                StatusBadgeView(isOperative: station.isOperative)
            }
            
            HStack(spacing: 16) {
                StatView(
                    value: station.bikes,
                    title: "Bicis",
                    icon: "bicycle.circle.fill"
                )
                
                Spacer()
                
                StatView(
                    value: station.slots,
                    title: "Anclajes",
                    icon: "parkingsign.circle.fill"
                )
                
                Spacer()
                
                Text(station.formattedLastUpdated)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(radius: 2)
        )
        .frame(maxWidth: .infinity)
    }
}

struct StatView: View {
    let value: Int
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text("\(value)")
                    .font(.headline)
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Cargando estaciones...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
