//
//  RSMultipeerConnectivity
//
//  Created by Radu Ursache - RanduSoft
//  Version: 1.0.0
//

import Foundation

class Logger {
    enum LogType: String {
        case info = "INFO"
        case error = "ERROR"
        case connection = "CONN"
    }
    
    static var enableLogging = true
    
    static func log(_ message: String, type: LogType = .info, function: String = #function) {
        guard enableLogging else { return }
        
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        
        print("[\(timestamp)] [\(type.rawValue)] [\(function)] \(message)")
    }
}
