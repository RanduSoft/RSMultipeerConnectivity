//
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache - RanduSoft
//  Version: 1.0.0
//

import SwiftUI

#if os(iOS)

struct DebugView<Content: Codable>: View {
    @StateObject private var manager: BaseConnectivityManager
    
    @State private var inputText: String = ""
    @State private var receivedObject: DataObject<Content>?
    
    init(displayName: String, role: BaseConnectivityManager.PeerRole, config: Config = Config(enableLogging: true)) {
        let manager: BaseConnectivityManager = role == .server
        ? ServerConnectivityManager(displayName: displayName, config: config)
        : ClientConnectivityManager(displayName: displayName, config: config)
        
        _manager = StateObject(wrappedValue: manager)
    }
    
    var body: some View {
        Group {
            if let serverManager = manager as? ServerConnectivityManager {
                serverView(manager: serverManager)
            } else if let clientManager = manager as? ClientConnectivityManager {
                clientView(manager: clientManager)
            }
        }.onAppear {
            if let serverManager = manager as? ServerConnectivityManager {
                serverManager.onPeerConnected = { peerId in
                    Logger.log("\(peerId.displayName) connected to \(serverManager.displayName)", type: .connection, function: "onPeerConnected")
                }
                serverManager.onPeerDisconnected = { peerId in
                    Logger.log("\(peerId.displayName) disconnected from \(serverManager.displayName)", type: .connection, function: "onPeerDisconnected")
                }
            } else if let clientManager = manager as? ClientConnectivityManager {
                clientManager.onConnectionStateChange = { isConnected in
                    Logger.log("\(clientManager.displayName) \(isConnected ? "connected to" : "disconnected from") server", type: .connection, function: "onConnectionStateChange")
                }
            }
            manager.receive(Content.self) { peerPayload in
                Logger.log("Received data from \(peerPayload.peerId.displayName)", type: .info, function: "receive")
                self.receivedObject = peerPayload.dataObject
            }
            manager.start()
        }.onDisappear {
            manager.stop()
        }.padding()
    }
    
    private func serverView(manager: ServerConnectivityManager) -> some View {
        VStack {
            Text(manager.displayName)
                .font(.title)
            Text("Connected clients: \(manager.connectedClients.count)")
            
            TextField("Enter text", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Button("Send") {
                sendMessage(inputText)
            }
            
            if let receivedData = receivedObject?.content {
                Text("Received: \(receivedData)")
                    .padding()
            }
        }
    }
    
    private func clientView(manager: ClientConnectivityManager) -> some View {
        VStack {
            switch manager.connectionState {
                case .connected:
                    Text("Connected")
                        .font(.title)
                        .foregroundColor(.green)
                    
                    TextField("Enter text", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                    
                    Button("Send") {
                        sendMessage(inputText)
                    }
                    
                    if let receivedData = receivedObject?.content {
                        Text("Received: \(receivedData)")
                            .padding()
                    }
                    
                    Button("Disconnect") {
                        manager.disconnectFromServer()
                    }.foregroundStyle(.red).padding(.top, 32)
                case .connecting:
                    Text("Connecting...")
                        .font(.title)
                case .notConnected:
                    Text("Select a server")
                        .font(.title)
                    
                    List(manager.availablePeers, id: \.self) { peer in
                        Button(peer.displayName) {
                            manager.connectToServer(peer)
                        }
                    }.listStyle(.insetGrouped).padding(-20)
                @unknown default:
                    EmptyView()
            }
        }
    }
    
    private func sendMessage(_ message: String) {
        do {
            try manager.send(
                DataObject(content: message)
            )
        } catch {
            Logger.log(String(describing: error), type: .error)
        }
    }
}

#Preview {
    GeometryReader { geometry in
        VStack(spacing: 0) {
            DebugView<String>(displayName: "Server \(Int.random(in: 1000..<9999))", role: .server)
                .frame(height: (geometry.size.height - 20) / 2)
                .background(.ultraThickMaterial)
            
            Divider()
            
            DebugView<String>(displayName: "Client \(Int.random(in: 1000..<9999))", role: .client)
                .frame(height: (geometry.size.height - 20) / 2)
                .background(Color(uiColor: .secondarySystemBackground))
        }.padding(.bottom, 20)
    }.ignoresSafeArea(edges: .bottom)
}

#endif
