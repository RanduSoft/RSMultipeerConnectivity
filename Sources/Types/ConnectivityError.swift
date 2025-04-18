//
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache - RanduSoft
//  Version: 1.0.0
//

import Foundation

public enum ConnectivityError: Error {
    case encodingFailed
    case decodingFailed
    
    case sendFailed(Error)
    case invalidData(Error)
    case noPeersConnected
    
    case connectionLost
}
