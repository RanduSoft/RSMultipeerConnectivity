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
    public var onPeerRejected: ((MCPeerID) -> Void)?
    
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private var validClientVersions: [String] = []
    
    public override init(displayName: String, config: Config = Config()) {
        let peerId = MCPeerID(displayName: displayName)
        serviceAdvertiser = MCNearbyServiceAdvertiser(
            peer: peerId,
            discoveryInfo: PeerRole.server.discoveryInfo,
            serviceType: config.serviceType
        )
        super.init(peerId: peerId, config: config)
        serviceAdvertiser.delegate = self
        validClientVersions = config.validClientVersions
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
        
        if validClientVersions.isEmpty {
            invitationHandler(true, session) ; return
        }
        
        guard let peerVersionString = versionFromDisplayName(peerID.displayName), validClientVersions.contains(peerVersionString) else {
            Logger.log("\(self.displayName) rejected invitation from: \(peerID.displayName) due to incompatible version", type: .error)
            
            self.onPeerRejected?(peerID)
            invitationHandler(false, session)
            return
        }
        
        invitationHandler(true, session)
    }
}

extension ServerConnectivityManager {
    func versionFromDisplayName(_ displayName: String) -> String? {
        let pattern = "\\[v([\\d\\.]+)\\]$"
        
        if let range = displayName.range(of: pattern, options: .regularExpression) {
            let versionWithBrackets = displayName[range]
            let startIndex = versionWithBrackets.index(versionWithBrackets.startIndex, offsetBy: 2)
            let endIndex = versionWithBrackets.index(versionWithBrackets.endIndex, offsetBy: -1)
            return String(versionWithBrackets[startIndex..<endIndex])
        }
        
        return nil
    }
}
