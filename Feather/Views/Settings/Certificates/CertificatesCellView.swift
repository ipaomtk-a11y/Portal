//
//  CertificateCellView.swift
//  IPAOMTK
//
//  Professional redesign for IPAOMTK
//

import SwiftUI
import NimbleViews

struct CertificatesCellView: View {
	@State var data: Certificate?
	@ObservedObject var cert: CertificatePair
	
	var body: some View {
		HStack(spacing: 14) {
			statusIcon
			
			VStack(alignment: .leading, spacing: 6) {
				Text(certificateTitle)
					.font(.headline.weight(.semibold))
					.foregroundColor(.primary)
					.lineLimit(1)
				
				Text(data?.AppIDName ?? .localized("Unknown"))
					.font(.subheadline)
					.foregroundColor(.secondary)
					.lineLimit(1)
				
				certInfoPills
			}
			
			Spacer(minLength: 8)
		}
		.padding(14)
		.background(
			RoundedRectangle(cornerRadius: 24, style: .continuous)
				.fill(Color(.secondarySystemBackground))
		)
		.contentTransition(.opacity)
		.onAppear {
			withAnimation {
				data = Storage.shared.getProvisionFileDecoded(for: cert)
			}
		}
	}
	
	private var certificateTitle: String {
		var title = cert.nickname ?? data?.Name ?? .localized("Unknown")
		
		if let getTaskAllow = data?.Entitlements?["get-task-allow"]?.value as? Bool, getTaskAllow == true {
			title = "🐞 \(title)"
		}
		
		return title
	}
	
	private var statusColor: Color {
		if cert.revoked == true { return .red }
		if cert.ppQCheck == true { return .orange }
		return .green
	}
	
	private var statusIcon: some View {
		Image(systemName: cert.revoked == true ? "xmark.seal.fill" : "checkmark.seal.fill")
			.font(.system(size: 24, weight: .bold))
			.foregroundColor(statusColor)
			.frame(width: 54, height: 54)
			.background(statusColor.opacity(0.14))
			.clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
	}
	
	private var certInfoPills: some View {
		let pillItems = buildPills(from: cert)
		
		return HStack(spacing: 6) {
			if pillItems.isEmpty {
				Text(.localized("Active"))
					.font(.caption.weight(.bold))
					.foregroundColor(.green)
					.padding(.horizontal, 10)
					.padding(.vertical, 5)
					.background(Color.green.opacity(0.14))
					.clipShape(Capsule())
			} else {
				ForEach(pillItems.indices, id: \.self) { index in
					let pill = pillItems[index]
					NBPillView(
						title: pill.title,
						icon: pill.icon,
						color: pill.color,
						index: index,
						count: pillItems.count
					)
				}
			}
		}
	}
	
	private func buildPills(from cert: CertificatePair) -> [NBPillItem] {
		var pills: [NBPillItem] = []
		
		if cert.ppQCheck == true {
			pills.append(NBPillItem(title: .localized("PPQCheck"), icon: "checkmark.shield", color: .red))
		}
		
		if cert.revoked == true {
			pills.append(NBPillItem(title: .localized("Revoked"), icon: "xmark.octagon", color: .red))
		}
		
		if let info = cert.expiration?.expirationInfo() {
			pills.append(NBPillItem(
				title: info.formatted,
				icon: info.icon,
				color: info.color
			))
		}
		
		return pills
	}
}
