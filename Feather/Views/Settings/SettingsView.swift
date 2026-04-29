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
				VStack(spacing: 22) {
					headerCard
					feedbackCard
					preferencesCard
					certificatesCard
					featuresCard
					directoriesCard
					resetCard
				}
				.padding(.horizontal, 18)
				.padding(.top, 14)
				.padding(.bottom, 35)
			}
			.background(Color.black.ignoresSafeArea())
		}
	}
}

// MARK: - Components
extension SettingsView {
	private var headerCard: some View {
		VStack(spacing: 18) {
			AsyncImage(url: URL(string: "https://ipaomtk.com/wp-content/uploads/2026/04/cropped-ipaomtk-icon.png")) { image in
				image.resizable().scaledToFit()
			} placeholder: {
				ProgressView()
			}
			.frame(width: 92, height: 92)
			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
			.shadow(color: .blue.opacity(0.25), radius: 20, x: 0, y: 10)
			
			VStack(spacing: 6) {
				Text("IPAOMTK")
					.font(.title2.bold())
					.foregroundColor(.primary)
				
				Text("Manage signing, certificates, and app preferences.")
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
					.padding(.vertical, 15)
					.background(
						LinearGradient(
							colors: [.blue, .cyan],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
			}
		}
		.padding(22)
		.background(cardBackground)
	}
	
	private var feedbackCard: some View {
		settingsCard {
			SettingsRow(title: "About \(Bundle.main.name)", icon: "info.circle.fill") {
				AboutView()
			}
			
			SettingsButtonRow(title: "Telegram", icon: "paperplane.fill") {
				openURL("https://t.me/IPAOMTK")
			}
			
			SettingsButtonRow(title: "Website", icon: "safari.fill") {
				openURL("https://www.ipaomtk.com/")
			}
		}
	}
	
	private var preferencesCard: some View {
		settingsCard {
			SettingsRow(title: .localized("Appearance"), icon: "paintbrush.fill") {
				AppearanceView()
			}
			
			SettingsRow(title: .localized("App Icon"), icon: "app.badge.fill") {
				AppIconView(currentIcon: $_currentIcon)
			}
		}
	}
	
	private var certificatesCard: some View {
		VStack(alignment: .leading, spacing: 12) {
			sectionTitle("Certificates")
			
			settingsCard {
				if let cert = selectedCertificate {
					CertificatesCellView(cert: cert)
				} else {
					Text(.localized("No Certificate"))
						.font(.subheadline)
						.foregroundColor(.secondary)
						.padding(.vertical, 8)
				}
				
				SettingsRow(title: .localized("Certificates"), icon: "checkmark.seal.fill") {
					CertificatesView()
				}
			}
			
			sectionFooter("Add and manage certificates used for signing applications.")
		}
	}
	
	private var featuresCard: some View {
		VStack(alignment: .leading, spacing: 12) {
			sectionTitle("Features")
			
			settingsCard {
				SettingsRow(title: .localized("Signing Options"), icon: "signature") {
					ConfigurationView()
				}
				
				SettingsRow(title: .localized("Archive & Compression"), icon: "archivebox.fill") {
					ArchiveView()
				}
				
				SettingsRow(title: .localized("Installation"), icon: "arrow.down.circle.fill") {
					InstallationView()
				}
			}
			
			sectionFooter("Configure installation, compression levels, and app modifications.")
		}
	}
	
	private var directoriesCard: some View {
		VStack(alignment: .leading, spacing: 12) {
			sectionTitle("Misc")
			
			settingsCard {
				SettingsButtonRow(title: .localized("Open Documents"), icon: "folder.fill") {
					UIApplication.open(URL.documentsDirectory.toSharedDocumentsURL()!)
				}
				
				SettingsButtonRow(title: .localized("Open Archives"), icon: "archivebox.fill") {
					UIApplication.open(FileManager.default.archives.toSharedDocumentsURL()!)
				}
				
				SettingsButtonRow(title: .localized("Open Certificates"), icon: "folder.badge.gearshape.fill") {
					UIApplication.open(FileManager.default.certificates.toSharedDocumentsURL()!)
				}
			}
			
			sectionFooter("Quick access to IPAOMTK files stored in Documents.")
		}
	}
	
	private var resetCard: some View {
		settingsCard {
			SettingsRow(title: .localized("Reset"), icon: "trash.fill", tint: .red) {
				ResetView()
			}
		}
	}
	
	private var cardBackground: some View {
		RoundedRectangle(cornerRadius: 26, style: .continuous)
			.fill(Color(.secondarySystemBackground))
			.shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
	}
	
	private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
		VStack(spacing: 0) {
			content()
		}
		.padding(.vertical, 6)
		.background(cardBackground)
	}
	
	private func sectionTitle(_ title: String) -> some View {
		Text(title)
			.font(.title3.bold())
			.foregroundColor(.primary)
			.padding(.horizontal, 4)
	}
	
	private func sectionFooter(_ text: String) -> some View {
		Text(text)
			.font(.footnote)
			.foregroundColor(.secondary)
			.padding(.horizontal, 4)
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
	}
	
	private var rowContent: some View {
		HStack(spacing: 14) {
			Image(systemName: icon)
				.font(.system(size: 18, weight: .semibold))
				.foregroundColor(tint)
				.frame(width: 32, height: 32)
				.background(tint.opacity(0.14))
				.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
			
			Text(title)
				.font(.body.weight(.medium))
				.foregroundColor(.primary)
			
			Spacer()
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 13)
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
					.frame(width: 32, height: 32)
					.background(tint.opacity(0.14))
					.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
				
				Text(title)
					.font(.body.weight(.medium))
					.foregroundColor(.primary)
				
				Spacer()
				
				Image(systemName: "arrow.up.right")
					.font(.footnote.weight(.semibold))
					.foregroundColor(.secondary)
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 13)
		}
		.buttonStyle(.plain)
	}
}
