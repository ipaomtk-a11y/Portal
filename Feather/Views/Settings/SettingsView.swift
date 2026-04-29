//
//  SettingsView.swift
//  IPAOMTK
//
//  Professional redesign for IPAOMTK
//

import SwiftUI
import NimbleViews
import UIKit
import Darwin
import IDeviceSwift

struct SettingsView: View {
	@AppStorage("feather.selectedCert") private var _storedSelectedCert: Int = 0
	@State private var _currentIcon: String? = UIApplication.shared.alternateIconName
	
	@FetchRequest(
		entity: CertificatePair.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
		animation: .snappy
	) private var _certificates: FetchedResults<CertificatePair>
	
	private var selectedCertificate: CertificatePair? {
		guard _storedSelectedCert >= 0, _storedSelectedCert < _certificates.count else {
			return nil
		}
		return _certificates[_storedSelectedCert]
	}
	
	var body: some View {
		NBNavigationView(.localized("Settings")) {
			ScrollView {
				VStack(spacing: 24) {
					headerCard
					accountCard
					preferencesCard
					certificatesCard
					featuresCard
					storageCard
					resetCard
				}
				.padding(.horizontal, 18)
				.padding(.top, 16)
				.padding(.bottom, 40)
			}
			.background(Color(.systemBackground).ignoresSafeArea())
		}
	}
}

// MARK: - Cards
extension SettingsView {
	private var headerCard: some View {
		VStack(spacing: 18) {
			AsyncImage(url: URL(string: "https://ipaomtk.com/wp-content/uploads/2026/04/cropped-ipaomtk-icon.png")) { image in
				image.resizable().scaledToFill()
			} placeholder: {
				ProgressView()
			}
			.frame(width: 105, height: 105)
			.clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
			.shadow(color: .blue.opacity(0.25), radius: 18, x: 0, y: 10)
			
			VStack(spacing: 6) {
				Text("IPAOMTK")
					.font(.title.bold())
					.foregroundColor(.primary)
				
				Text("Professional IPA signing, certificates, and app management.")
					.font(.subheadline)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
			}
			
			Button {
				openURL("https://t.me/IPAOMTK")
			} label: {
				Label("Join Telegram", systemImage: "paperplane.fill")
					.font(.headline)
					.foregroundColor(.white)
					.frame(maxWidth: .infinity)
					.padding(.vertical, 16)
					.background(
						LinearGradient(
							colors: [.blue, .cyan],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
					.shadow(color: .blue.opacity(0.25), radius: 14, x: 0, y: 8)
			}
		}
		.padding(24)
		.background(cardBackground)
	}
	
	private var accountCard: some View {
		settingsCard {
			SettingsRow(title: "About \(Bundle.main.name)", icon: "info.circle.fill", tint: .blue) {
				AboutView()
			}
			
			SettingsButtonRow(title: "Telegram", icon: "paperplane.fill", tint: .blue) {
				openURL("https://t.me/IPAOMTK")
			}
			
			SettingsButtonRow(title: "Website", icon: "safari.fill", tint: .green) {
				openURL("https://www.ipaomtk.com/")
			}
		}
	}
	
	private var preferencesCard: some View {
		groupCard(title: "Preferences", footer: nil) {
			SettingsRow(title: .localized("Appearance"), icon: "paintbrush.fill", tint: .purple) {
				AppearanceView()
			}
			
			SettingsRow(title: .localized("App Icon"), icon: "app.badge.fill", tint: .indigo) {
				AppIconView(currentIcon: $_currentIcon)
			}
		}
	}
	
	private var certificatesCard: some View {
		groupCard(
			title: "Certificates",
			footer: "Add and manage certificates used for signing applications."
		) {
			if let cert = selectedCertificate {
				CertificatesCellView(cert: cert)
					.padding(.horizontal, 16)
					.padding(.vertical, 10)
			} else {
				HStack(spacing: 14) {
					Image(systemName: "xmark.seal.fill")
						.font(.system(size: 18, weight: .semibold))
						.foregroundColor(.orange)
						.frame(width: 38, height: 38)
						.background(Color.orange.opacity(0.14))
						.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
					
					Text(.localized("No Certificate"))
						.font(.body.weight(.medium))
						.foregroundColor(.secondary)
					
					Spacer()
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 13)
			}
			
			SettingsRow(title: .localized("Certificates"), icon: "checkmark.seal.fill", tint: .green) {
				CertificatesView()
			}
		}
	}
	
	private var featuresCard: some View {
		groupCard(
			title: "Features",
			footer: "Configure signing, compression, installation, and app modifications."
		) {
			SettingsRow(title: .localized("Signing Options"), icon: "signature", tint: .blue) {
				ConfigurationView()
			}
			
			SettingsRow(title: .localized("Archive & Compression"), icon: "archivebox.fill", tint: .orange) {
				ArchiveView()
			}
			
			SettingsRow(title: .localized("Installation"), icon: "arrow.down.circle.fill", tint: .green) {
				InstallationView()
			}
		}
	}
	
	private var storageCard: some View {
		groupCard(
			title: "Storage",
			footer: "Quick access to IPAOMTK files stored in Documents."
		) {
			SettingsButtonRow(title: .localized("Open Documents"), icon: "folder.fill", tint: .blue) {
				UIApplication.open(URL.documentsDirectory.toSharedDocumentsURL()!)
			}
			
			SettingsButtonRow(title: .localized("Open Archives"), icon: "archivebox.fill", tint: .orange) {
				UIApplication.open(FileManager.default.archives.toSharedDocumentsURL()!)
			}
			
			SettingsButtonRow(title: .localized("Open Certificates"), icon: "folder.badge.gearshape.fill", tint: .green) {
				UIApplication.open(FileManager.default.certificates.toSharedDocumentsURL()!)
			}
		}
	}
	
	private var resetCard: some View {
		groupCard(title: "Danger Zone", footer: "Reset application sources, certificates, apps, and general contents.") {
			SettingsRow(title: .localized("Reset"), icon: "trash.fill", tint: .red) {
				ResetView()
			}
		}
	}
}

// MARK: - Helpers
extension SettingsView {
	private var cardBackground: some View {
		RoundedRectangle(cornerRadius: 30, style: .continuous)
			.fill(Color(.secondarySystemBackground))
			.shadow(color: .black.opacity(0.16), radius: 18, x: 0, y: 10)
	}
	
	private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
		VStack(spacing: 0) {
			content()
		}
		.padding(.vertical, 8)
		.background(cardBackground)
	}
	
	private func groupCard<Content: View>(
		title: String,
		footer: String?,
		@ViewBuilder content: () -> Content
	) -> some View {
		VStack(alignment: .leading, spacing: 12) {
			Text(title)
				.font(.title3.bold())
				.foregroundColor(.primary)
				.padding(.horizontal, 4)
			
			VStack(spacing: 0) {
				content()
			}
			.padding(.vertical, 8)
			.background(cardBackground)
			
			if let footer {
				Text(footer)
					.font(.footnote)
					.foregroundColor(.secondary)
					.padding(.horizontal, 4)
			}
		}
	}
	
	private func openURL(_ string: String) {
		if let url = URL(string: string) {
			UIApplication.shared.open(url)
		}
	}
}

// MARK: - Reusable Rows
private struct SettingsRow<Destination: View>: View {
	let title: String
	let icon: String
	var tint: Color = .indigo
	let destination: () -> Destination
	
