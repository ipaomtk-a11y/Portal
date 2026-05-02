import SwiftUI
import NimbleViews
import AltSourceKit
import NimbleJSON
import OSLog
import UIKit.UIImpactFeedbackGenerator

// MARK: - View
struct SourcesAddView: View {
    typealias RepositoryDataHandler = Result<ASRepository, Error>
    @Environment(\.dismiss) var dismiss

    private let _dataService = NBFetchService()
    
    @State private var _filteredRecommendedSourcesData: [(url: URL, data: ASRepository)] = []
    
    private func _refreshFilteredRecommendedSourcesData() {
        let filtered = recommendedSourcesData
            .filter { (url, data) in
                let id = data.id ?? url.absoluteString
                return !Storage.shared.sourceExists(id)
            }
            .sorted { lhs, rhs in
                let lhsName = lhs.data.name ?? ""
                let rhsName = rhs.data.name ?? ""
                return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
            }
        _filteredRecommendedSourcesData = filtered
    }
    
    @State var recommendedSourcesData: [(url: URL, data: ASRepository)] = []
    
    let recommendedSources: [URL] = [
        "https://file.ipaomtk.com/repo/ipaomtk-repo.json",
        "https://raw.githubusercontent.com/paigely/Navic/refs/heads/master/app-repo.json",
        "https://altstore.oatmealdome.me/",
        "https://pokemmo.com/altstore/",
        "https://provenance-emu.com/apps.json",
        "https://community-apps.sidestore.io/sidecommunity.json",
        "https://stikdebug.xyz/index.json",
        "https://alt.getutm.app",
        "https://alt.crystall1ne.dev/",
        "https://xitrix.github.io/iTorrent/AltStore.json"
    ].compactMap { URL(string: $0) }
    
    @State private var _isImporting = false
    @State private var _sourceURL = ""
    
    // MARK: Body
    var body: some View {
        NBNavigationView(.localized("Add Source"), displayMode: .inline) {
            ScrollView {
                VStack(spacing: 22) {
                    _urlInputSection
                    _actionButtonsSection
                    _featuredRepositoriesSection
                    _footerSection
                }
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if _isImporting {
                        ProgressView()
                    } else {
                        Button(.localized("Save")) {
                            FR.handleSource(_sourceURL) {
                                dismiss()
                            }
                        }
                        .fontWeight(.bold)
                        .disabled(_sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .task {
                await _fetchRecommendedRepositories()
            }
        }
    }
}

// MARK: - UI
extension SourcesAddView {
    private var _urlInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.localized("Source URL"))
                .font(.footnote.weight(.bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 34, height: 34)
                    
                    Image(systemName: "link")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                TextField(.localized("Enter Source URL"), text: $_sourceURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
            
            Text(.localized("Only AltStore-compatible repositories are supported."))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
        .padding(.horizontal)
    }
    
    private var _actionButtonsSection: some View {
        HStack(spacing: 12) {
            _actionButton(
                title: .localized("Import"),
                icon: "square.and.arrow.down.fill",
                color: .blue
            ) {
                _isImporting = true
                _fetchImportedRepositories(UIPasteboard.general.string) {
                    dismiss()
                }
            }
            
            _actionButton(
                title: .localized("Export"),
                icon: "square.and.arrow.up.fill",
                color: .orange
            ) {
                _exportSources()
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var _featuredRepositoriesSection: some View {
        if _filteredRecommendedSourcesData.isEmpty {
            VStack(spacing: 10) {
                ProgressView()
                
                Text(.localized("Loading featured repositories..."))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(.localized("Featured Repositories"))
                        .font(.footnote.weight(.bold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(_filteredRecommendedSourcesData.count)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 4)
                
                VStack(spacing: 12) {
                    ForEach(_filteredRecommendedSourcesData, id: \.url) { (url, source) in
                        _featuredCard(url: url, source: source)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var _footerSection: some View {
        VStack(spacing: 8) {
            Link(String.localized("Telegram..."), destination: URL(string: "https://t.me/ipaomtk")!)
                .font(.footnote.weight(.semibold))
            
            Text(.localized("Want to be featured? Contact us on Telegram."))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.top, 4)
    }
    
    private func _actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func _featuredCard(url: URL, source: ASRepository) -> some View {
        HStack(spacing: 14) {
            AsyncImage(url: source.currentIconURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ZStack {
                    LinearGradient(
                        colors: [.blue.opacity(0.85), .purple.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 54, height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name ?? "Unknown")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(url.host ?? "Repository")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 8)
            
            Button {
                Storage.shared.addSource(url, repository: source) { _ in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    _refreshFilteredRecommendedSourcesData()
                }
            } label: {
                Text(.localized("Add"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(
                        LinearGradient(
                            colors: [.blue, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
    
    private func _exportSources() {
        let sources = Storage.shared.getSources()
        guard !sources.isEmpty else {
            UIAlertController.showAlertWithOk(
                title: .localized("Error"),
                message: .localized("No sources to export")
            )
            return
        }
        
        UIPasteboard.general.string = sources.map {
            $0.sourceURL!.absoluteString
        }.joined(separator: "\n")
        
        UIAlertController.showAlertWithOk(
            title: .localized("Success"),
            message: .localized("Sources copied to clipboard")
        ) {
            dismiss()
        }
    }
}

// MARK: - Logic
extension SourcesAddView {
    private func _fetchRecommendedRepositories() async {
        let fetched = await _concurrentFetchRepositories(from: recommendedSources)
        await MainActor.run {
            recommendedSourcesData = fetched
            _refreshFilteredRecommendedSourcesData()
        }
    }
    
    private func _fetchImportedRepositories(_ code: String?, competion: @escaping () -> Void) {
        guard let code else {
            _isImporting = false
            return
        }
        
        let handler = ASDeobfuscator(with: code)
        let repoUrls = handler.decode().compactMap { URL(string: $0) }
        
        guard !repoUrls.isEmpty else {
            _isImporting = false
            return
        }
        
        Task {
            let fetched = await _concurrentFetchRepositories(from: repoUrls)
            let dict = Dictionary(fetched, uniquingKeysWith: { first, _ in first })
            await MainActor.run {
                Storage.shared.addSources(repos: dict) { _ in
                    competion()
                }
            }
        }
    }
    
    private func _concurrentFetchRepositories(from urls: [URL]) async -> [(url: URL, data: ASRepository)] {
        await withTaskGroup(of: (URL, ASRepository)?.self) { group in
            for url in urls {
                group.addTask {
                    await withCheckedContinuation { continuation in
                        _dataService.fetch<ASRepository>(from: url) { (result: RepositoryDataHandler) in
                            switch result {
                            case .success(let repo):
                                continuation.resume(returning: (url, repo))
                            case .failure(let error):
                                Logger.misc.error("Failed to fetch \(url): \(error.localizedDescription)")
                                continuation.resume(returning: nil)
                            }
                        }
                    }
                }
            }
            
            var results: [(url: URL, data: ASRepository)] = []
            
            for await result in group {
                if let result {
                    results.append((url: result.0, data: result.1))
                }
            }
            
            return results
        }
    }
}
