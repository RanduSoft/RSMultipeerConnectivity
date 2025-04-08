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
    let validClientVersions: [String]
    
    public init(serviceType: String = "randusoft-mp", enableLogging: Bool = false, validClientVersions: [String] = []) {
        self.serviceType = serviceType
        self.enableLogging = enableLogging
        self.validClientVersions = validClientVersions
    }
}
