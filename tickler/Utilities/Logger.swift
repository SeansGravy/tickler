import Foundation
import os.log

struct AppLogger {
    private static let subsystem = "com.seansgravy.tickler"

    static let priceManager = Logger(subsystem: subsystem, category: "PriceManager")
    static let coinbase = Logger(subsystem: subsystem, category: "Coinbase")
    static let yahoo = Logger(subsystem: subsystem, category: "Yahoo")
    static let general = Logger(subsystem: subsystem, category: "General")

    // Also write to a file for easy debugging
    private static let logFile: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("tickler", isDirectory: true)
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        return appFolder.appendingPathComponent("debug.log")
    }()

    static func log(_ message: String, category: String = "General") {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logLine = "[\(timestamp)] [\(category)] \(message)\n"

        // Write to file
        if let data = logLine.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFile.path) {
                if let handle = try? FileHandle(forWritingTo: logFile) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: logFile)
            }
        }

        // Also use os_log
        os_log("%{public}@", log: OSLog(subsystem: subsystem, category: category), type: .debug, message)
    }

    static func clearLog() {
        try? FileManager.default.removeItem(at: logFile)
    }

    static var logFilePath: String {
        logFile.path
    }
}
