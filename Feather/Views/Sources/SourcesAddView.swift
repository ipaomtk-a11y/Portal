//
//  SourcesAddView.swift
//  IPAOMTK
//
//  Professional redesign for IPAOMTK
//

import SwiftUI
import NimbleViews
import AltSourceKit
import NimbleJSON
import OSLog
import UIKit.UIImpactFeedbackGenerator
import NukeUI

struct SourcesAddView: View {
	typealias RepositoryDataHandler = Result<ASRepository, Error>
	
	@Environment(\.dismiss) var dismiss
	
	private let _dataService = NBFetchService()
	
	@State private var _filteredRecommendedSourcesData: [(url: URL, data: ASRepository)] = []
	@State var recommendedSourcesData: [(url: URL, data: ASRepository)] = []
	
	let recommendedSources: [URL] = [
    "https://file.ipaomtk.com/repo/ipaomtk-repo.json",
    "https://ashtemobile.tututweak.com/Ashtemobile.json"

].map { URL(string: $0)! }

	
	@State private var _isImporting = false
	@State private var _sourceURL = ""
	
	var body: some View {
		NBNavigationView(.localized("Add Source"), displayMode: .inline) {
			ScrollView {
				VStack(spacing: 22) {
					_headerCard
					_urlCard
					_toolsCard
					
					if !_filteredRecommendedSourcesData.isEmpty {
						_featuredCard
					}
				}
				.padding(.horizontal, 18)
				.padding(.top, 18)
				.padding(.bottom, 35)
			}
			.background(Color(.systemBackground).ignoresSafeArea())
			.toolbar {
				NBToolbarButton(role: .cancel)
				
				if !_isImporting {
					NBToolbarButton(
						.localized("Save"),
						style: .text,
						placement: .confirmationAction,
						isDisabled: _sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
					) {
						FR.handleSource(_sourceURL) {
							dismiss()
						}
					}
				} else {
					ToolbarItem(placement: .confirmationAction) {
						ProgressView()
					}
				}
			}
			.animation(.default, value: _filteredRecommendedSourcesData.map { $0.data.id ?? "" })
			.task {
				await _fetchRecommendedRepositories()
			}
		}
	}
}

extension SourcesAddView {
	private var _headerCard: some View {
		VStack(spacing: 14) {
			ZStack {
				LinearGradient(
					colors: [.indigo, .blue],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
				
				Image(systemName: "plus.circle.fill")
					.font(.system(size: 42, weight: .semibold))
					.foregroundColor(.white)
			}
			.frame(width: 82, height: 82)
			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
			.shadow(color: .blue.opacity(0.35), radius: 18, x: 0, y: 10)
			
			VStack(spacing: 6) {
				Text(.localized("Add Source"))
					.font(.title2.bold())
				
				Text(.localized("Add AltStore repositories to browse and download apps."))
					.font(.subheadline)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
			}
		}
		.frame(maxWidth: .infinity)
		.padding(24)
		.background(cardBackground)
	}
	
	private var _urlCard: some View {
		VStack(alignment: .leading, spacing: 14) {
			Text(.localized("Source URL"))
				.font(.headline)
			
			HStack(spacing: 12) {
				Image(systemName: "link")
					.font(.headline)
					.foregroundColor(.accentColor)
				
				TextField(.localized("Enter Source URL"), text: $_sourceURL)
					.keyboardType(.URL)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
			}
			.padding(14)
			.background(Color(.tertiarySystemBackground))
			.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
			
			Text(.localized("Only AltStore repositories are supported."))
				.font(.footnote)
				.foregroundColor(.secondary)
			
			Button {
				if let url = URL(string: "https://faq.altstore.io/developers/make-a-source") {
					UIApplication.shared.open(url)
				}
			} label: {
				Label(.localized("Learn how to setup a repository"), systemImage: "book.fill")
					.font(.footnote.weight(.semibold))
			}
		}
		.padding(18)
		.background(cardBackground)
	}
	
	private var _toolsCard: some View {
		VStack(spacing: 12) {
			Button {
				_isImporting = true
				_fetchImportedRepositories(UIPasteboard.general.string) {
					dismiss()
				}
			} label: {
				actionRow(
					title: .localized("Import from Clipboard"),
					subtitle: .localized("Supports KravaSign, MapleSign, and ESign."),
					icon: "square.and.arrow.down.fill",
					color: .green
				)
			}
			.buttonStyle(.plain)
			
			Divider()
			
			Button {
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
			} label: {
				actionRow(
					title: .localized("Export Sources"),
					subtitle: .localized("Copy all repository URLs to clipboard."),
					icon: "doc.on.doc.fill",
					color: .orange
				)
			}
			.buttonStyle(.plain)
		}
		.padding(18)
		.background(cardBackground)
	}
	
	private var _featuredCard: some View {
		VStack(alignment: .leading, spacing: 14) {
			HStack {
				Text(.localized("Featured"))
					.font(.title2.bold())
				
				Spacer()
				
				Text("\(_filteredRecommendedSourcesData.count)")
					.font(.footnote.bold())
					.foregroundColor(.secondary)
					.padding(.horizontal, 10)
					.padding(.vertical, 6)
					.background(Color(.tertiarySystemBackground))
					.clipShape(Capsule())
			}
			
			VStack(spacing: 12) {
				ForEach(_filteredRecommendedSourcesData, id: \.url) { url, source in
					recommendedSourceRow(url: url, source: source)
				}
			}
			
			Text(.localized("Open Telegram if you want your source to be featured."))
				.font(.footnote)
				.foregroundColor(.secondary)
		}
		.padding(18)
		.background(cardBackground)
	}
	
	private var cardBackground: some View {
		RoundedRectangle(cornerRadius: 26, style: .continuous)
			.fill(Color(.secondarySystemBackground))
			.shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 7)
	}
	
