//
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache - RanduSoft
//  Version: 1.0.0
//

import SwiftUI
import MultipeerConnectivity

public class BaseConnectivityManager: NSObject, ObservableObject {
    private let config: Config
    private let myPeerId: MCPeerID
    
    private var onReceive: ((PeerPayload) -> Void)?
    
    public var displayName: String {
        myPeerId.displayName
    }
    
    let session: MCSession
    
    init(displayName: String, config: Config = Config()) {
        self.config = config
        Logger.enableLogging = config.enableLogging
        
        self.myPeerId = MCPeerID(displayName: displayName)
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        session.delegate = self
    }
    
    init(peerId: MCPeerID, config: Config = Config()) {
        self.config = config
        Logger.enableLogging = config.enableLogging
        
        self.myPeerId = peerId
        self.session = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        session.delegate = self
    }
    
    func start() {
        fatalError("Override this method")
    }
    
    func stop() {
        fatalError("Override this method")
    }
    
    public func send<Content: Codable>(_ object: DataObject<Content>) throws {
        do {
            let data = try JSONEncoder().encode(object)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            throw ConnectivityError.sendFailed(error)
        }
    }
    
    public func receive<Content: Codable>(_ type: Content.Type, completion: @escaping (DataObjectPayload<Content>) -> Void) {
        onReceive = { peerPayload in
            do {
                let dataObject = try JSONDecoder().decode(DataObject<Content>.self, from: peerPayload.data)
                DispatchQueue.main.async {
                    completion((dataObject, peerPayload.peerId))
                }
            } catch {
                Logger.log(String(describing: error), type: .error)
            }
        }
    }
}

extension BaseConnectivityManager: MCSessionDelegate {
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        onReceive?((data, peerID))
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {}
}
