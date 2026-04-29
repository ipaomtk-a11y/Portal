//
//  ContentView.swift
//  IPAOMTK
//
//  Professional Library redesign for IPAOMTK
//

import SwiftUI
import CoreData
import NimbleViews

// MARK: - View
struct LibraryView: View {
	@StateObject var downloadManager = DownloadManager.shared
	
	@State private var _selectedInfoAppPresenting: AnyApp?
	@State private var _selectedSigningAppPresenting: AnyApp?
	@State private var _selectedInstallAppPresenting: AnyApp?
	@State private var _isImportingPresenting = false
	@State private var _isDownloadingPresenting = false
	@State private var _alertDownloadString: String = ""
	
	// MARK: Selection State
	@State private var _selectedAppUUIDs: Set<String> = []
	@State private var _editMode: EditMode = .inactive
	
	@State private var _searchText = ""
	@State private var _selectedScope: Scope = .all
	
	@Namespace private var _namespace
	
	// MARK: Fetch
	@FetchRequest(
		entity: Signed.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)],
		animation: .snappy
	) private var _signedApps: FetchedResults<Signed>
	
	@FetchRequest(
		entity: Imported.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)],
		animation: .snappy
	) private var _importedApps: FetchedResults<Imported>
	
	// MARK: Filter
	private func filteredAndSortedApps<T>(from apps: FetchedResults<T>) -> [T] where T: NSManagedObject {
		apps.filter {
			_searchText.isEmpty ||
			(($0.value(forKey: "name") as? String)?.localizedCaseInsensitiveContains(_searchText) ?? false)
		}
	}
	
	private var _filteredSignedApps: [Signed] {
		filteredAndSortedApps(from: _signedApps)
	}
	
	private var _filteredImportedApps: [Imported] {
		filteredAndSortedApps(from: _importedApps)
	}
	
	private var _totalApps: Int {
		_filteredSignedApps.count + _filteredImportedApps.count
	}
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("Library")) {
			ZStack(alignment: .bottomTrailing) {
				ScrollView {
					VStack(spacing: 22) {
						_headerView
						_scopePicker
						
						if _totalApps == 0 {
							_emptyState
						} else {
							_appSections
						}
					}
					.padding(.horizontal, 18)
					.padding(.top, 12)
					.padding(.bottom, 120)
				}
				.background(Color(.systemBackground).ignoresSafeArea())
				.searchable(text: $_searchText, placement: .platform())
				.scrollDismissesKeyboard(.interactively)
				
				if !_editMode.isEditing {
					_importFloatingButton
						.padding(.trailing, 18)
						.padding(.bottom, 28)
				}
			}
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					EditButton()
				}
				
				if _editMode.isEditing {
					NBToolbarButton(
						.localized("Delete"),
						systemImage: "trash",
						isDisabled: _selectedAppUUIDs.isEmpty
					) {
						_bulkDeleteSelectedApps()
					}
				}
			}
			.environment(\.editMode, $_editMode)
			.sheet(item: $_selectedInfoAppPresenting) { app in
				LibraryInfoView(app: app.base)
			}
			.sheet(item: $_selectedInstallAppPresenting) { app in
				InstallPreviewView(app: app.base, isSharing: app.archive)
					.presentationDetents([.height(200)])
					.presentationDragIndicator(.visible)
			}
			.fullScreenCover(item: $_selectedSigningAppPresenting) { app in
				SigningView(app: app.base)
					.compatNavigationTransition(id: app.base.uuid ?? "", ns: _namespace)
			}
			.sheet(isPresented: $_isImportingPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes: [.ipa, .tipa],
					allowsMultipleSelection: true,
					onDocumentsPicked: { urls in
						guard !urls.isEmpty else { return }
						
						for url in urls {
							let id = "FeatherManualDownload_\(UUID().uuidString)"
							let dl = downloadManager.startArchive(from: url, id: id)
							try? downloadManager.handlePachageFile(url: url, dl: dl)
						}
					}
				)
				.ignoresSafeArea()
			}
			.alert(.localized("Import from URL"), isPresented: $_isDownloadingPresenting) {
				TextField(.localized("URL"), text: $_alertDownloadString)
					.textInputAutocapitalization(.never)
				
				Button(.localized("Cancel"), role: .cancel) {
					_alertDownloadString = ""
				}
				
				Button(.localized("OK")) {
					if let url = URL(string: _alertDownloadString) {
						_ = downloadManager.startDownload(
							from: url,
							id: "FeatherManualDownload_\(UUID().uuidString)"
						)
					}
				}
			}
			.onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.installApp"))) { _ in
				if let latest = _signedApps.first {
					_selectedInstallAppPresenting = AnyApp(base: latest)
				}
			}
			.onChange(of: _editMode) { mode in
				if mode == .inactive {
					_selectedAppUUIDs.removeAll()
				}
			}
		}
	}
}

