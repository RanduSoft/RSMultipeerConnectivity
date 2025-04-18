//
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache - RanduSoft
//  Version: 1.1.0
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
    
    public var onReceiveData: ((PeerPayload) -> Void)?
    
    private var typedHandlers: [UUID: (PeerPayload) -> Void] = [:]
    
    let session: MCSession
    
    init(displayName: String, config: Config = Config()) {
        self.config = config
        Logger.enableLogging = config.enableLogging
        
        guard Validator.peerDisplayNameIsValid(displayName) else {
            fatalError("Invalid peer display name, make sure its under 63 bytes, not empty or contain only whitespaces")
        }
        
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
    
    public func send<T: Codable>(_ object: T, toPeers peerIds: [MCPeerID]? = nil) throws {
        let targets = peerIds ?? session.connectedPeers
        
        guard targets.isEmpty == false else {
            throw ConnectivityError.sendFailed(ConnectivityError.noPeersConnected)
        }
        
        do {
            let data = try JSONEncoder().encode(object)
            try session.send(data, toPeers: targets, with: .reliable)
        } catch {
            throw ConnectivityError.sendFailed(error)
        }
    }
    
    public func send<T: Codable>(_ object: T, toPeer peerId: MCPeerID) throws {
        try send(object, toPeers: [peerId])
    }
    
    @discardableResult
    public func receive<Content: Codable>(_ type: Content.Type = Content.self, completion: @escaping (DataObjectPayload<Content>) -> Void) -> UUID {
        let id = UUID()
        let wrapper: (PeerPayload) -> Void = { payload in
            do {
                let dataObject = try JSONDecoder().decode(DataObject<Content>.self, from: payload.data)
                DispatchQueue.main.async {
                    completion((dataObject, payload.peerId))
                }
            } catch {
                Logger.log(String(describing: error), type: .error)
            }
        }
        typedHandlers[id] = wrapper
        return id
    }
    
    public func cancelReceive(id: UUID) {
        typedHandlers.removeValue(forKey: id)
    }
    
    private func processReceivedData(_ payload: PeerPayload) {
        if let kickData = try? JSONDecoder().decode(KickRequest.self, from: payload.data) {
            Logger.log("Received kick request, will disconnect. Reason: \(kickData.reason ?? "NONE")", type: .info)
            
            DispatchQueue.main.async {
                (self as? ClientConnectivityManager)?.disconnectFromServer()
                (self as? ClientConnectivityManager)?.onKick?(kickData.reason)
            } ; return
        }
        
        DispatchQueue.main.async {
            self.onReceiveData?(payload)
        }
        
        for handler in typedHandlers.values {
            handler(payload)
        }
    }
}

extension BaseConnectivityManager: MCSessionDelegate {
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        processReceivedData((data, peerID))
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {}
}
