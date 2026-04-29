//
//  LibraryAppIconView.swift
//  IPAOMTK
//
//  Professional Library cell redesign for IPAOMTK
//

import SwiftUI
import NimbleExtensions
import NimbleViews

// MARK: - View
struct LibraryCellView: View {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@Environment(\.editMode) private var editMode
	
	var certInfo: Date.ExpirationInfo? {
		Storage.shared.getCertificate(from: app)?.expiration?.expirationInfo()
	}
	
	var certRevoked: Bool {
		Storage.shared.getCertificate(from: app)?.revoked == true
	}
	
	var app: AppInfoPresentable
	@Binding var selectedInfoAppPresenting: AnyApp?
	@Binding var selectedSigningAppPresenting: AnyApp?
	@Binding var selectedInstallAppPresenting: AnyApp?
	@Binding var selectedAppUUIDs: Set<String>
	
	// MARK: Selection
	private var _isSelected: Bool {
		guard let uuid = app.uuid else { return false }
		return selectedAppUUIDs.contains(uuid)
	}
	
	private func _toggleSelection() {
		guard let uuid = app.uuid else { return }
		
		if selectedAppUUIDs.contains(uuid) {
			selectedAppUUIDs.remove(uuid)
		} else {
			selectedAppUUIDs.insert(uuid)
		}
	}
	
	// MARK: Body
	var body: some View {
		let isEditing = editMode?.wrappedValue == .active
		
		HStack(spacing: 14) {
			if isEditing {
				Button {
					_toggleSelection()
				} label: {
					Image(systemName: _isSelected ? "checkmark.circle.fill" : "circle")
						.font(.system(size: 24, weight: .semibold))
						.foregroundColor(_isSelected ? .accentColor : .secondary)
				}
				.buttonStyle(.borderless)
			}
			
			FRAppIconView(app: app, size: 62)
				.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
				.shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 5)
			
			VStack(alignment: .leading, spacing: 5) {
				Text(app.name ?? .localized("Unknown"))
					.font(.headline.weight(.semibold))
					.foregroundColor(.primary)
					.lineLimit(1)
				
				Text(_desc)
					.font(.subheadline)
					.foregroundColor(.secondary)
					.lineLimit(1)
				
				if app.isSigned {
					HStack(spacing: 6) {
						Image(systemName: "checkmark.seal.fill")
							.font(.caption)
						Text(.localized("Signed"))
							.font(.caption.weight(.semibold))
					}
					.foregroundColor(.green)
				} else {
					HStack(spacing: 6) {
						Image(systemName: "tray.and.arrow.down.fill")
							.font(.caption)
						Text(.localized("Imported"))
							.font(.caption.weight(.semibold))
					}
					.foregroundColor(.orange)
				}
			}
			
			Spacer(minLength: 8)
			
			if !isEditing {
				_buttonActions(for: app)
			}
		}
		.padding(14)
		.background(
			RoundedRectangle(cornerRadius: 24, style: .continuous)
				.fill(_isSelected && isEditing ? Color.accentColor.opacity(0.14) : Color(.secondarySystemBackground))
				.shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 7)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 24, style: .continuous)
				.stroke(_isSelected && isEditing ? Color.accentColor.opacity(0.55) : Color.white.opacity(0.05), lineWidth: 1)
		)
		.contentShape(Rectangle())
		.onTapGesture {
			if isEditing {
				_toggleSelection()
			} else {
				selectedInfoAppPresenting = AnyApp(base: app)
			}
		}
		.swipeActions {
			if !isEditing {
				_actions(for: app)
			}
		}
		.contextMenu {
			if !isEditing {
				_contextActions(for: app)
				Divider()
				_contextActionsExtra(for: app)
				Divider()
				_actions(for: app)
			}
		}
	}
	
	private var _desc: String {
		if let version = app.version, let id = app.identifier {
			return "\(version) • \(id)"
		} else {
			return .localized("Unknown")
		}
	}
}

// MARK: - Actions
extension LibraryCellView {
	@ViewBuilder
	private func _actions(for app: AppInfoPresentable) -> some View {
		Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
			Storage.shared.deleteApp(for: app)
		}
	}
	
	@ViewBuilder
	private func _contextActions(for app: AppInfoPresentable) -> some View {
		Button(.localized("Get Info"), systemImage: "info.circle") {
			selectedInfoAppPresenting = AnyApp(base: app)
		}
	}
	
	@ViewBuilder
	private func _contextActionsExtra(for app: AppInfoPresentable) -> some View {
		if app.isSigned {
			if let id = app.identifier {
				Button(.localized("Open"), systemImage: "app.badge.checkmark") {
					UIApplication.openApp(with: id)
				}
			}
			
			Button(.localized("Install"), systemImage: "square.and.arrow.down") {
				selectedInstallAppPresenting = AnyApp(base: app)
			}
			
			Button(.localized("Re-sign"), systemImage: "signature") {
				selectedSigningAppPresenting = AnyApp(base: app)
			}
			
			Button(.localized("Export"), systemImage: "square.and.arrow.up") {
				selectedInstallAppPresenting = AnyApp(base: app, archive: true)
			}
		} else {
			Button(.localized("Install"), systemImage: "square.and.arrow.down") {
				selectedInstallAppPresenting = AnyApp(base: app)
			}
			
			Button(.localized("Sign"), systemImage: "signature") {
				selectedSigningAppPresenting = AnyApp(base: app)
			}
		}
	}
	
	@ViewBuilder
	private func _buttonActions(for app: AppInfoPresentable) -> some View {
		Group {
			if app.isSigned {
				Button {
					selectedInstallAppPresenting = AnyApp(base: app)
				} label: {
					FRExpirationPillView(
						title: .localized("Install"),
						revoked: certRevoked,
						expiration: certInfo
					)
				}
			} else {
				Button {
					selectedSigningAppPresenting = AnyApp(base: app)
				} label: {
					Text(.localized("Sign"))
						.font(.headline.weight(.semibold))
						.foregroundColor(.white)
						.padding(.horizontal, 18)
						.padding(.vertical, 10)
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
		}
		.buttonStyle(.borderless)
	}
}