// MARK: - UI Components
extension LibraryView {
	private var _headerView: some View {
		HStack(alignment: .center) {
			VStack(alignment: .leading, spacing: 6) {
				Text("Library")
					.font(.largeTitle.bold())
					.foregroundColor(.primary)
				
				Text("\(_totalApps) apps in your collection")
					.font(.subheadline)
					.foregroundColor(.secondary)
			}
			
			Spacer()
			
			Menu {
				_importActions()
			} label: {
				Image(systemName: "plus")
					.font(.system(size: 20, weight: .bold))
					.foregroundColor(.white)
					.frame(width: 46, height: 46)
					.background(
						LinearGradient(
							colors: [.pink, .red],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.clipShape(Circle())
					.shadow(color: .pink.opacity(0.35), radius: 14, x: 0, y: 8)
			}
		}
	}
	
	private var _scopePicker: some View {
		HStack(spacing: 10) {
			ForEach(Scope.allCases, id: \.displayName) { scope in
				Button {
					withAnimation(.snappy) {
						_selectedScope = scope
					}
				} label: {
					Text(scope.displayName)
						.font(.subheadline.weight(.semibold))
						.foregroundColor(_selectedScope == scope ? .white : .secondary)
						.padding(.horizontal, 16)
						.padding(.vertical, 10)
						.background(
							_selectedScope == scope
							? Color.accentColor
							: Color(.secondarySystemBackground)
						)
						.clipShape(Capsule())
				}
				.buttonStyle(.plain)
			}
			
			Spacer()
		}
	}
	
	private var _appSections: some View {
		VStack(spacing: 24) {
			if !_filteredSignedApps.isEmpty, _selectedScope == .all || _selectedScope == .signed {
				_librarySection(title: .localized("Signed"), count: _filteredSignedApps.count) {
					ForEach(_filteredSignedApps, id: \.uuid) { app in
						LibraryCellView(
							app: app,
							selectedInfoAppPresenting: $_selectedInfoAppPresenting,
							selectedSigningAppPresenting: $_selectedSigningAppPresenting,
							selectedInstallAppPresenting: $_selectedInstallAppPresenting,
							selectedAppUUIDs: $_selectedAppUUIDs
						)
						.compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
					}
				}
			}
			
			if !_filteredImportedApps.isEmpty, _selectedScope == .all || _selectedScope == .imported {
				_librarySection(title: .localized("Imported"), count: _filteredImportedApps.count) {
					ForEach(_filteredImportedApps, id: \.uuid) { app in
						LibraryCellView(
							app: app,
							selectedInfoAppPresenting: $_selectedInfoAppPresenting,
							selectedSigningAppPresenting: $_selectedSigningAppPresenting,
							selectedInstallAppPresenting: $_selectedInstallAppPresenting,
							selectedAppUUIDs: $_selectedAppUUIDs
						)
						.compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
					}
				}
			}
		}
	}
	
	private func _librarySection<Content: View>(
		title: String,
		count: Int,
		@ViewBuilder content: () -> Content
	) -> some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack {
				Text(title)
					.font(.title2.bold())
					.foregroundColor(.primary)
				
				Spacer()
				
				Text("\(count)")
					.font(.footnote.bold())
					.foregroundColor(.secondary)
					.padding(.horizontal, 10)
					.padding(.vertical, 6)
					.background(Color(.secondarySystemBackground))
					.clipShape(Capsule())
			}
			
			VStack(spacing: 12) {
				content()
			}
		}
	}
	
	private var _emptyState: some View {
		VStack(spacing: 18) {
			Image(systemName: "square.grid.2x2.fill")
				.font(.system(size: 48, weight: .semibold))
				.foregroundColor(.accentColor)
			
			Text(.localized("No Apps"))
				.font(.title2.bold())
				.foregroundColor(.primary)
			
			Text(.localized("Get started by importing your first IPA file."))
				.font(.subheadline)
				.foregroundColor(.secondary)
				.multilineTextAlignment(.center)
			
			Menu {
				_importActions()
			} label: {
				Label("Import IPA", systemImage: "plus.circle.fill")
					.font(.headline)
					.foregroundColor(.white)
					.padding(.horizontal, 24)
					.padding(.vertical, 14)
					.background(
						LinearGradient(
							colors: [.pink, .red],
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
	
	private var _importFloatingButton: some View {
		Menu {
			_importActions()
		} label: {
			HStack(spacing: 10) {
				Image(systemName: "plus.circle.fill")
				Text("Import IPA")
			}
			.font(.headline)
			.foregroundColor(.white)
			.padding(.horizontal, 20)
			.padding(.vertical, 15)
			.background(
				LinearGradient(
					colors: [.pink, .red],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
			)
			.clipShape(Capsule())
			.shadow(color: .pink.opacity(0.35), radius: 18, x: 0, y: 10)
		}
	}
}

// MARK: - Import Actions
extension LibraryView {
	@ViewBuilder
	private func _importActions() -> some View {
		Button(.localized("Import from Files"), systemImage: "folder.fill") {
			_isImportingPresenting = true
		}
		
		Button(.localized("Import from URL"), systemImage: "link.circle.fill") {
			_isDownloadingPresenting = true
		}
	}
}

// MARK: - Bulk Delete
extension LibraryView {
	private func _bulkDeleteSelectedApps() {
		let selectedApps = _getAllApps().filter { app in
			guard let uuid = app.uuid else { return false }
			return _selectedAppUUIDs.contains(uuid)
		}
		
		for app in selectedApps {
			Storage.shared.deleteApp(for: app)
		}
		
		_selectedAppUUIDs.removeAll()
	}
	
	private func _getAllApps() -> [AppInfoPresentable] {
		var allApps: [AppInfoPresentable] = []
		
		if _selectedScope == .all || _selectedScope == .signed {
			allApps.append(contentsOf: _filteredSignedApps)
		}
		
		if _selectedScope == .all || _selectedScope == .imported {
			allApps.append(contentsOf: _filteredImportedApps)
		}
		
		return allApps
	}
}

// MARK: - Scope
extension LibraryView {
	enum Scope: CaseIterable {
		case all
		case signed
		case imported
		
		var displayName: String {
			switch self {
			case .all: return .localized("All")
			case .signed: return .localized("Signed")
			case .imported: return .localized("Imported")
			}
		}
	}
}
