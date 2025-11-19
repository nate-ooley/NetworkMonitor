import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create 10 fake network logs for the SwiftUI Preview
        for i in 0..<10 {
            let newLog = NetworkLog(context: viewContext)
            newLog.timestamp = Date()
            newLog.url = "https://api.example.com/endpoint/\(i)"
            newLog.method = i % 2 == 0 ? "GET" : "POST"
            newLog.statusCode = Int16(i % 2 == 0 ? 200 : 404)
            newLog.status = i % 2 == 0 ? "Success" : "Failure"
            newLog.duration = Double.random(in: 0.1...1.5)
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "NetworkMonitor") // Must match .xcdatamodeld name
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
