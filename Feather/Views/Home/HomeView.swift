//
//  HomeView.swift
//  IPAOMTK
//

import SwiftUI
import NimbleViews
import Foundation
import UIKit

// MARK: - App Model

struct HomeApp: Identifiable {
    var id: String { "\(name)-\(webURL)" }

    let name: String
    let description: String
    let image: String?
    let url: String
    let webURL: String
    let isIPA: Bool
    let category: String

    var imageURL: URL? {
        if let image, image.hasPrefix("http") {
            return URL(string: image)
        }

        return URL(string: "https://ipaomtk.com/wp-content/uploads/2026/04/cropped-ipaomtk-icon.png")
    }
}

// MARK: - Feed API Models

struct FeedPost: Codable {
    let id: Int
    let link: String
    let title: RenderedText
    let excerpt: RenderedText
    let content: RenderedText?
    let embedded: EmbeddedData?

    enum CodingKeys: String, CodingKey {
        case id
        case link
        case title
        case excerpt
        case content
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

// MARK: - Helpers

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

// MARK: - Home View

struct HomeView: View {
    @StateObject var downloadManager = DownloadManager.shared

    @State private var apps: [HomeApp] = []
    @State private var searchResults: [HomeApp] = []

    @State private var isLoading = true
    @State private var isSearching = false
    @State private var isLoadingMore = false

    @State private var errorMessage: String?
    @State private var searchText = ""

    @State private var searchPage = 1
    @State private var searchTotalPages = 1
    @State private var searchTask: Task<Void, Never>?

    var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayedApps: [HomeApp] {
        isSearchActive ? searchResults : apps
    }

