//
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache - RanduSoft
//  Version: 1.1.0
//

import SwiftUI
import MultipeerConnectivity

public class ServerConnectivityManager: BaseConnectivityManager {
    @Published public var connectedClients: [MCPeerID] = []
    @Published public var connectionState: MCSessionState = .notConnected
    
    public var onPeerConnected: ((_ peerId: MCPeerID) -> Void)?
    public var onPeerDisconnected: ((_ peerId: MCPeerID) -> Void)?
    public var onPeerRejected: ((_ peerId: MCPeerID, _ reason: String?) -> Void)?
    
    public var invitationValidator: ((_ peerId: MCPeerID, _ clientHandshakeRequest: ClientHandshakeRequest) -> ServerHandshakeResponse)?
    
    private var pendingKicks = [MCPeerID: String?]()
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
                    
                    if let kickReason = self.pendingKicks.removeValue(forKey: peerID) {
                        try? self.kickPeer(peerID, forReason: kickReason)
                        Logger.log("\(self.displayName) kicked \(peerID.displayName) – \(kickReason ?? "UNKNOWN")", type: .connection)
                    }
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
    
    public func kickPeer(_ peerId: MCPeerID, forReason reason: String? = nil) throws {
        try self.kickPeers([peerId], forReason: reason)
    }
    
    public func kickPeers(_ peerIds: [MCPeerID], forReason reason: String? = nil) throws {
        try self.send(KickRequest(reason: reason), toPeers: peerIds)
    }
}

extension ServerConnectivityManager: MCNearbyServiceAdvertiserDelegate {
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Logger.log("\(self.displayName) received invitation from: \(peerID.displayName)", type: .info)
        
        invitationHandler(true, session)
        
        guard let context, let clientHandshakeRequest = try? JSONDecoder().decode(ClientHandshakeRequest.self, from: context) else {
            return
        }
        
        guard let serverResponse = self.invitationValidator?(peerID, clientHandshakeRequest) else {
            Logger.log("\(self.displayName) failed to decode serverResponse from: \(peerID.displayName)", type: .error)
            return
        }
        
        if serverResponse.allowed == false {
            onPeerRejected?(peerID, serverResponse.reason)
            pendingKicks[peerID] = serverResponse.reason
        }
    }
}
