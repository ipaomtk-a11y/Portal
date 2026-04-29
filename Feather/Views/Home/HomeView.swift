//
//  HomeView.swift
//  IPAOMTK
//

import SwiftUI
import NimbleViews
import Foundation
import UIKit

struct HomeApp: Identifiable {
    var id: String { url }

    let name: String
    let description: String
    let image: String?
    let url: String
    let isIPA: Bool
    let category: String

    var imageURL: URL? {
        if let image, image.hasPrefix("http") {
            return URL(string: image)
        }
        return URL(string: "https://ipaomtk.com/wp-content/uploads/2026/04/cropped-ipaomtk-icon.png")
    }
}

struct WordPressPost: Codable {
    let id: Int
    let link: String
    let title: RenderedText
    let excerpt: RenderedText
    let content: RenderedText
    let embedded: EmbeddedData?

    enum CodingKeys: String, CodingKey {
        case id, link, title, excerpt, content
        case embedded = "_embedded"
    }
}

struct RenderedText: Codable {
    let rendered: String
}

struct EmbeddedData: Codable {
    let featuredMedia: [FeaturedMedia]?

    enum CodingKeys: String, CodingKey {
        case featuredMedia = "wp:featuredmedia"
    }
}

struct FeaturedMedia: Codable {
    let sourceURL: String?

    enum CodingKeys: String, CodingKey {
        case sourceURL = "source_url"
    }
}

extension String {
    var cleanHTML: String {
        var text = self

        text = text.replacingOccurrences(of: "<br>", with: "\n")
        text = text.replacingOccurrences(of: "<br/>", with: "\n")
        text = text.replacingOccurrences(of: "<br />", with: "\n")
        text = text.replacingOccurrences(of: "</p>", with: "\n")
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        text = text.replacingOccurrences(of: "&#038;", with: "&")
        text = text.replacingOccurrences(of: "&#8217;", with: "'")
        text = text.replacingOccurrences(of: "&#8216;", with: "'")
        text = text.replacingOccurrences(of: "&#8220;", with: "\"")
        text = text.replacingOccurrences(of: "&#8221;", with: "\"")
        text = text.replacingOccurrences(of: "&#8211;", with: "-")
        text = text.replacingOccurrences(of: "&#8212;", with: "-")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&hellip;", with: "...")
        text = text.replacingOccurrences(of: "[&hellip;]", with: "")
        text = text.replacingOccurrences(of: "[...]", with: "")

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func firstURLContaining(_ keyword: String) -> String? {
        let pattern = #"https?:\/\/[^\s"'<>]+"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(self.startIndex..., in: self)
        let matches = regex.matches(in: self, range: range)

        for match in matches {
            if let swiftRange = Range(match.range, in: self) {
                var foundURL = String(self[swiftRange])
                foundURL = foundURL.replacingOccurrences(of: "\\/", with: "/")
                foundURL = foundURL.replacingOccurrences(of: "&#038;", with: "&")
                foundURL = foundURL.replacingOccurrences(of: "&amp;", with: "&")

                if foundURL.lowercased().contains(keyword.lowercased()) {
                    return foundURL
                }
            }
        }

        return nil
    }
}

struct HomeView: View {
    @StateObject var downloadManager = DownloadManager.shared
    @State private var apps: [HomeApp] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NBNavigationView("Home") {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if isLoading {
                        ProgressView("Loading IPAOMTK...")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else if apps.isEmpty {
                        Text("No posts found.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        featuredSection
                        appsSection
                        SocialMediaFooter()
                            .padding(.bottom, 30)
                    }
                }
                .padding(.top, 10)
            }
            .refreshable {
                await loadApps()
            }
        }
        .onAppear {
            Task {
                await loadApps()
            }
        }
    }

    var featuredSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Featured")
                .font(.title2.bold())
                .padding(.horizontal, 20)

            TabView {
                ForEach(apps.prefix(5)) { app in
                    NavigationLink {
                        HomeAppDetailView(app: app, downloadManager: downloadManager)
                    } label: {
                        FeaturedCard(app: app, downloadManager: downloadManager)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 250)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        }
    }

    var appsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Apps")
                .font(.title2.bold())
                .padding(.horizontal, 20)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 18) {
                ForEach(apps) { app in
                    NavigationLink {
                        HomeAppDetailView(app: app, downloadManager: downloadManager)
                    } label: {
                        AppGridCard(app: app, downloadManager: downloadManager)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func loadApps() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        guard let url = URL(string: "https://ipaomtk.com/wp-json/wp/v2/posts?_embed&per_page=50") else {
            DispatchQueue.main.async {
                self.errorMessage = "Bad WordPress URL."
                self.isLoading = false
            }
            return
        }

        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData

            let (data, _) = try await URLSession.shared.data(for: request)
            let posts = try JSONDecoder().decode([WordPressPost].self, from: data)

            let convertedApps: [HomeApp] = posts.map { post in
                let title = post.title.rendered.cleanHTML
                let excerpt = post.excerpt.rendered.cleanHTML
                let contentHTML = post.content.rendered

                let ipaURL = contentHTML.firstURLContaining(".ipa")
                let finalURL = ipaURL ?? post.link

                let featuredImage = post.embedded?.featuredMedia?.first?.sourceURL

                let imageURL =
                    featuredImage ??
                    contentHTML.firstURLContaining(".png") ??
                    contentHTML.firstURLContaining(".jpg") ??
                    contentHTML.firstURLContaining(".jpeg") ??
                    contentHTML.firstURLContaining(".webp")

                return HomeApp(
                    name: title.isEmpty ? "IPAOMTK App" : title,
                    description: excerpt.isEmpty ? "Download from IPAOMTK." : excerpt,
                    image: imageURL,
                    url: finalURL,
                    isIPA: ipaURL != nil,
                    category: "Apps"
                )
            }

            DispatchQueue.main.async {
                self.apps = convertedApps
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Could not load WordPress posts: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

struct FeaturedCard: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: app.imageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.25)
            }
            .frame(height: 220)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(app.isIPA ? "IPA" : "POST")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(app.isIPA ? Color.blue : Color.orange)
                    .foregroundColor(.white)
                    .clipShape(Capsule())

                Text(app.name)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(app.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)

                DownloadOrOpenButton(app: app, downloadManager: downloadManager)
                    .frame(width: 110)
                    .padding(.top, 4)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .padding(.horizontal, 20)
    }
}

