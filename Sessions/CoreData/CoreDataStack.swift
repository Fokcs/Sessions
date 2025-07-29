import CoreData
import Foundation

/// Core Data stack for the Sessions therapy app
/// 
/// Provides centralized Core Data configuration with HIPAA compliance and cross-platform sync capabilities.
/// This implementation uses app groups for secure data sharing between iOS and watchOS targets.
/// 
/// **HIPAA Compliance Features:**
/// - File protection using `NSFileProtectionComplete` to encrypt data at rest
/// - App group container (`group.com.AAFU.Sessions`) for secure data isolation
/// - Proper merge policies to prevent data conflicts
/// 
/// **Sync Capabilities:**
/// - Persistent history tracking enabled for WatchConnectivity synchronization
/// - Remote change notifications for real-time updates across devices
/// - Background context support for non-blocking write operations
/// 
/// **Thread Safety:**
/// - Main view context for UI binding (read operations)
/// - Background contexts for write operations to prevent UI blocking
/// - Automatic merge policies to handle concurrent modifications
class CoreDataStack: ObservableObject {
    /// Shared singleton instance for app-wide Core Data access
    /// Using singleton pattern ensures consistent data store access across the app
    static let shared = CoreDataStack()
    
    /// Lazy-loaded persistent container with full HIPAA compliance configuration
    /// 
    /// **Configuration Details:**
    /// - Uses app group container for secure cross-app data sharing
    /// - Enables file protection at complete level (data encrypted when device locked)
    /// - Configures persistent history tracking for device sync
    /// - Sets up automatic merge policies for conflict resolution
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TherapyDataModel")
        
        // Use app group for shared data access between iOS and watchOS
        // This enables secure data sharing while maintaining HIPAA compliance
        guard let storeURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.AAFU.Sessions"
        )?.appendingPathComponent("TherapyData.sqlite") else {
            fatalError("Unable to create store URL for app group")
        }
        
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        
        // Enable file protection for HIPAA compliance
        // NSFileProtectionComplete ensures data is encrypted when device is locked
        storeDescription.setOption(FileProtectionType.complete as NSObject,
                                  forKey: NSPersistentStoreFileProtectionKey)
        
        // Enable persistent history tracking for WatchConnectivity sync
        // This allows tracking changes for cross-device synchronization
        storeDescription.setOption(true as NSNumber,
                                  forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber,
                                  forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.persistentStoreDescriptions = [storeDescription]
        
        // Load the persistent store with error handling
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load store: \(error.localizedDescription)")
            }
        }
        
        // Configure view context for optimal UI performance
        // Automatically merge changes from background contexts
        container.viewContext.automaticallyMergesChangesFromParent = true
        // Use property-level merge policy to handle conflicts intelligently
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    /// Main view context for UI binding and read operations
    /// 
    /// **Usage Guidelines:**
    /// - Use only for read operations and UI binding
    /// - Never perform heavy write operations on this context
    /// - All UI updates should happen on this context for thread safety
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    /// Creates a new background context for write operations
    /// 
    /// **Usage Guidelines:**
    /// - Use for all write operations to prevent UI blocking
    /// - Each write operation should use a fresh background context
    /// - Context is configured with same merge policy as view context
    /// 
    /// - Returns: Configured background context ready for write operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        // Ensure consistent merge policy across all contexts
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    /// Saves changes in the specified context with error handling
    /// 
    /// **Thread Safety:** This method can be called from any thread as long as
    /// the context parameter matches the calling thread's context
    /// 
    /// - Parameter context: The context to save. Defaults to viewContext if nil
    /// - Note: Only saves if there are actual changes to prevent unnecessary I/O
    func save(context: NSManagedObjectContext? = nil) {
        let contextToSave = context ?? persistentContainer.viewContext
        
        // Only save if there are actual changes
        guard contextToSave.hasChanges else { return }
        
        do {
            try contextToSave.save()
        } catch {
            // TODO: Implement proper error handling/logging for production
            // Consider using structured logging for HIPAA audit trails
            print("Core Data save error: \(error.localizedDescription)")
        }
    }
    
    /// Legacy method for saving the main view context
    /// 
    /// **Deprecated:** Use `save(context:)` method instead for more explicit context handling
    /// Maintained for backward compatibility with existing code
    func saveContext() {
        save()
    }
}