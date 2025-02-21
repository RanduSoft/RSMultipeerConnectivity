//
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache - RanduSoft
//  Version: 1.0.0
//

import Foundation

public struct DataObject<Content: Codable>: Codable, Identifiable, Equatable {
    public let id: UUID
    public let content: Content
    public let timestamp: Date
    
    public init(id: UUID = UUID(), content: Content, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
    }
    
    public static func ==(lhs: DataObject, rhs: DataObject) -> Bool {
        return lhs.id == rhs.id
    }
}
