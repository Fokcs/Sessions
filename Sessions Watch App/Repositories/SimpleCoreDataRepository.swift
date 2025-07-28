import CoreData
import Foundation
import Combine

class SimpleCoreDataRepository: ObservableObject, TherapyRepository {
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
            
            do {
                try context.save()
            } catch {
                print("Failed to save client: \(error)")
            }
        }
    }
    
    func fetchClients() async throws -> [Client] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<ClientEntity> = ClientEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClientEntity.name, ascending: true)]
        
        let entities = try context.fetch(request)
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
    }
    
    func updateClient(_ client: Client) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        await context.perform {
            let request: NSFetchRequest<ClientEntity> = ClientEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", client.id as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                guard let entity = entities.first else { return }
                
                entity.name = client.name
                entity.dateOfBirth = client.dateOfBirth
                entity.notes = client.notes
                entity.lastModified = Date()
                
                try context.save()
            } catch {
                print("Failed to update client: \(error)")
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
                guard let entity = entities.first else { return }
                
                context.delete(entity)
                try context.save()
            } catch {
                print("Failed to delete client: \(error)")
            }
        }
    }
    
    func fetchClient(_ clientId: UUID) async throws -> Client? {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<ClientEntity> = ClientEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", clientId as CVarArg)
        request.fetchLimit = 1
        
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
    }
    
    // MARK: - Goal Template Operations
    
    func createGoalTemplate(_ template: GoalTemplate) async throws {
        let context = coreDataStack.newBackgroundContext()
        
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
                print("Failed to save goal template: \(error)")
            }
        }
    }
    
    func fetchGoalTemplates(for clientId: UUID) async throws -> [GoalTemplate] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<GoalTemplateEntity> = GoalTemplateEntity.fetchRequest()
        request.predicate = NSPredicate(format: "clientId == %@ AND isActive == YES", clientId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GoalTemplateEntity.title, ascending: true)]
        
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
    }
    
    func updateGoalTemplate(_ template: GoalTemplate) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        await context.perform {
            let request: NSFetchRequest<GoalTemplateEntity> = GoalTemplateEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", template.id as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                guard let entity = entities.first else { return }
                
                entity.title = template.title
                entity.goalDescription = template.description
                entity.category = template.category
                entity.defaultCueLevel = template.defaultCueLevel.rawValue
                entity.isActive = template.isActive
                
                try context.save()
            } catch {
                print("Failed to update goal template: \(error)")
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
                guard let entity = entities.first else { return }
                
                // Soft delete
                entity.isActive = false
                try context.save()
            } catch {
                print("Failed to delete goal template: \(error)")
            }
        }
    }
    
    func fetchGoalTemplate(_ templateId: UUID) async throws -> GoalTemplate? {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<GoalTemplateEntity> = GoalTemplateEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", templateId as CVarArg)
        request.fetchLimit = 1
        
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
    }
    
    // MARK: - Session Operations
    
    func startSession(for clientId: UUID, location: String?, createdOn: String) async throws -> Session {
        let sessionId = UUID()
        let now = Date()
        let context = coreDataStack.newBackgroundContext()
        
        await context.perform {
            let entity = SessionEntity(context: context)
            entity.id = sessionId
            entity.clientId = clientId
            entity.date = now
            entity.startTime = now
            entity.location = location
            entity.createdOn = createdOn
            entity.lastModified = now
            
            do {
                try context.save()
            } catch {
                print("Failed to start session: \(error)")
            }
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
        
        await context.perform {
            let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", sessionId as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                guard let entity = entities.first else { return }
                
                entity.endTime = Date()
                entity.lastModified = Date()
                
                try context.save()
            } catch {
                print("Failed to end session: \(error)")
            }
        }
    }
    
    func fetchSessions(for clientId: UUID) async throws -> [Session] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "clientId == %@", clientId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SessionEntity.startTime, ascending: false)]
        
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
    }
    
    func fetchActiveSession() async throws -> Session? {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "endTime == nil")
        request.fetchLimit = 1
        
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
    }
    
    func fetchSession(_ sessionId: UUID) async throws -> Session? {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", sessionId as CVarArg)
        request.fetchLimit = 1
        
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
            
            do {
                try context.save()
            } catch {
                print("Failed to log goal: \(error)")
            }
        }
    }
    
    func fetchGoalLogs(for sessionId: UUID) async throws -> [GoalLog] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<GoalLogEntity> = GoalLogEntity.fetchRequest()
        request.predicate = NSPredicate(format: "sessionId == %@", sessionId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GoalLogEntity.timestamp, ascending: true)]
        
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
    }
    
    func deleteGoalLog(_ goalLogId: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        await context.perform {
            let request: NSFetchRequest<GoalLogEntity> = GoalLogEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", goalLogId as CVarArg)
            
            do {
                let entities = try context.fetch(request)
                guard let entity = entities.first else { return }
                
                context.delete(entity)
                try context.save()
            } catch {
                print("Failed to delete goal log: \(error)")
            }
        }
    }
}