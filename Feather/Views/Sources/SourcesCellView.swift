//
//  SourcesCellView.swift
//  Feather
//

import SwiftUI
import NimbleViews
import NukeUI

// MARK: - View
struct SourcesCellView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var source: AltSource
    
    // MARK: Body
    var body: some View {
        let isRegular = horizontalSizeClass != .compact
        
        HStack(spacing: 14) {
            _iconView
            
            VStack(alignment: .leading, spacing: 5) {
                Text(source.name ?? .localized("Unknown"))
                    .font(.system(size: isRegular ? 18 : 17, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.caption2.weight(.bold))
                    
                    Text(.localized("Private Repository"))
                        .font(.subheadline.weight(.medium))
                }
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
            
            Spacer(minLength: 8)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary.opacity(0.45))
        }
        .padding(.horizontal, isRegular ? 18 : 14)
        .padding(.vertical, isRegular ? 16 : 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.045), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.045), radius: 10, x: 0, y: 5)
        .swipeActions {
            _actions(for: source)
        }
        .contextMenu {
            _actions(for: source)
        }
    }
    
    private var _iconView: some View {
        Group {
            if let iconURL = source.iconURL {
                LazyImage(url: iconURL) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        _placeholderIcon
                    }
                }
            } else {
                _placeholderIcon
            }
        }
        .frame(width: 58, height: 58)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
    
    private var _placeholderIcon: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.9), .purple.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "globe.desk.fill")
                .font(.system(size: 25, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Extension: View
extension SourcesCellView {
    @ViewBuilder
    private func _actions(for source: AltSource) -> some View {
        Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
            Storage.shared.deleteSource(for: source)
        }
    }
}
