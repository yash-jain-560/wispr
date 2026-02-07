import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let fileName = "wispr_data.json"
    
    private var fileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("com.abcom.optionstatuschip")
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        
        return appDirectory.appendingPathComponent(fileName)
    }
    
    func save<T: Encodable>(_ data: T) {
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: fileURL)
            print("Successfully saved data to \(fileURL.path)")
        } catch {
            print("Failed to save data: \(error)")
        }
    }
    
    func load<T: Decodable>() -> T? {
        // Debug
        print("Loading data from \(fileURL.path)")
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("No persistence file found at \(fileURL.path)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Failed to load data: \(error)")
            return nil
        }
    }
}
