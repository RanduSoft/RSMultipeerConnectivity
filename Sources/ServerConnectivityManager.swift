//
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache - RanduSoft
//  Version: 1.0.0
//


import SwiftUI
import MultipeerConnectivity

public class ServerConnectivityManager: BaseConnectivityManager {
    @Published public var connectedClients: [MCPeerID] = []
    @Published public var connectionState: MCSessionState = .notConnected
    
    public var onPeerConnected: ((MCPeerID) -> Void)?
    public var onPeerDisconnected: ((MCPeerID) -> Void)?
    
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    
    public override init(displayName: String, config: Config = Config()) {
        let peerId = MCPeerID(displayName: displayName)
        serviceAdvertiser = MCNearbyServiceAdvertiser(
            peer: peerId,
            discoveryInfo: PeerRole.server.discoveryInfo,
            serviceType: config.serviceType
        )
        super.init(peerId: peerId, config: config)
        serviceAdvertiser.delegate = self
    }
    
    public override func start() {
        serviceAdvertiser.startAdvertisingPeer()
    }
    
    public override func stop() {
        serviceAdvertiser.stopAdvertisingPeer()
    }
    
    public override func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectionState = state
            
            Logger.log("\(self.displayName) state changed: \(state)", type: .info)
            
            switch state {
                case .connected:
                    self.connectedClients.append(peerID)
                    self.onPeerConnected?(peerID)
                case .notConnected:
                    self.connectedClients.removeAll { $0 == peerID }
                    self.onPeerDisconnected?(peerID)
                case .connecting:
                    break
                @unknown default:
                    break
            }
        }
    }
}

extension ServerConnectivityManager: MCNearbyServiceAdvertiserDelegate {
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Logger.log("\(self.displayName) received invitation from: \(peerID.displayName)", type: .info)
        
        invitationHandler(true, session)
    }
}
