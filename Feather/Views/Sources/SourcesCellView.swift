//
//  SourcesCellView.swift
//  IPAOMTK
//
//  Professional redesign for IPAOMTK
//

import SwiftUI
import NimbleViews
import NukeUI

struct SourcesCellView: View {
	var source: AltSource
	
	var body: some View {
		HStack(spacing: 14) {
			sourceIcon
			
			VStack(alignment: .leading, spacing: 6) {
				Text(source.name ?? .localized("Unknown"))
					.font(.headline.weight(.semibold))
					.foregroundColor(.primary)
					.lineLimit(1)
				
				Text(source.sourceURL?.absoluteString ?? "")
					.font(.subheadline)
					.foregroundColor(.secondary)
					.lineLimit(1)
				
				HStack(spacing: 6) {
					Image(systemName: "globe")
						.font(.caption)
					
					Text(.localized("Repository"))
						.font(.caption.weight(.semibold))
				}
				.foregroundColor(.accentColor)
			}
			
			Spacer(minLength: 8)
			
			Image(systemName: "chevron.right")
				.font(.footnote.weight(.bold))
				.foregroundColor(.secondary.opacity(0.7))
		}
		.padding(14)
		.background(
			RoundedRectangle(cornerRadius: 24, style: .continuous)
				.fill(Color(.secondarySystemBackground))
				.shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 7)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 24, style: .continuous)
				.stroke(Color.white.opacity(0.05), lineWidth: 1)
		)
		.swipeActions {
			_actions(for: source)
			_contextActions(for: source)
		}
		.contextMenu {
			_contextActions(for: source)
			Divider()
			_actions(for: source)
		}
	}
	
	private var sourceIcon: some View {
		Group {
			if let iconURL = source.iconURL {
				LazyImage(url: iconURL) { state in
					if let image = state.image {
						image
							.resizable()
							.scaledToFill()
					} else {
						placeholderIcon
					}
				}
			} else {
				placeholderIcon
			}
		}
		.frame(width: 62, height: 62)
		.clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
		.shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 5)
	}
	
	private var placeholderIcon: some View {
		ZStack {
			LinearGradient(
				colors: [.accentColor.opacity(0.85), .purple.opacity(0.85)],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			
			Image(systemName: "globe.desk.fill")
				.font(.system(size: 28, weight: .semibold))
				.foregroundColor(.white)
		}
	}
}

extension SourcesCellView {
	@ViewBuilder
	private func _actions(for source: AltSource) -> some View {
		Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
			Storage.shared.deleteSource(for: source)
		}
	}
	
	@ViewBuilder
	private func _contextActions(for source: AltSource) -> some View {
		Button(.localized("Copy"), systemImage: "doc.on.clipboard") {
			UIPasteboard.general.string = source.sourceURL?.absoluteString
		}
	}
}
