//
//  File.swift
//  ztpLibNet
//
//  Created by Kong Hwi Tan on 20/7/26.
//

import SwiftUI
import Network

#Preview {
  ztpNWMonitorTemplate()
}

struct ztpNWMonitorTemplate: View {

  @State private var nwMonitor = ztpNWMonitor()

  var body: some View {
    VStack {

      Text("Network Monitor")
      Divider()

      Image(systemName: nwMonitor.connectIcon)
        .foregroundStyle(nwMonitor.connectIconColor)
      Text(nwMonitor.statusText)
      Text(nwMonitor.statusDesc)

      Text("Path Details").font(.footnote)
      Divider()
      LabeledContent("Expensive Connection", value: nwMonitor.expensiveText)
      LabeledContent("Low Data Mode", value: nwMonitor.lowDataModeText)
      LabeledContent("Available Interfaces", value: nwMonitor.interfaceSummary)

    }//vstack
    .padding()
  }//body
}//struct



//KIV    Icons for   LoopBack/Ethernet/Cellular
//
@MainActor
@Observable
public final class ztpNWMonitor {

  public init() { startMonitoring() }
  deinit { monitor.cancel() }

  public enum ConnectionStatus: String {
    case connected = "Connected",
         disconnected = "Disconnected",
         requiresConnection = "Requires Connection"
  }

  public var status = ConnectionStatus.requiresConnection
  public var isExpensive = false
  public var isConstrained = false
  public var availableInterfaces: [String] = []

  public var isConnected: Bool { status == .connected }

  public var statusText: String {
    status.rawValue
  }
  public var statusDesc: String {
    isConnected ?
    "Network is working properly." :
    "Network CANNOT be reached!"
  }

  public var expensiveText: String {
    isExpensive ? "Yes":"No"
  }
  public var lowDataModeText: String {
    isConstrained ? "Yes":"No"
  }
  public var interfaceSummary: String {
    availableInterfaces.isEmpty ?
    "None" :
    availableInterfaces.joined(separator: ", ")
  }

  public var connectIcon: String {
    isConnected ? "wifi" : "wifi.slash"

    // "wifi" : "wifi.slash"
    //cellularbars
    //cable.coaxial
    //cable.connector   cable.connector.slash
  }
  public var connectIconColor: Color {
    isConnected ? .green : .red
  }


  private let monitor = NWPathMonitor()
  private let queue = DispatchQueue(label: "ztpNetworkMonitor")
  private func startMonitoring() {

    monitor.pathUpdateHandler = { [weak self] path in
      Task { @MainActor [weak self, path] in
        guard let self else { return }
        self.updateStatus(from: path)
      }
    }

    monitor.start(queue: queue)
  }

  private func updateStatus(from path: NWPath) {
    switch path.status {
    case .satisfied:          status = .connected
    case .unsatisfied:        status = .disconnected
    case .requiresConnection: status = .requiresConnection
    @unknown default:         status = .requiresConnection
    }

    isExpensive = path.isExpensive
    isConstrained = path.isConstrained
    availableInterfaces = Array(Set(path.availableInterfaces.map(\.displayName)))
  }

}//class

fileprivate extension NWInterface {

  var displayName: String {
    switch type {
    case .wifi:          "Wi-fi"
    case .wiredEthernet: "Ethernet"
    case .cellular:      "Cellular"
    case .loopback:      "Loopback"
    case .other:         "Other"
    @unknown default:    "Unknown"
    }
  }

}//extension



//eof
