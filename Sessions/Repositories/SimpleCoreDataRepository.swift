import CoreData
import Foundation
import Combine

/// Core Data implementation of TherapyRepository protocol
/// 
/// **Architecture Pattern:**
/// This class implements the Repository pattern, providing a clean abstraction layer
/// between the domain models (Swift structs) and Core Data persistence layer.
/// It handles all database operations while maintaining separation of concerns.
/// 
/// **Design Decisions:**
/// - Uses background contexts for all write operations to prevent UI blocking
/// - Implements proper async/await patterns for non-blocking database access
/// - Follows the SimpleCoreDataRepository approach from CLAUDE.md guidelines
/// - Avoids complex context.perform return patterns that caused Stage 1 issues
/// 
/// **HIPAA Compliance:**
/// - All data operations go through the secure CoreDataStack configuration
/// - Uses app group containers with NSFileProtectionComplete encryption
/// - Implements soft deletes for goal templates to preserve audit trails
/// 
/// **Thread Safety:**
/// - Write operations use newBackgroundContext() for thread isolation
/// - Read operations use viewContext for UI binding compatibility
/// - No managed objects passed between contexts to prevent threading issues
class SimpleCoreDataRepository: ObservableObject, TherapyRepository {
    /// Shared singleton instance for app-wide repository access
    /// Using singleton pattern ensures consistent data access across ViewModels
    static let shared = SimpleCoreDataRepository()
    
    /// Reference to the shared Core Data stack
    /// Provides access to persistent container and context management
    private let coreDataStack: CoreDataStack
    
    /// Initializes repository with Core Data stack dependency
    /// 
    /// - Parameter coreDataStack: Core Data stack instance (defaults to shared singleton)
    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - Client Operations
    
    /// Creates a new client record in Core Data
    /// 
    /// **Thread Safety:** Uses background context to prevent UI blocking
    /// **Error Handling:** Properly propagates TherapyAppError for UI presentation
    /// 
    /// - Parameter client: Client model to persist
    /// - Throws: TherapyAppError for save failures or validation errors
    func createClient(_ client: Client) async throws {
        // Validate required fields before attempting save
        guard !client.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TherapyAppError.clientNameRequired
        }
        
        let context = coreDataStack.newBackgroundContext()
        var saveError: Error?
        
        await context.perform {
            // Create new Core Data entity and map from Swift model
            let entity = ClientEntity(context: context)
            entity.id = client.id
            entity.name = client.name
            entity.dateOfBirth = client.dateOfBirth
            entity.notes = client.notes
            entity.createdDate = client.createdDate
            entity.lastModified = Date()  // Update modification timestamp
            
            do {
                try context.save()
            } catch {
                saveError = error
            }
        }
        
