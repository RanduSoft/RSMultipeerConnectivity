//
//  Extensions.swift
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache on 08.04.2025.
//

import Foundation
import MultipeerConnectivity

public extension MCPeerID {
    var displayNameWithoutVersion: String {
        self.displayName.replacingOccurrences(of: "\\s*\\[.*?\\]\\s*$", with: "", options: .regularExpression)
    }
}

extension String {
    static var kickRequest: String {
        "FORCE_DISCONNECT"
    }
    
    var isKickRequest: Bool {
        self == String.kickRequest
    }
}
