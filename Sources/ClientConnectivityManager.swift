//
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache - RanduSoft
//  Version: 1.0.0
//

import SwiftUI
import MultipeerConnectivity

public class ClientConnectivityManager: BaseConnectivityManager {
    @Published public var availablePeers: [MCPeerID] = []
    @Published public var connectionState: MCSessionState = .notConnected
    
    public var onConnectionStateChange: ((Bool) -> Void)?
    
    private let serviceBrowser: MCNearbyServiceBrowser
    
    public override init(displayName: String, config: Config = Config()) {
        let peerId = MCPeerID(displayName: displayName)
        serviceBrowser = MCNearbyServiceBrowser(
            peer: peerId,
            serviceType: config.serviceType
        )
        super.init(peerId: peerId, config: config)
        serviceBrowser.delegate = self
    }
    
    public override func start() {
        serviceBrowser.startBrowsingForPeers()
    }
    
    public override func stop() {
        serviceBrowser.stopBrowsingForPeers()
        availablePeers.removeAll()
    }
    
    public func connectToServer(_ peerId: MCPeerID) {
        serviceBrowser.invitePeer(peerId, to: session, withContext: nil, timeout: 10)
    }
    
    public func disconnectFromServer() {
        session.disconnect()
    }
    
    public override func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectionState = state
            
            switch state {
                case .connected:
                    self.onConnectionStateChange?(true)
                case .notConnected:
                    self.onConnectionStateChange?(false)
                default:
                    break
            }
        }
    }
}

extension ClientConnectivityManager: MCNearbyServiceBrowserDelegate {
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard info?[PeerRole.roleKey] == String(describing: PeerRole.server) else {
            return
        }
        
        DispatchQueue.main.async {
            if !self.availablePeers.contains(peerID) {
                self.availablePeers.append(peerID)
            }
        }
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.availablePeers.removeAll { $0 == peerID }
        }
    }
}
