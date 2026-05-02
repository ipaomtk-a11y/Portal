//
//  SourcesView.swift
//  IPAOMTK
//

import CoreData
import AltSourceKit
import SwiftUI
import NimbleViews

struct SourcesView: View {
    
    @StateObject var viewModel = SourcesViewModel.shared
    @State private var _isAddingPresenting = false
    @State private var _searchText = ""
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)]
    ) private var _sources: FetchedResults<AltSource>
    
    private var filtered: [AltSource] {
        _sources.filter {
            _searchText.isEmpty ||
            ($0.name?.localizedCaseInsensitiveContains(_searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // HEADER
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sources")
                            .font(.largeTitle.bold())
                        
                        Text("\(filtered.count) repositories connected")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                    // ALL REPO CARD
                    NavigationLink {
                        SourceAppsView(object: Array(_sources), viewModel: viewModel)
                    } label: {
                        HStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(colors: [.blue, .purple],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing)
                                )
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: "square.grid.2x2")
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading) {
                                Text("All Repositories")
                                    .font(.headline)
                                
                                Text("Explore apps from all sources")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                    
                    
                    // LIST
                    VStack(spacing: 12) {
                        ForEach(filtered) { source in
                            NavigationLink {
                                SourceAppsView(object: [source], viewModel: viewModel)
                            } label: {
                                SourcesCellView(source: source)
                            }
                        }
                    }
                    
                }
                .padding()
            }
            .searchable(text: $_searchText)
            .toolbar {
                Button {
                    _isAddingPresenting = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $_isAddingPresenting) {
                SourcesAddView()
            }
        }
    }
}
