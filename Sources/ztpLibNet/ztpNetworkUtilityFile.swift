//
//  File1.swift
//  ztpLibNet
//
//  Created by Kong Hwi Tan on 7/3/26.
//

import Foundation


public enum ztpNetworkTransportError: Error {
  case offline, timedOut, dnsFailure, tlsFailure,
       cannotConnect, cancelled, unknown

  init(urlError: URLError) {

    switch (urlError.code) {
    case .notConnectedToInternet, .networkConnectionLost,
         .dataNotAllowed:
      self = .offline

    case .timedOut:
      self = .timedOut

    case .dnsLookupFailed, .cannotFindHost:
      self = .dnsFailure

    case .secureConnectionFailed, .serverCertificateHasBadDate,
         .serverCertificateUntrusted, .serverCertificateHasUnknownRoot:
      self = .tlsFailure

    case .cannotConnectToHost:
      self = .cannotConnect

    case .cancelled:
      self = .cancelled

    default:
      self = .unknown
    }
  }

  var userMessage: String {
    switch self {
    case .offline:
      "You are offline. Please check your internet connection."
    case .timedOut:
      "The request timed out. Please try again later."
    case .dnsFailure, .cannotConnect:
      "Server cannot be reached right now. Please try again later."
    case .tlsFailure:
      "A secure connection could not be established."
    case .cancelled:
      "The request was cancelled."
    case .unknown:
      "An Unknown network error occurred. Please try again later."
    }
  }
}


public enum ztpNetworkError: Error {
  case badURL,
       //request(String),
       transport(ztpNetworkTransportError),
       httpResponse,
       httpStatusCode(Int),
       decodingError(String)

  public var userMessage: String {
    switch self {
    case .badURL:
      "URL error"
    case .transport(let transportError):
      transportError.userMessage
    case .httpResponse:
      "HTTP response error"
    case .httpStatusCode(let code):
      switch code {
      case 401: "Your session has expired. Please sign-in again."
      case 403: "You do not have permission for the requested action."
      case 404: "The requested resource could not be found."
      case 429: "The Server has too many requests pending. Please wait and try again later."
      case 500...509: "The Server is not responding. Please try again later."
      default: "Something went wrong. Status Code: \(code)"
      }
    case .decodingError:
      "Decoding error"
      //default: "Unknown Error Encountered"
    }
  }

  public var techDescription: String {
    switch self {
    case .badURL:
      "Invalid URL"
      //case .request(let message):     "Request error: \(message)"
    case .transport(let transportError):
      transportError.userMessage
    case .httpResponse:
      "Network error: Response not HTTPURLResponse"
    case .httpStatusCode(let code):
      "HTTP error: Status code \(code)"
    case .decodingError(let detail):
      detail
    }
  }

}


public enum ztpNetworkUtility {

  // Throws
  static public func fetchAndDecodeJSONthrows<T: Decodable>(
    from urlString: String,
    configureDecoder: ((JSONDecoder)->Void)?=nil) async throws(ztpNetworkError)->T {

      guard let url = URL(string: urlString) else {
        throw ztpNetworkError.badURL
      }

      do {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
          throw ztpNetworkError.httpResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
          throw ztpNetworkError.httpStatusCode(httpResponse.statusCode)
        }

        do {
          let decoder = JSONDecoder()
          configureDecoder?(decoder)
          let decoded = try decoder.decode(T.self, from: data)
          return decoded

        } catch let error as DecodingError {
          throw ztpNetworkError.decodingError(decodingError(error: error))
        } catch {
          let errMsg = ("Data as string: \(String(data: data, encoding: .utf8) ?? "could not convert data to string")")
          throw ztpNetworkError.decodingError(errMsg)
        }

      } catch let networkError as ztpNetworkError {
        throw networkError

      } catch let urlError as URLError {
        throw ztpNetworkError.transport(ztpNetworkTransportError(urlError: urlError))

      } catch {
        throw ztpNetworkError.transport(.unknown)
      }

    } // func


  // Archived - Does not throw, only prints error
  static public func fetchAndDecodeJSON<T: Decodable>(
    from urlString: String,
    configureDecoder: ((JSONDecoder)->Void)?=nil) async->T? {

      guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return nil
      }

      do {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
          print("Network error: Response not HTTPURLResponse")
          return nil
        }
        guard (200...299).contains(httpResponse.statusCode) else {
          print("HTTP error: Status code \(httpResponse.statusCode)")
          return nil
        }

        do {
          let decoder = JSONDecoder()
          configureDecoder?(decoder)
          let decoded = try decoder.decode(T.self, from: data)
          return decoded

        } catch let error as DecodingError {

          print(decodingError(error: error))
          return nil

        } catch {
          print("Decoding error: \(error.localizedDescription)")
          print("Data as string: \(String(data: data, encoding: .utf8) ?? "cannot convert data to String")")
          return nil
        }

      } catch {
        print("Request error: \(error.localizedDescription)")
        return nil
      }
    } // func


  static func decodingError(error: DecodingError) -> String {
    switch error {
    case .typeMismatch(let type, let context):
      """
      Decoding Error:
      Type mismatch for Type '\(type)'
      
      Context:
      \(context.debugDescription)  
      Coding Path:
      \(context.codingPath.map{$0.stringValue}.joined(separator: "-> ")) 
      """
    case .valueNotFound(let type, let context):
      """
      Decoding Error:
      Value of Type '\(type)' not found
      
      Context:
      \(context.debugDescription)  
      Coding Path:
      \(context.codingPath.map{$0.stringValue}.joined(separator: "-> ")) 
      """
    case .keyNotFound(let codingKey, let context):
      """
      Decoding Error:
      Key '\(codingKey.stringValue)' not found
      
      Context:
      \(context.debugDescription)  
      Coding Path:
      \(context.codingPath.map{$0.stringValue}.joined(separator: "-> ")) 
      """
    case .dataCorrupted(let context):
      """
      Decoding Error:
      Data corrupted
      
      Context:
      \(context.debugDescription)  
      Coding Path:
      \(context.codingPath.map{$0.stringValue}.joined(separator: "-> ")) 
      """
    @unknown default:
      """
      Decoding Error:
      Unknown error
      
      \(error.localizedDescription)
      """
    }
  } // func

} // class



//eof