        // Propagate error if save failed
        if let error = saveError {
            throw TherapyAppError.coreDataError(error as NSError)
        }
    }
    
    /// Retrieves all clients sorted by name
    /// 
    /// **Thread Safety:** Uses viewContext for UI-compatible read operations
    /// **Data Mapping:** Converts Core Data entities to Swift model structs
    /// 
    /// - Returns: Array of Client models sorted alphabetically by name
    /// - Throws: TherapyAppError for fetch failures
    func fetchClients() async throws -> [Client] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<ClientEntity> = ClientEntity.fetchRequest()
        // Sort clients alphabetically for consistent UI presentation
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClientEntity.name, ascending: true)]
        
        do {
            let entities = try context.fetch(request)
            // Convert Core Data entities to Swift models, filtering out invalid records
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let name = entity.name,
                      let createdDate = entity.createdDate,
                      let lastModified = entity.lastModified else {
                    return nil
                }
                
                return Client(
                    id: id,
                    name: name,
                    dateOfBirth: entity.dateOfBirth,
                    notes: entity.notes,
                    createdDate: createdDate,
                    lastModified: lastModified
                )
            }
        } catch {
            throw TherapyAppError.fetchFailure(error as NSError)
        }
    }
    
    func updateClient(_ client: Client) async throws {
        // Validate required fields before attempting update
        guard !client.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TherapyAppError.clientNameRequired
        }
        
        let context = coreDataStack.newBackgroundContext()
        var operationError: Error?
        
        await context.perform {
            let request: NSFetchRequest<ClientEntity> = ClientEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", client.id as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                guard let entity = entities.first else {
                    operationError = TherapyAppError.clientNotFound(clientId: client.id.uuidString)
                    return
                }
                
                entity.name = client.name
                entity.dateOfBirth = client.dateOfBirth
                entity.notes = client.notes
                entity.lastModified = Date()
                
                try context.save()
            } catch {
                operationError = error
            }
        }
        
        // Propagate error if operation failed
        if let error = operationError {
            if error is TherapyAppError {
                throw error
            } else {
                throw TherapyAppError.coreDataError(error as NSError)
            }
        }
    }
    
    func deleteClient(_ clientId: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()
        var operationError: Error?
        
        await context.perform {
            let request: NSFetchRequest<ClientEntity> = ClientEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", clientId as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                guard let entity = entities.first else {
                    operationError = TherapyAppError.clientNotFound(clientId: clientId.uuidString)
                    return
                }
                
                // Check if client has sessions before allowing deletion
                let sessionRequest: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
                sessionRequest.predicate = NSPredicate(format: "clientId == %@", clientId as CVarArg)
                sessionRequest.fetchLimit = 1
                
                let sessionCount = try context.count(for: sessionRequest)
                if sessionCount > 0 {
                    operationError = TherapyAppError.clientHasSessions
                    return
                }
                
                context.delete(entity)
                try context.save()
            } catch {
                operationError = error
            }
        }
        
        // Propagate error if operation failed
        if let error = operationError {
            if error is TherapyAppError {
                throw error
            } else {
                throw TherapyAppError.coreDataError(error as NSError)
            }
        }
    }
    
    func fetchClient(_ clientId: UUID) async throws -> Client? {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<ClientEntity> = ClientEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", clientId as CVarArg)
        request.fetchLimit = 1
        
        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first,
                  let id = entity.id,
                  let name = entity.name,
                  let createdDate = entity.createdDate,
                  let lastModified = entity.lastModified else {
                return nil
            }
            
            return Client(
                id: id,
                name: name,
                dateOfBirth: entity.dateOfBirth,
                notes: entity.notes,
                createdDate: createdDate,
                lastModified: lastModified
            )
        } catch {
            throw TherapyAppError.fetchFailure(error as NSError)
        }
    }
    
    // MARK: - Goal Template Operations
    
    func createGoalTemplate(_ template: GoalTemplate) async throws {
        // Validate required fields before attempting save
        guard !template.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TherapyAppError.goalTitleRequired
        }
        
        let context = coreDataStack.newBackgroundContext()
        var saveError: Error?
        
        await context.perform {
            let entity = GoalTemplateEntity(context: context)
            entity.id = template.id
            entity.title = template.title
            entity.goalDescription = template.description
            entity.category = template.category
            entity.defaultCueLevel = template.defaultCueLevel.rawValue
            entity.clientId = template.clientId
            entity.isActive = template.isActive
            entity.createdDate = template.createdDate
            
            do {
                try context.save()
            } catch {
                saveError = error
            }
        }
        
        // Propagate error if save failed
        if let error = saveError {
            throw TherapyAppError.coreDataError(error as NSError)
        }
    }
    
    func fetchGoalTemplates(for clientId: UUID) async throws -> [GoalTemplate] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<GoalTemplateEntity> = GoalTemplateEntity.fetchRequest()
        request.predicate = NSPredicate(format: "clientId == %@ AND isActive == YES", clientId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GoalTemplateEntity.title, ascending: true)]
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let title = entity.title,
                      let category = entity.category,
                      let defaultCueLevelString = entity.defaultCueLevel,
                      let defaultCueLevel = CueLevel(rawValue: defaultCueLevelString),
                      let clientId = entity.clientId,
                      let createdDate = entity.createdDate else {
                    return nil
                }
                
                return GoalTemplate(
                    id: id,
                    title: title,
                    description: entity.goalDescription,
                    category: category,
                    defaultCueLevel: defaultCueLevel,
                    clientId: clientId,
                    isActive: entity.isActive,
                    createdDate: createdDate
                )
            }
        } catch {
            throw TherapyAppError.fetchFailure(error as NSError)
        }
    }
    
    func updateGoalTemplate(_ template: GoalTemplate) async throws {
        // Validate required fields before attempting update
        guard !template.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TherapyAppError.goalTitleRequired
        }
        
        let context = coreDataStack.newBackgroundContext()
        var operationError: Error?
        
        await context.perform {
            let request: NSFetchRequest<GoalTemplateEntity> = GoalTemplateEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", template.id as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                guard let entity = entities.first else {
                    operationError = TherapyAppError.goalTemplateNotFound(templateId: template.id.uuidString)
                    return
                }
                
                entity.title = template.title
                entity.goalDescription = template.description
                entity.category = template.category
                entity.defaultCueLevel = template.defaultCueLevel.rawValue
                entity.isActive = template.isActive
                
                try context.save()
            } catch {
                operationError = error
            }
        }
        
        // Propagate error if operation failed
        if let error = operationError {
            if error is TherapyAppError {
                throw error
            } else {
                throw TherapyAppError.coreDataError(error as NSError)
            }
        }
    }
    
    /// Soft deletes a goal template by setting isActive to false
    /// 
    /// **Design Decision:** Uses soft delete instead of hard delete to preserve
    /// historical data integrity and maintain references from existing goal logs.
    /// This is important for HIPAA compliance and audit trail requirements.
    /// 
    /// - Parameter templateId: UUID of template to deactivate
    /// - Throws: TherapyAppError for operation failures or not found scenarios
    func deleteGoalTemplate(_ templateId: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()
        var operationError: Error?
        
        await context.perform {
            let request: NSFetchRequest<GoalTemplateEntity> = GoalTemplateEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", templateId as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                guard let entity = entities.first else {
                    operationError = TherapyAppError.goalTemplateNotFound(templateId: templateId.uuidString)
                    return
                }
                
                // Soft delete - preserves data integrity for historical references
                entity.isActive = false
                try context.save()
            } catch {
                operationError = error
            }
        }
        
        // Propagate error if operation failed
        if let error = operationError {
            if error is TherapyAppError {
                throw error
            } else {
                throw TherapyAppError.coreDataError(error as NSError)
            }
        }
    }
    
    func fetchGoalTemplate(_ templateId: UUID) async throws -> GoalTemplate? {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<GoalTemplateEntity> = GoalTemplateEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", templateId as CVarArg)
        request.fetchLimit = 1
        
        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first,
                  let id = entity.id,
                  let title = entity.title,
                  let category = entity.category,
                  let defaultCueLevelString = entity.defaultCueLevel,
                  let defaultCueLevel = CueLevel(rawValue: defaultCueLevelString),
                  let clientId = entity.clientId,
                  let createdDate = entity.createdDate else {
                return nil
            }
            
            return GoalTemplate(
                id: id,
                title: title,
                description: entity.goalDescription,
                category: category,
                defaultCueLevel: defaultCueLevel,
                clientId: clientId,
                isActive: entity.isActive,
                createdDate: createdDate
            )
        } catch {
            throw TherapyAppError.fetchFailure(error as NSError)
        }
    }
    
    func fetchAllGoalTemplates() async throws -> [GoalTemplate] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<GoalTemplateEntity> = GoalTemplateEntity.fetchRequest()
        // No predicate - fetch all goal templates (active and inactive)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \GoalTemplateEntity.isActive, ascending: false), // Active first
            NSSortDescriptor(keyPath: \GoalTemplateEntity.title, ascending: true)
        ]
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let title = entity.title,
                      let category = entity.category,
                      let defaultCueLevelString = entity.defaultCueLevel,
                      let defaultCueLevel = CueLevel(rawValue: defaultCueLevelString),
                      let clientId = entity.clientId,
                      let createdDate = entity.createdDate else {
                    return nil
                }
                
                return GoalTemplate(
                    id: id,
                    title: title,
                    description: entity.goalDescription,
                    category: category,
                    defaultCueLevel: defaultCueLevel,
                    clientId: clientId,
                    isActive: entity.isActive,
                    createdDate: createdDate
                )
            }
        } catch {
            throw TherapyAppError.fetchFailure(error as NSError)
        }
    }
    
    // MARK: - Session Operations
    
    /// Creates and starts a new therapy session
    /// 
    /// **Session Lifecycle:** Creates active session with no end time
    /// **Return Value:** Returns Swift model immediately after Core Data save
    /// 
    /// - Parameters:
    ///   - clientId: Associated client identifier
    ///   - location: Optional session location
    ///   - createdOn: Device/platform identifier
    /// - Returns: Newly created Session model
    /// - Throws: TherapyAppError for validation, business logic, or save failures
    func startSession(for clientId: UUID, location: String?, createdOn: String) async throws -> Session {
        // Check if there's already an active session
        let activeSession = try await fetchActiveSession()
        if activeSession != nil {
            throw TherapyAppError.sessionAlreadyActive
        }
        
        // Verify client exists
        let client = try await fetchClient(clientId)
        if client == nil {
            throw TherapyAppError.clientNotFound(clientId: clientId.uuidString)
        }
        
        let sessionId = UUID()
        let now = Date()
        let context = coreDataStack.newBackgroundContext()
        var saveError: Error?
        
        await context.perform {
            // Create active session entity (endTime remains nil)
            let entity = SessionEntity(context: context)
            entity.id = sessionId
            entity.clientId = clientId
            entity.date = now
            entity.startTime = now
            entity.location = location
            entity.createdOn = createdOn
            entity.lastModified = now
            // Note: endTime intentionally left nil to indicate active session
            
            do {
                try context.save()
            } catch {
                saveError = error
            }
        }
        
        // Propagate error if save failed
        if let error = saveError {
            throw TherapyAppError.coreDataError(error as NSError)
        }
        
        return Session(
            id: sessionId,
            clientId: clientId,
            date: now,
            startTime: now,
            endTime: nil,
            location: location,
            createdOn: createdOn,
            notes: nil,
            goalLogs: [],
            lastModified: now
        )
    }
    
    func endSession(_ sessionId: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()
        var operationError: Error?
        
        await context.perform {
            let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", sessionId as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                guard let entity = entities.first else {
                    operationError = TherapyAppError.sessionNotFound(sessionId: sessionId.uuidString)
                    return
                }
                
                // Verify session is still active (not already ended)
                if entity.endTime != nil {
                    operationError = TherapyAppError.validation(field: "Session", reason: "Session has already been ended")
                    return
                }
                
                entity.endTime = Date()
                entity.lastModified = Date()
                
                try context.save()
            } catch {
                operationError = error
            }
        }
        
        // Propagate error if operation failed
        if let error = operationError {
            if error is TherapyAppError {
                throw error
            } else {
                throw TherapyAppError.coreDataError(error as NSError)
            }
        }
    }
    
    func fetchSessions(for clientId: UUID) async throws -> [Session] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "clientId == %@", clientId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SessionEntity.startTime, ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { entity in
                guard let id = entity.id,
                      let clientId = entity.clientId,
                      let date = entity.date,
                      let startTime = entity.startTime,
                      let lastModified = entity.lastModified,
                      let createdOn = entity.createdOn else {
                    return nil
                }
                
                return Session(
                    id: id,
                    clientId: clientId,
                    date: date,
                    startTime: startTime,
                    endTime: entity.endTime,
                    location: entity.location,
                    createdOn: createdOn,
                    notes: entity.notes,
                    goalLogs: [],
                    lastModified: lastModified
                )
            }
        } catch {
            throw TherapyAppError.fetchFailure(error as NSError)
        }
    }
    
    /// Retrieves the currently active session (if any)
    /// 
    /// **Business Logic:** Only one session should be active at a time
    /// **Query:** Finds sessions where endTime is nil
    /// 
    /// - Returns: Active Session model or nil if no active session exists
    /// - Throws: TherapyAppError for fetch failures
    func fetchActiveSession() async throws -> Session? {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        // Find sessions without end time (active sessions)
        request.predicate = NSPredicate(format: "endTime == nil")
        request.fetchLimit = 1  // Should only be one active session
        
        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first,
                  let id = entity.id,
                  let clientId = entity.clientId,
                  let date = entity.date,
                  let startTime = entity.startTime,
                  let lastModified = entity.lastModified,
                  let createdOn = entity.createdOn else {
                return nil
            }
            
            return Session(
                id: id,
                clientId: clientId,
                date: date,
                startTime: startTime,
                endTime: entity.endTime,
                location: entity.location,
                createdOn: createdOn,
                notes: entity.notes,
                goalLogs: [],
                lastModified: lastModified
            )
        } catch {
            throw TherapyAppError.fetchFailure(error as NSError)
        }
    }
    
    func fetchSession(_ sessionId: UUID) async throws -> Session? {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", sessionId as CVarArg)
        request.fetchLimit = 1
        
        do {
            let entities = try context.fetch(request)
            guard let entity = entities.first,
                  let id = entity.id,
                  let clientId = entity.clientId,
                  let date = entity.date,
                  let startTime = entity.startTime,
                  let lastModified = entity.lastModified,
                  let createdOn = entity.createdOn else {
                return nil
            }
            
            // Fetch goal logs for this session
            let goalLogs = try await fetchGoalLogs(for: sessionId)
            
            return Session(
                id: id,
                clientId: clientId,
                date: date,
                startTime: startTime,
                endTime: entity.endTime,
                location: entity.location,
                createdOn: createdOn,
                notes: entity.notes,
                goalLogs: goalLogs,
                lastModified: lastModified
            )
        } catch {
            // Check if it's already a TherapyAppError from fetchGoalLogs
            if error is TherapyAppError {
                throw error
            } else {
                throw TherapyAppError.fetchFailure(error as NSError)
            }
        }
    }
    
    // MARK: - Goal Log Operations
    
    /// Records a goal attempt/trial within a therapy session
    /// 
    /// **Core Functionality:** This is the primary data entry point during therapy sessions
    /// **Real-time Logging:** Creates immediate record of therapeutic interactions
    /// 
    /// - Parameter goalLog: GoalLog model containing attempt details
    /// - Throws: TherapyAppError for validation or save failures
    func logGoal(_ goalLog: GoalLog) async throws {
        // Validate goal description is not empty
        guard !goalLog.goalDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TherapyAppError.validation(field: "Goal Description", reason: "Goal description cannot be empty")
        }
        
        // Verify session exists and is active
        let session = try await fetchSession(goalLog.sessionId)
        if session == nil {
            throw TherapyAppError.sessionNotFound(sessionId: goalLog.sessionId.uuidString)
        }
        
        if session?.endTime != nil {
            throw TherapyAppError.validation(field: "Session", reason: "Cannot log goals to an ended session")
        }
        
        let context = coreDataStack.newBackgroundContext()
        var saveError: Error?
        
        await context.perform {
            // Create goal log entity with complete attempt details
            let entity = GoalLogEntity(context: context)
            entity.id = goalLog.id
            entity.goalTemplateId = goalLog.goalTemplateId  // Optional - may be nil for ad-hoc goals
            entity.goalDescription = goalLog.goalDescription  // Always stored for data integrity
            entity.cueLevel = goalLog.cueLevel.rawValue  // Convert enum to string
            entity.wasSuccessful = goalLog.wasSuccessful  // Core outcome measure
            entity.sessionId = goalLog.sessionId  // Links to containing session
            entity.timestamp = goalLog.timestamp  // Precise timing for analysis
            entity.notes = goalLog.notes  // Optional attempt-specific observations
            
            do {
                try context.save()
            } catch {
                saveError = error
            }
        }
        
        // Propagate error if save failed
        if let error = saveError {
            throw TherapyAppError.coreDataError(error as NSError)
        }
    }
    
    func fetchGoalLogs(for sessionId: UUID) async throws -> [GoalLog] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<GoalLogEntity> = GoalLogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "sessionId == %@", sessionId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GoalLogEntity.timestamp, ascending: true)]
        
        do {
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
                    timestamp: timestamp,
                    notes: entity.notes
                )
            }
        } catch {
            throw TherapyAppError.fetchFailure(error as NSError)
        }
    }
    
    func deleteGoalLog(_ goalLogId: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()
        var operationError: Error?
        
        await context.perform {
            let request: NSFetchRequest<GoalLogEntity> = GoalLogEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", goalLogId as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                guard let entity = entities.first else {
                    operationError = TherapyAppError.validation(field: "Goal Log", reason: "Goal log not found")
                    return
                }
                
                // Verify the goal log's session is still active (prevent deletion from ended sessions)
                if let sessionEntity = entity.session, sessionEntity.endTime != nil {
                    operationError = TherapyAppError.validation(field: "Session", reason: "Cannot delete goals from an ended session")
                    return
                }
                
                context.delete(entity)
                try context.save()
            } catch {
                operationError = error
            }
        }
        
        // Propagate error if operation failed
        if let error = operationError {
            if error is TherapyAppError {
                throw error
            } else {
                throw TherapyAppError.coreDataError(error as NSError)
            }
        }
    }
}