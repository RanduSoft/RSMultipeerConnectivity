//
//  Extensions.swift
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache on 18.04.2025.
//

import Foundation
import MultipeerConnectivity

extension MCPeerID: @retroactive Identifiable {
    public var id: String {
        "\(self)"
    }
}
