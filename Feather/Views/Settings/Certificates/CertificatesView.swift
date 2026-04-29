//
//  CertificatesView.swift
//  Feather
//
//  Professional redesign for IPAOMTK
//

import SwiftUI
import NimbleViews

struct CertificatesView: View {
	@AppStorage("feather.selectedCert") private var _storedSelectedCert: Int = 0
	
	@State private var _isAddingPresenting = false
	@State private var _isSelectedInfoPresenting: CertificatePair?
	
	@FetchRequest(
		entity: CertificatePair.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
		animation: .snappy
	) private var _certificates: FetchedResults<CertificatePair>
	
	private var _bindingSelectedCert: Binding<Int>?
	private var _selectedCertBinding: Binding<Int> {
		_bindingSelectedCert ?? $_storedSelectedCert
	}
	
	init(selectedCert: Binding<Int>? = nil) {
		self._bindingSelectedCert = selectedCert
	}
	
	var body: some View {
		ZStack(alignment: .bottomTrailing) {
			ScrollView {
				VStack(spacing: 22) {
					headerCard
					
					if _certificates.isEmpty {
						emptyState
					} else {
						certificatesSection
					}
				}
				.padding(.horizontal, 18)
				.padding(.top, 16)
				.padding(.bottom, 115)
			}
			.background(Color(.systemBackground).ignoresSafeArea())
			
			if _bindingSelectedCert == nil {
				addFloatingButton
					.padding(.trailing, 18)
					.padding(.bottom, 28)
			}
		}
		.navigationTitle(.localized("Certificates"))
		.toolbar {
			if _bindingSelectedCert == nil {
				NBToolbarButton(
					systemImage: "plus",
					style: .icon,
					placement: .topBarTrailing
				) {
					_isAddingPresenting = true
				}
			}
		}
		.sheet(item: $_isSelectedInfoPresenting) { cert in
			CertificatesInfoView(cert: cert)
		}
		.sheet(isPresented: $_isAddingPresenting) {
			CertificatesAddView()
				.presentationDetents([.large])
		}
	}
}

// MARK: - UI
extension CertificatesView {
	private var headerCard: some View {
		HStack(spacing: 15) {
			ZStack {
				LinearGradient(
					colors: [.green, .teal],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
				
				Image(systemName: "checkmark.seal.fill")
					.font(.system(size: 30, weight: .bold))
					.foregroundColor(.white)
			}
			.frame(width: 66, height: 66)
			.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
			
			VStack(alignment: .leading, spacing: 5) {
				Text(.localized("Certificates"))
					.font(.title2.bold())
					.foregroundColor(.primary)
				
				Text("\(_certificates.count) signing certificates available")
					.font(.subheadline)
					.foregroundColor(.secondary)
			}
			
			Spacer()
		}
		.padding(18)
		.background(cardBackground)
	}
	
	private var certificatesSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack {
				Text(.localized("Signing Certificates"))
					.font(.title2.bold())
					.foregroundColor(.primary)
				
				Spacer()
				
				Text("\(_certificates.count)")
					.font(.footnote.bold())
					.foregroundColor(.secondary)
					.padding(.horizontal, 10)
					.padding(.vertical, 6)
					.background(Color(.secondarySystemBackground))
					.clipShape(Capsule())
			}
			
			VStack(spacing: 12) {
				ForEach(Array(_certificates.enumerated()), id: \.element.uuid) { index, cert in
					cellButton(for: cert, at: index)
				}
			}
		}
	}
	
	private var emptyState: some View {
		VStack(spacing: 18) {
			Image(systemName: "questionmark.folder.fill")
				.font(.system(size: 48, weight: .semibold))
				.foregroundColor(.accentColor)
			
			Text(.localized("No Certificates"))
				.font(.title2.bold())
				.foregroundColor(.primary)
			
			Text(.localized("Get started signing by importing your first certificate."))
				.font(.subheadline)
				.foregroundColor(.secondary)
				.multilineTextAlignment(.center)
			
			Button {
				_isAddingPresenting = true
			} label: {
				Label(.localized("Import Certificate"), systemImage: "plus.circle.fill")
					.font(.headline)
					.foregroundColor(.white)
					.padding(.horizontal, 24)
					.padding(.vertical, 14)
					.background(
						LinearGradient(
							colors: [.green, .teal],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.clipShape(Capsule())
			}
		}
		.frame(maxWidth: .infinity)
		.padding(30)
		.background(cardBackground)
		.padding(.top, 70)
	}
	
	private var addFloatingButton: some View {
		Button {
			_isAddingPresenting = true
		} label: {
			HStack(spacing: 10) {
				Image(systemName: "plus.circle.fill")
				Text(.localized("Import"))
			}
			.font(.headline)
			.foregroundColor(.white)
			.padding(.horizontal, 20)
			.padding(.vertical, 15)
			.background(
				LinearGradient(
					colors: [.green, .teal],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
			)
			.clipShape(Capsule())
			.shadow(color: .green.opacity(0.3), radius: 18, x: 0, y: 10)
		}
	}
	
	private var cardBackground: some View {
		RoundedRectangle(cornerRadius: 28, style: .continuous)
			.fill(Color(.secondarySystemBackground))
			.shadow(color: .black.opacity(0.14), radius: 16, x: 0, y: 9)
	}
	
	private func cellButton(for cert: CertificatePair, at index: Int) -> some View {
		Button {
			_selectedCertBinding.wrappedValue = index
		} label: {
			CertificatesCellView(cert: cert)
				.overlay(
					RoundedRectangle(cornerRadius: 24, style: .continuous)
						.strokeBorder(
							_selectedCertBinding.wrappedValue == index ? Color.accentColor : Color.clear,
							lineWidth: 2
						)
				)
				.contextMenu {
					contextActions(for: cert)
					
					if cert.isDefault != true {
						Divider()
						actions(for: cert)
					}
				}
				.transaction {
					$0.animation = nil
				}
		}
		.buttonStyle(.plain)
	}
}

// MARK: - Actions
extension CertificatesView {
	@ViewBuilder
	private func actions(for cert: CertificatePair) -> some View {
		Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
			Storage.shared.deleteCertificate(for: cert)
		}
	}
	
	@ViewBuilder
	private func contextActions(for cert: CertificatePair) -> some View {
		Button(.localized("Get Info"), systemImage: "info.circle") {
			_isSelectedInfoPresenting = cert
		}
		
		Divider()
		
		Button(.localized("Check Revokage"), systemImage: "person.text.rectangle") {
			Storage.shared.revokagedCertificate(for: cert)
		}
	}
}
