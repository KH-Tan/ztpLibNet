//
//  File 2.swift
//  ztpLibNet
//
//  Created by Kong Hwi Tan on 9/3/26.
//

import Foundation

@Observable
public class ztpDataService<T: Decodable> {
  var data: T?

  let urlString: String
  private let configurator: ((JSONDecoder) -> Void)?

  private let netUtil = ztpNetworkUtility.self
  var networkError: ztpNetworkError? = nil
  var isLoading: Bool = false

  init(urlString: String, configurator: ((JSONDecoder) -> Void)? = nil) {
    self.urlString = urlString
    self.configurator = configurator
  }

  func fetchData() async {
    isLoading = true
    networkError = nil
    defer { isLoading = false }

    #if DEBUG
    try? await Task.sleep(for: .seconds(2))
    #endif

    do {
      if let configurator {
        data = try await netUtil
          .fetchAndDecodeJSONthrows(from: urlString,
                                    configureDecoder: configurator)
      } else {
        data = try await netUtil
          .fetchAndDecodeJSONthrows(from: urlString)
      }
    } catch {
      networkError = error
    }
  }
}