    var body: some View {
        NBNavigationView("Home") {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    searchBar

                    if isLoading && apps.isEmpty {
                        ProgressView("Loading apps...")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    } else if let errorMessage, apps.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    } else if isSearchActive && isSearching && searchResults.isEmpty {
                        ProgressView("Searching...")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 50)
                    } else if displayedApps.isEmpty {
                        Text(isSearchActive ? "No apps found." : "No apps available.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                    } else {
                        if !isSearchActive {
                            featuredSection
                        }

                        appsSection

                        if isSearchActive && searchPage < searchTotalPages {
                            loadMoreButton
                        }

                        if !isSearchActive {
                            SocialMediaFooter()
                                .padding(.bottom, 30)
                        }
                    }
                }
                .padding(.top, 10)
            }
            .refreshable {
                await loadLatestApps(showLoading: false)
            }
        }
        .onAppear {
            if apps.isEmpty {
                Task {
                    await loadLatestApps(showLoading: true)
                }
            }
        }
        .onChange(of: searchText) { newValue in
            searchTask?.cancel()

            searchTask = Task {
                try? await Task.sleep(nanoseconds: 500_000_000)

                if Task.isCancelled {
                    return
                }

                await startSearch(keyword: newValue)
            }
        }
    }

    var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search all apps...", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

            if !searchText.isEmpty {
                Button {
                    searchTask?.cancel()
                    searchText = ""
                    searchResults = []
                    isSearching = false
                    searchPage = 1
                    searchTotalPages = 1
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 20)
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
            Text(isSearchActive ? "Search Results" : "Apps")
                .font(.title2.bold())
                .padding(.horizontal, 20)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 18) {
                ForEach(displayedApps) { app in
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

    var loadMoreButton: some View {
        Button {
            Task {
                await loadMoreSearchResults()
            }
        } label: {
            HStack {
                if isLoadingMore {
                    ProgressView()
                }

                Text(isLoadingMore ? "Loading..." : "Load More Results")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.12))
            .foregroundColor(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
        .disabled(isLoadingMore)
    }

    private func loadLatestApps(showLoading: Bool) async {
        DispatchQueue.main.async {
            if showLoading {
                self.isLoading = true
            }

            self.errorMessage = nil
        }

        guard let url = makeFeedURL(search: nil, page: 1) else {
            DispatchQueue.main.async {
                self.errorMessage = "Bad feed URL."
                self.isLoading = false
            }
            return
        }

        do {
            let result = try await fetchApps(from: url)

            DispatchQueue.main.async {
                self.apps = result.apps
                self.isLoading = false
                self.errorMessage = nil
            }
        } catch {
            if (error as NSError).code == NSURLErrorCancelled {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }

            DispatchQueue.main.async {
                if self.apps.isEmpty {
                    self.errorMessage = "Could not load apps. Pull down to refresh."
                }

                self.isLoading = false
            }
        }
    }

    private func startSearch(keyword: String) async {
        let cleanKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanKeyword.isEmpty {
            DispatchQueue.main.async {
                self.searchResults = []
                self.isSearching = false
                self.searchPage = 1
                self.searchTotalPages = 1
            }
            return
        }

        if cleanKeyword.count < 2 {
            return
        }

        DispatchQueue.main.async {
            self.isSearching = true
            self.searchPage = 1
            self.searchTotalPages = 1
            self.searchResults = []
        }

        guard let url = makeFeedURL(search: cleanKeyword, page: 1) else {
            DispatchQueue.main.async {
                self.isSearching = false
            }
            return
        }

        do {
            let result = try await fetchApps(from: url)

            DispatchQueue.main.async {
                self.searchResults = result.apps
                self.searchPage = 1
                self.searchTotalPages = result.totalPages
                self.isSearching = false
            }
        } catch {
            if (error as NSError).code == NSURLErrorCancelled {
                DispatchQueue.main.async {
                    self.isSearching = false
                }
                return
            }

            DispatchQueue.main.async {
                self.searchResults = []
                self.isSearching = false
            }
        }
    }

    private func loadMoreSearchResults() async {
        let cleanKeyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanKeyword.isEmpty else {
            return
        }

        guard searchPage < searchTotalPages else {
            return
        }

        let nextPage = searchPage + 1

        guard let url = makeFeedURL(search: cleanKeyword, page: nextPage) else {
            return
        }

        DispatchQueue.main.async {
            self.isLoadingMore = true
        }

        do {
            let result = try await fetchApps(from: url)

            DispatchQueue.main.async {
                self.searchResults.append(contentsOf: result.apps)
                self.searchPage = nextPage
                self.searchTotalPages = result.totalPages
                self.isLoadingMore = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoadingMore = false
            }
        }
    }

    private func makeFeedURL(search: String?, page: Int) -> URL? {
        var components = URLComponents(string: "https://ipaomtk.com/wp-json/wp/v2/posts")

        var items: [URLQueryItem] = [
            URLQueryItem(name: "per_page", value: "100"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "_embed", value: "1")
        ]

        if let search, !search.isEmpty {
            items.append(URLQueryItem(name: "search", value: search))
        }

        components?.queryItems = items
        return components?.url
    }

    private func fetchApps(from url: URL) async throws -> (apps: [HomeApp], totalPages: Int) {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        let httpResponse = response as? HTTPURLResponse
        let totalPagesValue = httpResponse?.value(forHTTPHeaderField: "X-WP-TotalPages") ?? "1"
        let totalPages = Int(totalPagesValue) ?? 1

        let posts = try JSONDecoder().decode([FeedPost].self, from: data)

        let convertedApps = posts.map { post in
            convertPostToApp(post)
        }

        return (convertedApps, totalPages)
    }

    private func convertPostToApp(_ post: FeedPost) -> HomeApp {
        let title = post.title.rendered.cleanHTML
        let excerpt = post.excerpt.rendered.cleanHTML
        let contentHTML = post.content?.rendered ?? ""

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
            webURL: post.link,
            isIPA: ipaURL != nil,
            category: "Apps"
        )
    }
}

// MARK: - Featured Card

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
                Text(app.isIPA ? "IPA" : "APP")
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
                    .frame(width: 120)
                    .padding(.top, 4)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .padding(.horizontal, 20)
    }
}

// MARK: - Grid Card

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

            Text(app.isIPA ? "Download available" : "View app page")
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

// MARK: - Detail View

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
                                .frame(width: 140)
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

                    AppInfoRow(title: "Source", value: "IPAOMTK")
                    AppInfoRow(title: "Type", value: app.isIPA ? "IPA Download" : "App Page")
                    AppInfoRow(title: "Website", value: "ipaomtk.com")

                    Button {
                        if let link = URL(string: app.webURL) {
                            UIApplication.shared.open(link)
                        }
                    } label: {
                        Text("Open Web Page")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.12))
                            .foregroundColor(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Button

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
                    } else if let url = URL(string: app.webURL) {
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

// MARK: - Downloader

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

// MARK: - Info Row

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

// MARK: - Footer

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
