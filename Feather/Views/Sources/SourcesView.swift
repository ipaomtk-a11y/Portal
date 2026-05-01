//
//  SourcesView.swift
//  IPAOMTK
//
//  Professional redesign for IPAOMTK
//

import CoreData
import AltSourceKit
import SwiftUI
import NimbleViews

struct SourcesView: View {
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
    
    var body: some View {
        NBNavigationView(.localized("Sources")) {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 22) {
                        _headerView
                        
                        if _filteredSources.isEmpty {
                            _emptyState
                        } else {
                            _allRepositoriesCard
                            _repositoriesSection
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 120)
                }
                .background(Color(.systemBackground).ignoresSafeArea())
                .searchable(text: $_searchText, placement: .platform())
                .refreshable {
                    await viewModel.fetchSources(_sources, refresh: true)
                }
                
                _addFloatingButton
                    .padding(.trailing, 18)
                    .padding(.bottom, 28)
            }
            .sheet(isPresented: $_isAddingPresenting) {
                SourcesAddView()
            }
        }
        .task(id: Array(_sources)) {
            await viewModel.fetchSources(_sources)
        }
        #if !NIGHTLY && !DEBUG
        .onAppear {
            guard _shouldStar < 6 else { return }
            _shouldStar += 1
            guard _shouldStar == 6 else { return }
            
            let telegram = UIAlertAction(title: "Telegram", style: .default) { _ in
                UIApplication.open("https://t.me/ipaomtk")
            }
            
            let cancel = UIAlertAction(title: .localized("Dismiss"), style: .cancel)
            
            UIAlertController.showAlert(
                title: "Enjoying IPAOMTK?",
                message: "Join our Telegram channel for more updates!",
                actions: [telegram, cancel]
            )
        }
        #endif
    }
}

extension SourcesView {
    private var _headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Sources")
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)
                
                Text("\(_filteredSources.count) repositories connected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                _isAddingPresenting = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        LinearGradient(
                            colors: [.indigo, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .blue.opacity(0.35), radius: 14, x: 0, y: 8)
            }
            .disabled(_addingSourceLoading)
        }
    }
    
    private var _allRepositoriesCard: some View {
        NavigationLink {
            SourceAppsView(object: Array(_sources), viewModel: viewModel)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    LinearGradient(
                        colors: [.indigo, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Image(systemName: "globe.desk.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(.localized("All Repositories"))
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text(.localized("See all apps from your sources"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 7)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var _repositoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(.localized("Repositories"))
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(_filteredSources.count)")
                    .font(.footnote.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
            }
            
            VStack(spacing: 12) {
                ForEach(_filteredSources) { source in
                    NavigationLink {
                        SourceAppsView(object: [source], viewModel: viewModel)
                    } label: {
                        PrivateSourcesCellView(source: source)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var _emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "globe.desk.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(.accentColor)
            
            Text(.localized("No Repositories"))
                .font(.title2.bold())
            
            Text(.localized("Get started by adding your first repository."))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                _isAddingPresenting = true
            } label: {
                Label(.localized("Add Source"), systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.indigo, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.top, 80)
    }
    
    private var _addFloatingButton: some View {
        Button {
            _isAddingPresenting = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                Text(.localized("Add Source"))
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [.indigo, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .blue.opacity(0.35), radius: 18, x: 0, y: 10)
        }
        .disabled(_addingSourceLoading)
    }
}

private struct PrivateSourcesCellView: View {
    let source: AltSource
    
    var body: some View {
        HStack(spacing: 14) {
            sourceIcon
            
            VStack(alignment: .leading, spacing: 6) {
                Text(source.name ?? "Repository")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("Private Repository")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Label("Repository", systemImage: "globe")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.indigo)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
        )
    }
    
    private var sourceIcon: some View {
        AsyncImage(url: source.iconURL) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            ZStack {
                LinearGradient(
                    colors: [.indigo, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                Image(systemName: "globe.desk.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 58, height: 58)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
