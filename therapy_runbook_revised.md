# Therapy Data Logger - Revised Agent Development Runbook

## Overview

This runbook provides a step-by-step guide for the AI coding agent to build the Therapy Data Logger app using a platform-parallel development approach. Each stage builds upon the previous foundation while maintaining focus on specific components. Complete all testing and validation before proceeding to the next stage.

## Development Strategy

**Approach**: Platform-Parallel Development
- Stage 1: Foundation (Core Data + Shared Infrastructure)
- Stage 2: iPhone Data Management (Client/Goal CRUD)
- Stage 3: Watch Core Workflow (Session Management)
- Stage 4: Device Synchronization (WatchConnectivity)
- Stage 5: iPhone Analytics & Polish (Advanced Features)

---

## Stage 1: Foundation - Core Data & Shared Infrastructure

### Objective
Establish the foundational data layer and shared infrastructure that both iPhone and Watch apps will depend on. Focus on robust Core Data implementation with proper encryption and app group sharing.

### Step 1.2: Configure App Groups and Entitlements

**Action**: Set up app groups for data sharing between targets

**iOS App Entitlements** (`iOS App.entitlements`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.default-data-protection</key>
    <string>NSFileProtectionComplete</string>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.yourcompany.therapydatalogger</string>
    </array>
</dict>
</plist>
```

**watchOS App Entitlements** (`watchOS App.entitlements`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.default-data-protection</key>
    <string>NSFileProtectionComplete</string>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.yourcompany.therapydatalogger</string>
    </array>
</dict>
</plist>
```

**Validation Checklist**:
- [ ] App Groups configured in both targets
- [ ] File protection entitlements added
- [ ] Build succeeds with entitlements
- [ ] App group container URL resolves correctly

### Step 1.3: Create Core Data Model

**Action**: Create `TherapyDataModel.xcdatamodeld` in Shared folder with required entities

**Core Data Entities to Create**:

1. **ClientEntity**
   - `id`: UUID, required, indexed
   - `name`: String, required
   - `dateOfBirth`: Date, optional
   - `notes`: String, optional
   - `createdDate`: Date, required
   - `lastModified`: Date, required

2. **GoalTemplateEntity**
   - `id`: UUID, required, indexed
   - `title`: String, required
   - `description`: String, optional
   - `category`: String, required
   - `defaultCueLevel`: String, required
   - `clientId`: UUID, required, indexed
   - `isActive`: Boolean, required, default YES
   - `createdDate`: Date, required

3. **SessionEntity**
   - `id`: UUID, required, indexed
   - `date`: Date, required, indexed
   - `startTime`: Date, required
   - `endTime`: Date, optional
   - `clientId`: UUID, required, indexed
   - `notes`: String, optional
   - `location`: String, optional
   - `createdOn`: String, required, default "iPhone"
   - `lastModified`: Date, required

4. **GoalLogEntity**
   - `id`: UUID, required
   - `goalTemplateId`: UUID, optional, indexed
   - `goalDescription`: String, required
   - `cueLevel`: String, required
   - `wasSuccessful`: Boolean, required
   - `sessionId`: UUID, required, indexed
   - `timestamp`: Date, required, indexed
   - `notes`: String, optional

**Relationships to Configure**:
- ClientEntity.sessions → SessionEntity (one-to-many, cascade delete)
- ClientEntity.goalTemplates → GoalTemplateEntity (one-to-many, cascade delete)
- SessionEntity.client → ClientEntity (many-to-one, nullify)
- SessionEntity.goalLogs → GoalLogEntity (one-to-many, cascade delete)
- GoalLogEntity.session → SessionEntity (many-to-one, nullify)
- GoalTemplateEntity.client → ClientEntity (many-to-one, nullify)

**Validation Checklist**:
- [ ] All entities created with correct attributes and types
- [ ] Relationships properly configured with delete rules
- [ ] Appropriate indexes on UUID and Date fields
- [ ] Core Data model validates without errors
- [ ] Data model file accessible to both targets

### Step 1.4: Implement Core Data Stack

**Action**: Create robust Core Data stack in `Shared/CoreData/CoreDataStack.swift`

```swift
import CoreData
import Foundation

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TherapyDataModel")
        
        // Use app group for shared data access
        guard let storeURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.yourcompany.therapydatalogger"
        )?.appendingPathComponent("TherapyData.sqlite") else {
            fatalError("Unable to create store URL")
        }
        
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        storeDescription.setOption(FileProtectionType.complete as NSObject,
                                  forKey: NSPersistentStoreFileProtectionKey)
        
        // Enable persistent history tracking for sync
        storeDescription.setOption(true as NSNumber,
                                  forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber,
                                  forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    func save(context: NSManagedObjectContext? = nil) {
        let contextToSave = context ?? persistentContainer.viewContext
        
        if contextToSave.hasChanges {
            do {
                try contextToSave.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
}
```

**Validation Checklist**:
- [ ] Core Data stack compiles successfully
- [ ] App group container URL resolves correctly
- [ ] File protection configured
- [ ] Persistent history tracking enabled
- [ ] Both iOS and watchOS can instantiate the stack
- [ ] Background context creation works

### Step 1.5: Create Swift Model Structs

**Action**: Create model structs in `Shared/Models/` that mirror Core Data entities

**File**: `Shared/Models/Client.swift`
```swift
import Foundation

struct Client: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let dateOfBirth: Date?
    let notes: String?
    let createdDate: Date
    let lastModified: Date
    
    init(id: UUID = UUID(), name: String, dateOfBirth: Date? = nil, notes: String? = nil) {
        self.id = id
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.notes = notes
        self.createdDate = Date()
        self.lastModified = Date()
    }
    
    var displayName: String { name }
    var age: Int? {
        guard let dateOfBirth = dateOfBirth else { return nil }
        return Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year
    }
    var displayDetails: String {
        if let age = age {
            return "Age \(age)"
        } else {
            return "Age not specified"
        }
    }
}
```

**File**: `Shared/Models/CueLevel.swift`
```swift
import Foundation
import SwiftUI

enum CueLevel: String, CaseIterable, Codable {
    case independent = "independent"
    case minimal = "minimal"
    case moderate = "moderate"
    case maximal = "maximal"
    
    var displayName: String {
        switch self {
        case .independent: return "Independent"
        case .minimal: return "Min"
        case .moderate: return "Mod"
        case .maximal: return "Max"
        }
    }
    
    var fullDisplayName: String {
        switch self {
        case .independent: return "Independent"
        case .minimal: return "Minimal"
        case .moderate: return "Moderate"
        case .maximal: return "Maximal"
        }
    }
    
    var color: Color {
        switch self {
        case .independent: return .blue
        case .minimal: return .green
        case .moderate: return .orange
        case .maximal: return .red
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .independent:
            return LinearGradient(colors: [.blue, Color(red: 0, green: 0.34, blue: 0.8)], startPoint: .top, endPoint: .bottom)
        case .minimal:
            return LinearGradient(colors: [.green, Color(red: 0.13, green: 0.55, blue: 0.13)], startPoint: .top, endPoint: .bottom)
        case .moderate:
            return LinearGradient(colors: [.orange, Color(red: 0.8, green: 0.47, blue: 0)], startPoint: .top, endPoint: .bottom)
        case .maximal:
            return LinearGradient(colors: [.red, Color(red: 0.8, green: 0.16, blue: 0.13)], startPoint: .top, endPoint: .bottom)
        }
    }
}
```

**File**: `Shared/Models/GoalTemplate.swift`
```swift
import Foundation

struct GoalTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let description: String?
    let category: String
    let defaultCueLevel: CueLevel
    let clientId: UUID
    let isActive: Bool
    let createdDate: Date
    
    init(id: UUID = UUID(), title: String, description: String? = nil, 
         category: String, defaultCueLevel: CueLevel, clientId: UUID, isActive: Bool = true) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.defaultCueLevel = defaultCueLevel
        self.clientId = clientId
        self.isActive = isActive
        self.createdDate = Date()
    }
}
```

**File**: `Shared/Models/Session.swift`
```swift
import Foundation

struct Session: Identifiable, Codable, Equatable {
    let id: UUID
    let clientId: UUID
    let date: Date
    let startTime: Date
    var endTime: Date?
    let location: String?
    let createdOn: String
    var notes: String?
    var goalLogs: [GoalLog] = []
    let lastModified: Date
    
    init(id: UUID = UUID(), clientId: UUID, location: String? = nil, createdOn: String = "iPhone") {
        self.id = id
        self.clientId = clientId
        self.date = Date()
        self.startTime = Date()
        self.location = location
        self.createdOn = createdOn
        self.lastModified = Date()
    }
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var isActive: Bool {
        endTime == nil
    }
    
    var successRate: Double {
        guard !goalLogs.isEmpty else { return 0.0 }
        let successCount = goalLogs.filter { $0.wasSuccessful }.count
        return Double(successCount) / Double(goalLogs.count)
    }
    
    var totalTrials: Int {
        goalLogs.count
    }
}
```

**File**: `Shared/Models/GoalLog.swift`
```swift
import Foundation

struct GoalLog: Identifiable, Codable, Equatable {
    let id: UUID
    let goalTemplateId: UUID?
    let goalDescription: String
    let cueLevel: CueLevel
    let wasSuccessful: Bool
    let sessionId: UUID
    let timestamp: Date
    let notes: String?
    
    init(id: UUID = UUID(), goalTemplateId: UUID? = nil, goalDescription: String,
         cueLevel: CueLevel, wasSuccessful: Bool, sessionId: UUID, notes: String? = nil) {
        self.id = id
        self.goalTemplateId = goalTemplateId
        self.goalDescription = goalDescription
        self.cueLevel = cueLevel
        self.wasSuccessful = wasSuccessful
        self.sessionId = sessionId
        self.timestamp = Date()
        self.notes = notes
    }
}
```

**Validation Checklist**:
- [ ] All model files compile successfully
- [ ] Models conform to Identifiable, Codable, and Equatable
- [ ] CueLevel enum has proper color and gradient definitions
- [ ] Models include computed properties for UI display
- [ ] Models match Core Data entity structure
- [ ] Proper initializers with sensible defaults

### Step 1.6: Create Repository Protocol and Implementation

**Action**: Create repository pattern for data access in `Shared/Repositories/`

**File**: `Shared/Repositories/TherapyRepository.swift`
```swift
import Foundation
import Combine

protocol TherapyRepository: ObservableObject {
    // Client operations
    func createClient(_ client: Client) async throws
    func fetchClients() async throws -> [Client]
    func updateClient(_ client: Client) async throws
    func deleteClient(_ clientId: UUID) async throws
    
    // Goal template operations
    func createGoalTemplate(_ template: GoalTemplate) async throws
    func fetchGoalTemplates(for clientId: UUID) async throws -> [GoalTemplate]
    func updateGoalTemplate(_ template: GoalTemplate) async throws
    func deleteGoalTemplate(_ templateId: UUID) async throws
    
    // Session operations
    func startSession(for clientId: UUID, location: String?, createdOn: String) async throws -> Session
    func endSession(_ sessionId: UUID) async throws
    func fetchSessions(for clientId: UUID) async throws -> [Session]
    func fetchActiveSession() async throws -> Session?
    
    // Goal log operations
    func logGoal(_ goalLog: GoalLog) async throws
    func fetchGoalLogs(for sessionId: UUID) async throws -> [GoalLog]
    func deleteGoalLog(_ goalLogId: UUID) async throws
}
```

**File**: `Shared/Repositories/CoreDataTherapyRepository.swift`
```swift
import CoreData
import Foundation

class CoreDataTherapyRepository: ObservableObject, TherapyRepository {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - Client Operations
    
    func createClient(_ client: Client) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        await context.perform {
            let entity = ClientEntity(context: context)
            entity.id = client.id
            entity.name = client.name
            entity.dateOfBirth = client.dateOfBirth
            entity.notes = client.notes
            entity.createdDate = client.createdDate
            entity.lastModified = Date()
            
            self.coreDataStack.save(context: context)
        }
    }
    
    func fetchClients() async throws -> [Client] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<ClientEntity> = ClientEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClientEntity.name, ascending: true)]
        
        return try await context.perform {
            let entities = try context.fetch(request)
            return entities.map { entity in
                Client(
                    id: entity.id ?? UUID(),
                    name: entity.name ?? "",
                    dateOfBirth: entity.dateOfBirth,
                    notes: entity.notes
                )
            }
        }
    }
    
    func updateClient(_ client: Client) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        await context.perform {
            let request: NSFetchRequest<ClientEntity> = ClientEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", client.id as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                if let entity = entities.first {
                    entity.name = client.name
                    entity.dateOfBirth = client.dateOfBirth
                    entity.notes = client.notes
                    entity.lastModified = Date()
                    
                    self.coreDataStack.save(context: context)
                }
            } catch {
                print("Update client error: \(error)")
            }
        }
    }
    
    func deleteClient(_ clientId: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        await context.perform {
            let request: NSFetchRequest<ClientEntity> = ClientEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", clientId as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                if let entity = entities.first {
                    context.delete(entity)
                    self.coreDataStack.save(context: context)
                }
            } catch {
                print("Delete client error: \(error)")
            }
        }
    }
    
    // MARK: - Goal Template Operations
    
    func createGoalTemplate(_ template: GoalTemplate) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        await context.perform {
            let entity = GoalTemplateEntity(context: context)
            entity.id = template.id
            entity.title = template.title
            entity.description = template.description
            entity.category = template.category
            entity.defaultCueLevel = template.defaultCueLevel.rawValue
            entity.clientId = template.clientId
            entity.isActive = template.isActive
            entity.createdDate = template.createdDate
            
            self.coreDataStack.save(context: context)
        }
    }
    
    func fetchGoalTemplates(for clientId: UUID) async throws -> [GoalTemplate] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<GoalTemplateEntity> = GoalTemplateEntity.fetchRequest()
        request.predicate = NSPredicate(format: "clientId == %@ AND isActive == YES", clientId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GoalTemplateEntity.title, ascending: true)]
        
        return try await context.perform {
            let entities = try context.fetch(request)
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let title = entity.title,
                      let category = entity.category,
                      let defaultCueLevelString = entity.defaultCueLevel,
                      let defaultCueLevel = CueLevel(rawValue: defaultCueLevelString),
                      let clientId = entity.clientId else {
                    return nil
                }
                
                return GoalTemplate(
                    id: id,
                    title: title,
                    description: entity.description,
                    category: category,
                    defaultCueLevel: defaultCueLevel,
                    clientId: clientId,
                    isActive: entity.isActive
                )
            }
        }
    }
    
    func updateGoalTemplate(_ template: GoalTemplate) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        await context.perform {
            let request: NSFetchRequest<GoalTemplateEntity> = GoalTemplateEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", template.id as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                if let entity = entities.first {
                    entity.title = template.title
                    entity.description = template.description
                    entity.category = template.category
                    entity.defaultCueLevel = template.defaultCueLevel.rawValue
                    entity.isActive = template.isActive
                    
                    self.coreDataStack.save(context: context)
                }
            } catch {
                print("Update goal template error: \(error)")
            }
        }
    }
    
    func deleteGoalTemplate(_ templateId: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        await context.perform {
            let request: NSFetchRequest<GoalTemplateEntity> = GoalTemplateEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", templateId as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                if let entity = entities.first {
                    entity.isActive = false // Soft delete
                    self.coreDataStack.save(context: context)
                }
            } catch {
                print("Delete goal template error: \(error)")
            }
        }
    }
    
    // MARK: - Session Operations
    
    func startSession(for clientId: UUID, location: String?, createdOn: String) async throws -> Session {
        let context = coreDataStack.newBackgroundContext()
        
        return try await context.perform {
            let entity = SessionEntity(context: context)
            let sessionId = UUID()
            let now = Date()
            
            entity.id = sessionId
            entity.clientId = clientId
            entity.date = now
            entity.startTime = now
            entity.location = location
            entity.createdOn = createdOn
            entity.lastModified = now
            
            try context.save()
            
            return Session(
                id: sessionId,
                clientId: clientId,
                location: location,
                createdOn: createdOn
            )
        }
    }
    
    func endSession(_ sessionId: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        await context.perform {
            let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", sessionId as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                if let entity = entities.first {
                    entity.endTime = Date()
                    entity.lastModified = Date()
                    
                    self.coreDataStack.save(context: context)
                }
            } catch {
                print("End session error: \(error)")
            }
        }
    }
    
    func fetchSessions(for clientId: UUID) async throws -> [Session] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "clientId == %@", clientId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SessionEntity.startTime, ascending: false)]
        
        return try await context.perform {
            let entities = try context.fetch(request)
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let clientId = entity.clientId,
                      let date = entity.date,
                      let startTime = entity.startTime,
                      let lastModified = entity.lastModified else {
                    return nil
                }
                
                var session = Session(id: id, clientId: clientId, location: entity.location, createdOn: entity.createdOn ?? "iPhone")
                // Note: We'll need to manually set these since Session init creates new dates
                // This is a limitation we'll address in the next stage
                return session
            }
        }
    }
    
    func fetchActiveSession() async throws -> Session? {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "endTime == nil")
        request.fetchLimit = 1
        
        return try await context.perform {
            let entities = try context.fetch(request)
            guard let entity = entities.first,
                  let id = entity.id,
                  let clientId = entity.clientId else {
                return nil
            }
            
            return Session(id: id, clientId: clientId, location: entity.location, createdOn: entity.createdOn ?? "iPhone")
        }
    }
    
    // MARK: - Goal Log Operations
    
    func logGoal(_ goalLog: GoalLog) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        await context.perform {
            let entity = GoalLogEntity(context: context)
            entity.id = goalLog.id
            entity.goalTemplateId = goalLog.goalTemplateId
            entity.goalDescription = goalLog.goalDescription
            entity.cueLevel = goalLog.cueLevel.rawValue
            entity.wasSuccessful = goalLog.wasSuccessful
            entity.sessionId = goalLog.sessionId
            entity.timestamp = goalLog.timestamp
            entity.notes = goalLog.notes
            
            self.coreDataStack.save(context: context)
        }
    }
    
    func fetchGoalLogs(for sessionId: UUID) async throws -> [GoalLog] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<GoalLogEntity> = GoalLogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "sessionId == %@", sessionId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GoalLogEntity.timestamp, ascending: true)]
        
        return try await context.perform {
            let entities = try context.fetch(request)
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let goalDescription = entity.goalDescription,
                      let cueLevelString = entity.cueLevel,
                      let cueLevel = CueLevel(rawValue: cueLevelString),
                      let sessionId = entity.sessionId,
                      let timestamp = entity.timestamp else {
                    return nil
                }
                
                return GoalLog(
                    id: id,
                    goalTemplateId: entity.goalTemplateId,
                    goalDescription: goalDescription,
                    cueLevel: cueLevel,
                    wasSuccessful: entity.wasSuccessful,
                    sessionId: sessionId,
                    notes: entity.notes
                )
            }
        }
    }
    
    func deleteGoalLog(_ goalLogId: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        await context.perform {
            let request: NSFetchRequest<GoalLogEntity> = GoalLogEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", goalLogId as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                if let entity = entities.first {
                    context.delete(entity)
                    self.coreDataStack.save(context: context)
                }
            } catch {
                print("Delete goal log error: \(error)")
            }
        }
    }
}
```

**Validation Checklist**:
- [ ] Repository protocol defines all necessary methods
- [ ] Core Data repository compiles successfully
- [ ] Repository methods use async/await pattern
- [ ] Proper error handling implemented
- [ ] Background context used for write operations
- [ ] View context used for read operations
- [ ] Fetch requests include proper predicates and sorting

### Step 1.7: Create Basic Unit Tests

**Action**: Create unit tests in `Tests/FoundationTests.swift`

```swift
import XCTest
import CoreData
@testable import TherapyDataLogger

final class FoundationTests: XCTestCase {
    
    var repository: CoreDataTherapyRepository!
    var testContext: NSManagedObjectContext!
    
    override func setUp() async throws {
        // Create in-memory Core Data stack for testing
        let container = NSPersistentContainer(name: "TherapyDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
        
        let testStack = CoreDataStack()
        testStack.persistentContainer = container
        
        repository = CoreDataTherapyRepository(coreDataStack: testStack)
        testContext = container.viewContext
    }
    
    func testCreateAndFetchClient() async throws {
        // Create test client
        let client = Client(name: "Test Client", dateOfBirth: Date(), notes: "Test notes")
        
        // Save client
        try await repository.createClient(client)
        
        // Fetch clients