struct AppGridCard: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager

    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: app.imageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 86, height: 86)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Text(app.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(app.isIPA ? "Download available" : "Open post")
                .font(.caption)
                .foregroundColor(.secondary)

            DownloadOrOpenButton(app: app, downloadManager: downloadManager)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 230)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}

struct HomeAppDetailView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                AsyncImage(url: app.imageURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.25)
                }
                .frame(height: 280)
                .frame(maxWidth: .infinity)
                .clipped()

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 16) {
                        AsyncImage(url: app.imageURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 90, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        VStack(alignment: .leading, spacing: 8) {
                            Text(app.name)
                                .font(.title.bold())

                            Text(app.category)
                                .foregroundColor(.secondary)

                            DownloadOrOpenButton(app: app, downloadManager: downloadManager)
                                .frame(width: 130)
                        }
                    }

                    Divider()

                    Text("Description")
                        .font(.title2.bold())

                    Text(app.description)
                        .font(.body)
                        .foregroundColor(.secondary)

                    Divider()

                    Text("Information")
                        .font(.title2.bold())

                    AppInfoRow(title: "Source", value: "IPAOMTK WordPress")
                    AppInfoRow(title: "Type", value: app.isIPA ? "IPA Download" : "WordPress Post")
                    AppInfoRow(title: "Website", value: "ipaomtk.com")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DownloadOrOpenButton: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    @StateObject private var downloader = HomeAppDownloader()

    var body: some View {
        Group {
            if downloader.isFinished {
                Label("Done", systemImage: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .clipShape(Capsule())
            } else if downloader.isDownloading {
                HStack {
                    ProgressView()
                    Text("Loading")
                }
                .font(.system(size: 14, weight: .bold))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.12))
                .foregroundColor(.blue)
                .clipShape(Capsule())
            } else {
                Button {
                    if app.isIPA, let url = URL(string: app.url) {
                        downloader.start(url: url) { localURL in
                            _ = downloadManager.startDownload(from: localURL)
                        }
                    } else if let url = URL(string: app.url) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text(app.isIPA ? "Get" : "Open")
                        .font(.system(size: 14, weight: .bold))
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

class HomeAppDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var isDownloading = false
    @Published var isFinished = false

    private var downloadTask: URLSessionDownloadTask?
    private var session: URLSession?
    private var downloadURL: URL?
    private var onFinished: ((URL) -> Void)?

    func start(url: URL, onFinished: @escaping (URL) -> Void) {
        self.downloadURL = url
        self.onFinished = onFinished
        self.isDownloading = true
        self.isFinished = false

        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        self.downloadTask = session?.downloadTask(with: url)
        self.downloadTask?.resume()
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(UUID().uuidString)-\(downloadURL?.lastPathComponent ?? "download.ipa")"
        let destinationURL = tempDir.appendingPathComponent(fileName)

        try? FileManager.default.removeItem(at: destinationURL)

        do {
            try FileManager.default.copyItem(at: location, to: destinationURL)

            DispatchQueue.main.async {
                self.isDownloading = false
                self.isFinished = true
                self.onFinished?(destinationURL)
            }
        } catch {
            DispatchQueue.main.async {
                self.isDownloading = false
            }
        }

        session.finishTasksAndInvalidate()
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if error != nil {
            DispatchQueue.main.async {
                self.isDownloading = false
            }
        }

        session.finishTasksAndInvalidate()
    }
}

struct AppInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .foregroundColor(.secondary)
            }
            Divider()
        }
    }
}

struct SocialMediaFooter: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Follow Us")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 25) {
                SocialButton(icon: "paperplane.fill", color: .blue, url: "https://t.me/ipaomtk")
                SocialButton(icon: "camera.fill", color: Color(UIColor.systemPurple), url: "https://www.instagram.com/ipaomtk")
                SocialButton(icon: "play.tv.fill", color: .black, url: "https://www.tiktok.com/@ipaomtk")
            }
        }
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, 20)
    }
}

struct SocialButton: View {
    let icon: String
    let color: Color
    let url: String

    var body: some View {
        Button {
            if let link = URL(string: url) {
                UIApplication.shared.open(link)
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 54, height: 54)
                .background(color)
                .clipShape(Circle())
        }
    }
}