	var body: some View {
		NavigationLink(destination: destination()) {
			rowContent
		}
		.buttonStyle(.plain)
	}
	
	private var rowContent: some View {
		HStack(spacing: 14) {
			Image(systemName: icon)
				.font(.system(size: 18, weight: .semibold))
				.foregroundColor(tint)
				.frame(width: 38, height: 38)
				.background(tint.opacity(0.14))
				.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
			
			Text(title)
				.font(.body.weight(.semibold))
				.foregroundColor(.primary)
			
			Spacer()
			
			Image(systemName: "chevron.right")
				.font(.footnote.weight(.bold))
				.foregroundColor(.secondary.opacity(0.75))
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 14)
	}
}

private struct SettingsButtonRow: View {
	let title: String
	let icon: String
	var tint: Color = .indigo
	let action: () -> Void
	
	var body: some View {
		Button(action: action) {
			HStack(spacing: 14) {
				Image(systemName: icon)
					.font(.system(size: 18, weight: .semibold))
					.foregroundColor(tint)
					.frame(width: 38, height: 38)
					.background(tint.opacity(0.14))
					.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
				
				Text(title)
					.font(.body.weight(.semibold))
					.foregroundColor(.primary)
				
				Spacer()
				
				Image(systemName: "arrow.up.right")
					.font(.footnote.weight(.bold))
					.foregroundColor(.secondary.opacity(0.75))
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 14)
		}
		.buttonStyle(.plain)
	}
}
