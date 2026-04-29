//
//  CertificatesAddView.swift
//  Feather
//
//  Professional redesign for IPAOMTK
//

import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

struct CertificatesAddView: View {
	@Environment(\.dismiss) private var dismiss
	
	@State private var _p12URL: URL? = nil
	@State private var _provisionURL: URL? = nil
	@State private var _p12Password: String = ""
	@State private var _certificateName: String = ""
	
	@State private var _isImportingP12Presenting = false
	@State private var _isImportingMobileProvisionPresenting = false
	
	private var saveButtonDisabled: Bool {
		_p12URL == nil || _provisionURL == nil
	}
	
	var body: some View {
		NBNavigationView(.localized("New Certificate"), displayMode: .inline) {
			ScrollView {
				VStack(spacing: 22) {
					headerCard
					filesCard
					detailsCard
					saveCard
				}
				.padding(.horizontal, 18)
				.padding(.top, 18)
				.padding(.bottom, 35)
			}
			.background(Color(.systemBackground).ignoresSafeArea())
			.toolbar {
				NBToolbarButton(role: .cancel)
				
				NBToolbarButton(
					.localized("Save"),
					style: .text,
					placement: .confirmationAction,
					isDisabled: saveButtonDisabled
				) {
					_saveCertificate()
				}
			}
			.sheet(isPresented: $_isImportingP12Presenting) {
				FileImporterRepresentableView(
					allowedContentTypes: [.p12],
					onDocumentsPicked: { urls in
						guard let selectedFileURL = urls.first else { return }
						_p12URL = selectedFileURL
					}
				)
				.ignoresSafeArea()
			}
			.sheet(isPresented: $_isImportingMobileProvisionPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes: [.mobileProvision],
					onDocumentsPicked: { urls in
						guard let selectedFileURL = urls.first else { return }
						_provisionURL = selectedFileURL
					}
				)
				.ignoresSafeArea()
			}
		}
	}
}

