//
//  KickRequest.swift
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache on 18.04.2025.
//

import Foundation

struct KickRequest: Codable {
    private let requestID: UUID
    let reason: String?
    
    init(reason: String?) {
        self.requestID = UUID()
        self.reason = reason
    }
}
