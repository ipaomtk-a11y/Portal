struct HomeView: View {
    @StateObject var downloadManager = DownloadManager.shared

    @State private var apps: [HomeApp] = []
    @State private var searchResults: [HomeApp] = []
    @State private var isLoading = true
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchText = ""

    var showingSearch: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayedApps: [HomeApp] {
        showingSearch ? searchResults : apps
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
                    } else if isSearching {
                        ProgressView("Searching...")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if let errorMessage, apps.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    } else if displayedApps.isEmpty {
                        Text(showingSearch ? "No apps found." : "No apps available.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                    } else {
                        if !showingSearch {
                            featuredSection
                        }

                        appsSection

                        if !showingSearch {
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
            Task {
                await searchApps(keyword: newValue)
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
                    searchText = ""
                    searchResults = []
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
            Text(showingSearch ? "Search Results" : "Apps")
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

    private func loadLatestApps(showLoading: Bool) async {
        DispatchQueue.main.async {
            if showLoading {
                self.isLoading = true
            }
            self.errorMessage = nil
        }

        guard let url = URL(string: "https://ipaomtk.com/wp-json/wp/v2/posts?per_page=100&page=1&_embed") else {
            DispatchQueue.main.async {
                self.errorMessage = "Bad feed URL."
                self.isLoading = false
            }
            return
        }

        await fetchPosts(from: url) { converted in
            self.apps = converted
            self.isLoading = false
            self.errorMessage = nil
        }
    }

    private func searchApps(keyword: String) async {
        let cleanKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanKeyword.isEmpty {
            DispatchQueue.main.async {
                self.searchResults = []
                self.isSearching = false
            }
            return
        }

        if cleanKeyword.count < 2 {
            return
        }

        DispatchQueue.main.async {
            self.isSearching = true
        }

        let encodedKeyword = cleanKeyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanKeyword

        guard let url = URL(string: "https://ipaomtk.com/wp-json/wp/v2/posts?search=\(encodedKeyword)&per_page=100&page=1&_embed") else {
            DispatchQueue.main.async {
                self.isSearching = false
            }
            return
        }

        await fetchPosts(from: url) { converted in
            self.searchResults = converted
            self.isSearching = false
        }
    }

    private func fetchPosts(from url: URL, completion: @escaping ([HomeApp]) -> Void) async {
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 25

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
                    webURL: post.link,
                    isIPA: ipaURL != nil,
                    category: "Apps"
                )
            }

            DispatchQueue.main.async {
                completion(convertedApps)
            }
        } catch {
            if (error as NSError).code == NSURLErrorCancelled {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isSearching = false
                }
                return
            }

            DispatchQueue.main.async {
                self.isLoading = false
                self.isSearching = false

                if self.apps.isEmpty {
                    self.errorMessage = "Could not load apps. Pull down to refresh."
                }
            }
        }
    }
}
