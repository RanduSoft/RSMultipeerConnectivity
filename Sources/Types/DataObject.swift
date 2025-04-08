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

extension DataObject {
    static var kickRequest: DataObject<String> {
        DataObject<String>(id: UUID(uuidString: "d15c0000-0000-0000-0000-000000000000")!, content: "FORCE_DISCONNECT")
    }
    
    var isKickRequest: Bool {
        DataObject.kickRequest.content == content as? String
    }
}
