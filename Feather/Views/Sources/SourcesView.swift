import CoreData
import AltSourceKit
import SwiftUI
import NimbleViews

// MARK: - View
struct SourcesView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    #if !NIGHTLY && !DEBUG
    @AppStorage("Feather.shouldStar") private var _shouldStar: Int = 0
    #endif
    
    @StateObject var viewModel = SourcesViewModel.shared
    @State private var _isAddingPresenting = false
    @State private var _addingSourceLoading = false
    @State private var _searchText = ""
    
    private var _filteredSources: [AltSource] {
        _sources.filter {
            _searchText.isEmpty ||
            ($0.name?.localizedCaseInsensitiveContains(_searchText) ?? false)
        }
    }
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var _sources: FetchedResults<AltSource>
    
    // MARK: Body
    var body: some View {
        NBNavigationView(.localized("Sources")) {
            List {
                if !_filteredSources.isEmpty {
                    Section {
                        _allRepositoriesCard
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    
                    NBSection(
                        .localized("Repositories"),
                        secondary: _filteredSources.count.description
                    ) {
                        ForEach(_filteredSources) { source in
                            NavigationLink {
                                SourceAppsView(object: [source], viewModel: viewModel)
                            } label: {
                                SourcesCellView(source: source)
                                    .padding(.vertical, 3)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .searchable(text: $_searchText, placement: .platform())
            .overlay {
                if _filteredSources.isEmpty {
                    _emptyStateView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        _isAddingPresenting = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .disabled(_addingSourceLoading)
                }
            }
            .refreshable {
                await viewModel.fetchSources(_sources, refresh: true)
            }
            .sheet(isPresented: $_isAddingPresenting) {
                SourcesAddView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .task(id: Array(_sources)) {
            await viewModel.fetchSources(_sources)
        }
        #if !NIGHTLY && !DEBUG
        .onAppear {
            _handleAppRating()
        }
        #endif
    }
}

// MARK: - Components
extension SourcesView {
    private var _allRepositoriesCard: some View {
        NavigationLink {
            SourceAppsView(object: Array(_sources), viewModel: viewModel)
        } label: {
            HStack(spacing: 15) {
                ZStack {
                    LinearGradient(
                        colors: [.blue, .indigo, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .blue.opacity(0.25), radius: 10, x: 0, y: 5)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(.localized("All Repositories"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(.localized("Explore all apps from every source"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer(minLength: 8)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.45))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.primary.opacity(0.045), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.045), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func _emptyStateView() -> some View {
        if #available(iOS 17, *) {
            ContentUnavailableView {
                Label(.localized("No Repositories"), systemImage: "globe.asia.australia.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.blue)
            } description: {
                Text(.localized("Stay updated by adding your favorite app repositories here."))
            } actions: {
                Button {
                    _isAddingPresenting = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text(.localized("Add First Source"))
                    }
                    .font(.headline.weight(.bold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 13)
                    .background(
                        LinearGradient(
                            colors: [.blue, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: .blue.opacity(0.25), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
            }
        } else {
            VStack(spacing: 14) {
                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text(.localized("No Repositories"))
                    .font(.title2.bold())
                
                Text(.localized("Stay updated by adding your favorite app repositories here."))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button {
                    _isAddingPresenting = true
                } label: {
                    Text(.localized("Add First Source"))
                        .font(.headline.weight(.bold))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 13)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            .padding()
        }
    }
    
    #if !NIGHTLY && !DEBUG
    private func _handleAppRating() {
        guard _shouldStar < 6 else { return }
        _shouldStar += 1
        guard _shouldStar == 6 else { return }
        
        let telegram = UIAlertAction(title: "Telegram", style: .default) { _ in
            UIApplication.open("https://t.me/ipaomtk")
        }
        
        let cancel = UIAlertAction(title: .localized("Dismiss"), style: .cancel)
        
        UIAlertController.showAlert(
            title: "Enjoying IPAOMTK",
            message: "Join our Telegram channel for more updates and support!",
            actions: [telegram, cancel]
        )
    }
    #endif
}
