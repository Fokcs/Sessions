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
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        category: String,
        defaultCueLevel: CueLevel,
        clientId: UUID,
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.defaultCueLevel = defaultCueLevel
        self.clientId = clientId
        self.isActive = isActive
        self.createdDate = Date()
    }
    
    init(
        id: UUID,
        title: String,
        description: String?,
        category: String,
        defaultCueLevel: CueLevel,
        clientId: UUID,
        isActive: Bool,
        createdDate: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.defaultCueLevel = defaultCueLevel
        self.clientId = clientId
        self.isActive = isActive
        self.createdDate = createdDate
    }
}