// MARK: - UI
extension CertificatesAddView {
	private var headerCard: some View {
		VStack(spacing: 14) {
			ZStack {
				LinearGradient(
					colors: [.green, .teal],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
				
				Image(systemName: "checkmark.seal.fill")
					.font(.system(size: 42, weight: .bold))
					.foregroundColor(.white)
			}
			.frame(width: 84, height: 84)
			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
			.shadow(color: .green.opacity(0.3), radius: 18, x: 0, y: 10)
			
			VStack(spacing: 6) {
				Text(.localized("New Certificate"))
					.font(.title2.bold())
					.foregroundColor(.primary)
				
				Text(.localized("Import your .p12 certificate and mobile provisioning profile."))
					.font(.subheadline)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
			}
		}
		.frame(maxWidth: .infinity)
		.padding(24)
		.background(cardBackground)
	}
	
	private var filesCard: some View {
		VStack(alignment: .leading, spacing: 14) {
			Text(.localized("Required Files"))
				.font(.headline)
				.foregroundColor(.primary)
			
			importFileRow(
				title: .localized("Certificate File"),
				subtitle: _p12URL?.lastPathComponent ?? ".p12 file required",
				icon: "key.fill",
				color: .green,
				file: _p12URL
			) {
				_isImportingP12Presenting = true
			}
			
			importFileRow(
				title: .localized("Provisioning File"),
				subtitle: _provisionURL?.lastPathComponent ?? ".mobileprovision file required",
				icon: "doc.badge.gearshape.fill",
				color: .blue,
				file: _provisionURL
			) {
				_isImportingMobileProvisionPresenting = true
			}
		}
		.padding(18)
		.background(cardBackground)
	}
	
	private var detailsCard: some View {
		VStack(alignment: .leading, spacing: 14) {
			Text(.localized("Certificate Details"))
				.font(.headline)
				.foregroundColor(.primary)
			
			VStack(spacing: 12) {
				HStack(spacing: 12) {
					Image(systemName: "lock.fill")
						.foregroundColor(.orange)
						.frame(width: 28)
					
					SecureField(.localized("Password Optional"), text: $_p12Password)
						.textInputAutocapitalization(.never)
				}
				.padding(14)
				.background(Color(.tertiarySystemBackground))
				.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
				
				HStack(spacing: 12) {
					Image(systemName: "tag.fill")
						.foregroundColor(.purple)
						.frame(width: 28)
					
					TextField(.localized("Nickname Optional"), text: $_certificateName)
						.textInputAutocapitalization(.words)
				}
				.padding(14)
				.background(Color(.tertiarySystemBackground))
				.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
			}
			
			Text(.localized("Leave the password empty if your private key does not require one."))
				.font(.footnote)
				.foregroundColor(.secondary)
		}
		.padding(18)
		.background(cardBackground)
	}
	
	private var saveCard: some View {
		Button {
			_saveCertificate()
		} label: {
			HStack(spacing: 10) {
				Image(systemName: "checkmark.circle.fill")
				Text(.localized("Save Certificate"))
			}
			.font(.headline)
			.foregroundColor(.white)
			.frame(maxWidth: .infinity)
			.padding(.vertical, 16)
			.background(
				LinearGradient(
					colors: saveButtonDisabled ? [.gray.opacity(0.6), .gray.opacity(0.4)] : [.green, .teal],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
			)
			.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
			.shadow(color: saveButtonDisabled ? .clear : .green.opacity(0.25), radius: 14, x: 0, y: 8)
		}
		.disabled(saveButtonDisabled)
		.buttonStyle(.plain)
	}
	
	private var cardBackground: some View {
		RoundedRectangle(cornerRadius: 28, style: .continuous)
			.fill(Color(.secondarySystemBackground))
			.shadow(color: .black.opacity(0.14), radius: 16, x: 0, y: 9)
	}
	
	private func importFileRow(
		title: String,
		subtitle: String,
		icon: String,
		color: Color,
		file: URL?,
		action: @escaping () -> Void
	) -> some View {
		Button(action: action) {
			HStack(spacing: 14) {
				Image(systemName: file == nil ? icon : "checkmark.circle.fill")
					.font(.system(size: 20, weight: .semibold))
					.foregroundColor(color)
					.frame(width: 44, height: 44)
					.background(color.opacity(0.14))
					.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
				
				VStack(alignment: .leading, spacing: 4) {
					Text(title)
						.font(.headline)
						.foregroundColor(.primary)
					
					Text(subtitle)
						.font(.footnote)
						.foregroundColor(.secondary)
						.lineLimit(1)
				}
				
				Spacer()
				
				Text(file == nil ? .localized("Import") : .localized("Added"))
					.font(.subheadline.weight(.bold))
					.foregroundColor(file == nil ? color : .secondary)
					.padding(.horizontal, 13)
					.padding(.vertical, 8)
					.background((file == nil ? color : Color.secondary).opacity(0.14))
					.clipShape(Capsule())
			}
			.padding(12)
			.background(Color(.tertiarySystemBackground))
			.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
		}
		.disabled(file != nil)
		.buttonStyle(.plain)
		.animation(.easeInOut(duration: 0.25), value: file != nil)
	}
}

// MARK: - Save
extension CertificatesAddView {
	private func _saveCertificate() {
		guard
			let p12URL = _p12URL,
			let provisionURL = _provisionURL,
			FR.checkPasswordForCertificate(for: p12URL, with: _p12Password, using: provisionURL)
		else {
			UIAlertController.showAlertWithOk(
				title: .localized("Bad Password"),
				message: .localized("Please check the password and try again.")
			)
			return
		}
		
		FR.handleCertificateFiles(
			p12URL: p12URL,
			provisionURL: provisionURL,
			p12Password: _p12Password,
			certificateName: _certificateName
		) { _ in
			dismiss()
		}
	}
}
