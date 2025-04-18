//
//  HandshakeContext.swift
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache on 18.04.2025.
//

import Foundation

public struct ClientHandshakeRequest: Codable {
    public let deviceDetails: String
    public let appVersion: String
    
    public init(deviceDetails: String, appVersion: String) {
        self.deviceDetails = deviceDetails
        self.appVersion = appVersion
    }
}

public struct ServerHandshakeResponse: Codable {
    public let allowed: Bool
    public let reason: String?
    
    public init(allowed: Bool, reason: String? = nil) {
        self.allowed = allowed
        self.reason = reason
    }
}
