import CoreData
import Foundation

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TherapyDataModel")
        
        // Use app group for shared data access
        guard let storeURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.AAFU.Sessions"
        )?.appendingPathComponent("TherapyData.sqlite") else {
            fatalError("Unable to create store URL for app group")
        }
        
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        
        // Enable file protection for HIPAA compliance
        storeDescription.setOption(FileProtectionType.complete as NSObject,
                                  forKey: NSPersistentStoreFileProtectionKey)
        
        // Enable persistent history tracking for WatchConnectivity sync
        storeDescription.setOption(true as NSNumber,
                                  forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber,
                                  forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load store: \(error.localizedDescription)")
            }
        }
        
        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    func save(context: NSManagedObjectContext? = nil) {
        let contextToSave = context ?? persistentContainer.viewContext
        
        guard contextToSave.hasChanges else { return }
        
        do {
            try contextToSave.save()
        } catch {
            print("Core Data save error: \(error.localizedDescription)")
        }
    }
    
    func saveContext() {
        save()
    }
}