//
//  SourcesCellView.swift
//  IPAOMTK
//

import SwiftUI
import NimbleViews
import NukeUI

struct SourcesCellView: View {
    var source: AltSource
    
    var body: some View {
        HStack(spacing: 14) {
            
            // ICON
            ZStack {
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                if let url = source.iconURL {
                    LazyImage(url: url) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "globe")
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    Image(systemName: "globe")
                        .foregroundColor(.white)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .blue.opacity(0.25), radius: 8, x: 0, y: 4)
            
            
            // TEXT
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name ?? "Unknown")
                    .font(.headline)
                
                Text("Private Repository")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Label("Protected", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.05))
        )
        .swipeActions {
            _actions(for: source)
        }
        .contextMenu {
            _actions(for: source)
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
}
