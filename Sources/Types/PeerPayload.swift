//
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache - RanduSoft
//  Version: 1.0.0
//

import Foundation
import MultipeerConnectivity

public typealias PeerPayload = (data: Data, peerId: MCPeerID)
public typealias DataObjectPayload<Content: Codable> = (dataObject: DataObject<Content>, peerId: MCPeerID)
