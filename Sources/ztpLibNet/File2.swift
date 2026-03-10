//
//  File 2.swift
//  ztpLibNet
//
//  Created by Kong Hwi Tan on 9/3/26.
//

import Foundation

public enum ztpLoadingState {
  case idle, loading, loaded, failed
}

@Observable
public class ztpDataService<T: Decodable> {
  public var loadingState: ztpLoadingState = .idle //***
  public var data: T?
  public var networkError: ztpNetworkError? = nil

  let urlString: String
  private let configurator: ((JSONDecoder) -> Void)?

  private let netUtil = ztpNetworkUtility.self
  //var isLoading: Bool = false

  public init(urlString: String,
              configurator: ((JSONDecoder) -> Void)? = nil) {
    self.urlString = urlString
    self.configurator = configurator
  }

  public func fetchData() async {
    loadingState = .loading //****
    //isLoading = true
    networkError = nil
    //defer { isLoading = false }

    #if DEBUG
    try? await Task.sleep(for: .seconds(0.5))
    #endif

    do {
      if let configurator {
        data = try await netUtil
          .fetchAndDecodeJSONthrows(from: urlString,
                                    configureDecoder: configurator)

        if data != nil { loadingState = .loaded } //***

      } else {
        data = try await netUtil
          .fetchAndDecodeJSONthrows(from: urlString)

        if data != nil { loadingState = .loaded } //***

      }
    } catch {
      networkError = error
      loadingState = .failed //***
    }
  }
}




//eof

