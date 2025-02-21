//
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache - RanduSoft
//  Version: 1.0.0
//

import Foundation

public struct Config {
    let serviceType: String
    let enableLogging: Bool
    
    public init(serviceType: String = "randusoft-mp", enableLogging: Bool = false) {
        self.serviceType = serviceType
        self.enableLogging = enableLogging
    }
}