	private func actionRow(title: String, subtitle: String, icon: String, color: Color) -> some View {
		HStack(spacing: 14) {
			Image(systemName: icon)
				.font(.system(size: 20, weight: .semibold))
				.foregroundColor(.white)
				.frame(width: 44, height: 44)
				.background(color)
				.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
			
			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.headline)
					.foregroundColor(.primary)
				
				Text(subtitle)
					.font(.footnote)
					.foregroundColor(.secondary)
			}
			
			Spacer()
			
			Image(systemName: "chevron.right")
				.font(.footnote.weight(.bold))
				.foregroundColor(.secondary)
		}
	}
	
	private func recommendedSourceRow(url: URL, source: ASRepository) -> some View {
		HStack(spacing: 14) {
			Group {
				if let iconURL = source.currentIconURL {
					LazyImage(url: iconURL) { state in
						if let image = state.image {
							image
								.resizable()
								.scaledToFill()
						} else {
							recommendedPlaceholderIcon
						}
					}
				} else {
					recommendedPlaceholderIcon
				}
			}
			.frame(width: 56, height: 56)
			.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
			
			VStack(alignment: .leading, spacing: 5) {
				Text(source.name ?? .localized("Unknown"))
					.font(.headline.weight(.semibold))
					.lineLimit(1)
				
				Text(url.absoluteString)
					.font(.footnote)
					.foregroundColor(.secondary)
					.lineLimit(1)
			}
			
			Spacer()
			
			Button {
				Storage.shared.addSource(url, repository: source) { _ in
					_refreshFilteredRecommendedSourcesData()
				}
			} label: {
				Text(.localized("Add"))
					.font(.subheadline.weight(.bold))
					.foregroundColor(.white)
					.padding(.horizontal, 16)
					.padding(.vertical, 10)
					.background(
						LinearGradient(
							colors: [.indigo, .blue],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.clipShape(Capsule())
			}
			.buttonStyle(.plain)
		}
		.padding(12)
		.background(Color(.tertiarySystemBackground))
		.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
	}
	
	private var recommendedPlaceholderIcon: some View {
		ZStack {
			LinearGradient(
				colors: [.indigo, .blue],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			
			Image(systemName: "globe.desk.fill")
				.font(.system(size: 25, weight: .semibold))
				.foregroundColor(.white)
		}
	}
}

extension SourcesAddView {
	private func _refreshFilteredRecommendedSourcesData() {
		let filtered = recommendedSourcesData
			.filter { url, data in
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
	
	private func _fetchRecommendedRepositories() async {
		let fetched = await _concurrentFetchRepositories(from: recommendedSources)
		
		await MainActor.run {
			recommendedSourcesData = fetched
			_refreshFilteredRecommendedSourcesData()
		}
	}
	
	private func _fetchImportedRepositories(
		_ code: String?,
		competion: @escaping () -> Void
	) {
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
					_isImporting = false
					competion()
				}
			}
		}
	}
	
	private func _concurrentFetchRepositories(
		from urls: [URL]
	) async -> [(url: URL, data: ASRepository)] {
		var results: [(url: URL, data: ASRepository)] = []
		let dataService = _dataService
		
		await withTaskGroup(of: Void.self) { group in
			for url in urls {
				group.addTask {
					await withCheckedContinuation { continuation in
						dataService.fetch<ASRepository>(from: url) { (result: RepositoryDataHandler) in
							switch result {
							case .success(let repo):
								Task { @MainActor in
									results.append((url: url, data: repo))
								}
							case .failure(let error):
								Logger.misc.error("Failed to fetch \(url): \(error.localizedDescription)")
							}
							
							continuation.resume()
						}
					}
				}
			}
			
			await group.waitForAll()
		}
		
		return results
	}
}
