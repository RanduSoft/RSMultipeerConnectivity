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
    
    public var displayName: String {
        myPeerId.displayName
    }
    
    public var onReceive: ((_ payload: PeerPayload) -> Void)?
    
    private let handlersQueue = DispatchQueue(label: "handlers")
    private var typedHandlers: [UUID: (_ payload: PeerPayload) -> Void] = [:]
    
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
}

// send
public extension BaseConnectivityManager {
    func send(_ data: Data, toPeers peerIds: [MCPeerID]? = nil) throws {
        let targets = peerIds ?? session.connectedPeers
        
        guard targets.isEmpty == false else {
            throw ConnectivityError.sendFailed(ConnectivityError.noPeersConnected)
        }
        
        do {
            try session.send(data, toPeers: targets, with: .reliable)
        } catch {
            throw ConnectivityError.sendFailed(error)
        }
    }
    
    func send(_ object: Codable, toPeers peerIds: [MCPeerID]? = nil) throws {
        do {
            let data = try JSONEncoder().encode(object)
            try send(data, toPeers: peerIds)
        } catch {
            throw ConnectivityError.sendFailed(error)
        }
    }
    
    func sendDataObject<Content: Codable>(_ object: DataObject<Content>, toPeers peerIds: [MCPeerID]? = nil) throws {
        try send(object, toPeers: peerIds)
    }

    func sendDataObject<Content: Codable>(_ object: DataObject<Content>, toPeer peerId: MCPeerID) throws {
        try sendDataObject(object, toPeers: [peerId])
    }
}

// receive
public extension BaseConnectivityManager {
    @discardableResult
    private func receiveHandler<Result>(decoder: @escaping (Data) throws -> Result, completion: @escaping (Result, MCPeerID) -> Void) -> UUID {
        let id = UUID()
        
        let wrapper: (PeerPayload) -> Void = { payload in
            do {
                let value = try decoder(payload.data)
                
                DispatchQueue.main.async {
                    completion(value, payload.peerId)
                }
            } catch {
                Logger.log(String(describing: error), type: .error)
            }
        }
        
        handlersQueue.sync {
            typedHandlers[id] = wrapper
        }
        
        return id
    }
    
    @discardableResult
    func receive<T: Codable>(_ type: T.Type = T.self, completion: @escaping ((object: T, peerId: MCPeerID)) -> Void) -> UUID {
        receiveHandler(
            decoder: { try JSONDecoder().decode(T.self, from: $0) },
            completion: { completion(($0, $1)) }
        )
    }
    
    @discardableResult
    func receiveDataObject<Content: Codable>(_ type: Content.Type = Content.self, completion: @escaping (DataObjectPayload<Content>) -> Void) -> UUID {
        receiveHandler(
            decoder: { try JSONDecoder().decode(DataObject<Content>.self, from: $0) },
            completion: { completion(($0, $1)) }
        )
    }
    
    func cancelReceiveDataObject(id: UUID) {
        _ = handlersQueue.sync { typedHandlers.removeValue(forKey: id) }
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
            self.onReceive?(payload)
        }
        
        handlersQueue.sync {
            for handler in typedHandlers.values {
                handler(payload)
            }
        }
    }
}

// delegate
extension BaseConnectivityManager: MCSessionDelegate {
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        processReceivedData((data, peerID))
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {}
}
