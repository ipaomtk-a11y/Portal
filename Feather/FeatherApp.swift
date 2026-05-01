//
//  FeatherApp.swift
//  IPAOMTK
//
//  Created by IPAOMTK on 10.04.2025.
//

import SwiftUI
import Nuke
import IDeviceSwift
import OSLog

@main
struct FeatherApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	
	let heartbeat = HeartbeatManager.shared
	
	@StateObject var downloadManager = DownloadManager.shared
	let storage = Storage.shared
	
	var body: some Scene {
		WindowGroup {
			VStack {
				DownloadHeaderView(downloadManager: downloadManager)
					.transition(.move(edge: .top).combined(with: .opacity))
				VariedTabbarView()
					.environment(\.managedObjectContext, storage.context)
					.onOpenURL(perform: _handleURL)
					.transition(.move(edge: .top).combined(with: .opacity))
			}
			.animation(.smooth, value: downloadManager.manualDownloads.description)
			.onReceive(NotificationCenter.default.publisher(for: .heartbeatInvalidHost)) { _ in
				DispatchQueue.main.async {
					UIAlertController.showAlertWithOk(
						title: "InvalidHostID",
						message: .localized("Your pairing file is invalid and is incompatible with your device, please import a valid pairing file.")
					)
				}
			}
			.onAppear {
				if let style = UIUserInterfaceStyle(rawValue: UserDefaults.standard.integer(forKey: "Feather.userInterfaceStyle")) {
					UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style
				}
				
				UIApplication.topViewController()?.view.window?.tintColor = UIColor(Color(hex: UserDefaults.standard.string(forKey: "Feather.userTintColor") ?? "#848ef9"))
				
				_downloadAndInstallVIPCert()
			}
		}
	}
	
	// MARK: - Auto VIP Certificate Downloader
	private func _downloadAndInstallVIPCert() {
		guard UserDefaults.standard.bool(forKey: "AshteVIPCertInstalled") == false else { return }

		let p12URLString = "https://file.ipaomtk.com/certs/cert.p12"
		let provURLString = "https://file.ipaomtk.com/certs/cert.mobileprovision"

		guard let p12URL = URL(string: p12URLString),
			  let provURL = URL(string: provURLString) else { return }

		Task {
			do {
				let (p12Data, _) = try await URLSession.shared.data(from: p12URL)
				let (provData, _) = try await URLSession.shared.data(from: provURL)

				let tempP12 = FileManager.default.temporaryDirectory.appendingPathComponent("vip_cert.p12")
				let tempProv = FileManager.default.temporaryDirectory.appendingPathComponent("vip_cert.mobileprovision")

				try p12Data.write(to: tempP12)
				try provData.write(to: tempProv)

				DispatchQueue.main.async {
					FR.handleCertificateFiles(
						p12URL: tempP12,
						provisionURL: tempProv,
						p12Password: "1IPAOMTK", //
						certificateName: "IPAOMTK Free",
						isDefault: true
					) { error in
						if error == nil {
							UserDefaults.standard.set(true, forKey: "IPAOMTKVIPCertInstalled")
							Logger.misc.info("VIP successful")
						}
					}
				}
			} catch {
				Logger.misc.error("filed: \(error.localizedDescription)")
			}
		}
	}

	private func _handleURL(_ url: URL) {
		if url.scheme == "feather" {
			if url.host == "import-certificate" {
				guard
					let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
					let queryItems = components.queryItems
				else { return }
				
				func queryValue(_ name: String) -> String? {
					queryItems.first(where: { $0.name == name })?.value?.removingPercentEncoding
				}
				
				guard
					let p12Base64 = queryValue("p12"),
					let provisionBase64 = queryValue("mobileprovision"),
					let passwordBase64 = queryValue("password"),
					let passwordData = Data(base64Encoded: passwordBase64),
					let password = String(data: passwordData, encoding: .utf8)
				else { return }
				
				let generator = UINotificationFeedbackGenerator()
				generator.prepare()
				
				guard
					let p12URL = FileManager.default.decodeAndWrite(base64: p12Base64, pathComponent: ".p12"),
					let provisionURL = FileManager.default.decodeAndWrite(base64: provisionBase64, pathComponent: ".mobileprovision"),
					FR.checkPasswordForCertificate(for: p12URL, with: password, using: provisionURL)
				else {
					generator.notificationOccurred(.error)
					return
				}
				
				FR.handleCertificateFiles(
					p12URL: p12URL,
					provisionURL: provisionURL,
					p12Password: password
				) { error in
					if let error = error {
						UIAlertController.showAlertWithOk(title: .localized("Error"), message: error.localizedDescription)
					} else {
						generator.notificationOccurred(.success)
					}
				}
				return
			}
			if url.host == "export-certificate" {
				guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
				let queryItems = components.queryItems?.reduce(into: [String: String]()) { $0[$1.name.lowercased()] = $1.value } ?? [:]
				guard let callbackTemplate = queryItems["callback_template"]?.removingPercentEncoding else { return }
				FR.exportCertificateAndOpenUrl(using: callbackTemplate)
			}
			if let fullPath = url.validatedScheme(after: "/source/") {
				FR.handleSource(fullPath) { }
			}
			if let fullPath = url.validatedScheme(after: "/install/"), let downloadURL = URL(string: fullPath) {
				_ = DownloadManager.shared.startDownload(from: downloadURL)
			}
		} else {
			if url.pathExtension == "ipa" || url.pathExtension == "tipa" {
				if FileManager.default.isFileFromFileProvider(at: url) {
					guard url.startAccessingSecurityScopedResource() else { return }
					FR.handlePackageFile(url) { _ in }
				} else {
					FR.handlePackageFile(url) { _ in }
				}
				return
			}
		}
	}
}

class AppDelegate: NSObject, UIApplicationDelegate {
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		_createPipeline()
		_createDocumentsDirectories()
		ResetView.clearWorkCache()
		return true
	}
	
	private func _createPipeline() {
		DataLoader.sharedUrlCache.diskCapacity = 0
		let pipeline = ImagePipeline {
			let dataLoader: DataLoader = {
				let config = URLSessionConfiguration.default
				config.urlCache = nil
				return DataLoader(configuration: config)
			}()
			let dataCache = try? DataCache(name: "thewonderofyou.Feather.datacache")
			let imageCache = Nuke.ImageCache()
			dataCache?.sizeLimit = 500 * 1024 * 1024
			imageCache.costLimit = 100 * 1024 * 1024
			$0.dataCache = dataCache
			$0.imageCache = imageCache
			$0.dataLoader = dataLoader
			$0.dataCachePolicy = .automatic
			$0.isStoringPreviewsInMemoryCache = false
		}
		ImagePipeline.shared = pipeline
	}
	
	private func _createDocumentsDirectories() {
		let fileManager = FileManager.default
		let directories: [URL] = [fileManager.archives, fileManager.certificates, fileManager.signed, fileManager.unsigned]
		for url in directories {
			try? fileManager.createDirectoryIfNeeded(at: url)
		}
	}
}
