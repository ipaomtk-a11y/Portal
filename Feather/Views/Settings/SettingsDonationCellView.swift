//
//  SettingsDonationCellView.swift
//  ipaomtk
//
//  Professional redesign for IPAOMTK
//

#if !NIGHTLY && !DEBUG
import SwiftUI
import NimbleViews

struct SettingsDonationCellView: View {
	var site: String
	
	var body: some View {
		VStack(spacing: 18) {
			header
			
			VStack(spacing: 14) {
				benefit(
					.localized("Remove Alerts"),
					.localized("Get beta access and remove donation reminder alerts."),
					systemName: "bell.slash.fill",
					color: .pink
				)
				
				benefit(
					.localized("Exclusive Features"),
					.localized("Unlock early beta features before public releases."),
					systemName: "sparkles",
					color: .purple
				)
				
				benefit(
					.localized("Support IPAOMTK"),
					.localized("Help support future updates and development."),
					systemName: "heart.fill",
					color: .red
				)
			}
			
			Button {
				UIApplication.open(site)
			} label: {
				HStack(spacing: 10) {
					Image(systemName: "heart.fill")
					Text(.localized("Donate"))
				}
				.font(.headline)
				.foregroundColor(.white)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 15)
				.background(
					LinearGradient(
						colors: [.pink, .red],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
				.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
				.shadow(color: .pink.opacity(0.3), radius: 14, x: 0, y: 8)
			}
			.buttonStyle(.plain)
		}
		.padding(22)
		.background(
			RoundedRectangle(cornerRadius: 28, style: .continuous)
				.fill(Color(.secondarySystemBackground))
				.shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
		)
	}
	
	private var header: some View {
		VStack(spacing: 12) {
			ZStack {
				LinearGradient(
					colors: [.pink, .red],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
				
				Image(systemName: "heart.fill")
					.font(.system(size: 34, weight: .bold))
					.foregroundColor(.white)
			}
			.frame(width: 78, height: 78)
			.clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
			
			VStack(spacing: 5) {
				Text(.localized("Donations"))
					.font(.title2.bold())
					.foregroundColor(.primary)
				
				Text(.localized("Support IPAOMTK development."))
					.font(.subheadline)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
			}
		}
	}
	
	private func benefit(
		_ title: String,
		_ desc: String,
		systemName: String,
		color: Color
	) -> some View {
		HStack(spacing: 14) {
			Image(systemName: systemName)
				.font(.system(size: 18, weight: .semibold))
				.foregroundColor(color)
				.frame(width: 42, height: 42)
				.background(color.opacity(0.14))
				.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
			
			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.headline)
					.foregroundColor(.primary)
				
				Text(desc)
					.font(.footnote)
					.foregroundColor(.secondary)
					.fixedSize(horizontal: false, vertical: true)
			}
			
			Spacer()
		}
	}
}

#endif
