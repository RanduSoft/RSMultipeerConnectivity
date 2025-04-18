//
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache - RanduSoft
//  Version: 1.0.0
//

import Foundation

public extension BaseConnectivityManager {
    enum PeerRole {
        case server
        case client
        
        var discoveryInfo: [String: String] {
            [PeerRole.roleKey: String(describing: self)]
        }
        
        static var roleKey = "role"
    }
}
