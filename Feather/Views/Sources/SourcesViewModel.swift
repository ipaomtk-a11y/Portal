//
//  SourcesViewModel.swift
//  IPAOMTK
//
//  Professional cleaned version for IPAOMTK
//

import Foundation
import AltSourceKit
import SwiftUI
import NimbleJSON

final class SourcesViewModel: ObservableObject {
	static let shared = SourcesViewModel()
	
	typealias RepositoryDataHandler = Result<ASRepository, Error>
	
	private let _dataService = NBFetchService()
	
	@Published var sources: [AltSource: ASRepository] = [:]
	@Published var isLoading = false
	
	var isFinished = true
	
	func fetchSources(
		_ sources: FetchedResults<AltSource>,
		refresh: Bool = false,
		batchSize: Int = 4
	) async {
		guard isFinished else { return }
		
		if !refresh, sources.allSatisfy({ self.sources[$0] != nil }) {
			return
		}
		
		isFinished = false
		
		await MainActor.run {
			self.isLoading = true
			if refresh {
				self.sources = [:]
			}
		}
		
		defer {
			Task { @MainActor in
				self.isLoading = false
			}
			isFinished = true
		}
		
		let sourcesArray = Array(sources)
		
		for startIndex in stride(from: 0, to: sourcesArray.count, by: batchSize) {
			let endIndex = min(startIndex + batchSize, sourcesArray.count)
			let batch = sourcesArray[startIndex..<endIndex]
			
			let batchResults = await withTaskGroup(
				of: (AltSource, ASRepository?).self,
				returning: [AltSource: ASRepository].self
			) { group in
				for source in batch {
					group.addTask {
						guard let url = source.sourceURL else {
							return (source, nil)
						}
						
						return await withCheckedContinuation { continuation in
							self._dataService.fetch(from: url) { (result: RepositoryDataHandler) in
								switch result {
								case .success(let repo):
									continuation.resume(returning: (source, repo))
								case .failure:
									continuation.resume(returning: (source, nil))
								}
							}
						}
					}
				}
				
				var results = [AltSource: ASRepository]()
				
				for await (source, repo) in group {
					if let repo {
						results[source] = repo
					}
				}
				
				return results
			}
			
			await MainActor.run {
				for (source, repo) in batchResults {
					self.sources[source] = repo
				}
			}
		}
	}
}
