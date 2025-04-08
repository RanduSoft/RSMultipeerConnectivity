//
//  Validator.swift
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache on 08.04.2025.
//

public struct Validator {
    static func peerDisplayNameIsValid(_ displayName: String) -> Bool {
        guard !displayName.isEmpty && !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        guard displayName.utf8.count <= 63 else {
            return false
        }
        
        return true
    }
}
