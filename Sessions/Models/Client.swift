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
    
    init(id: UUID, name: String, dateOfBirth: Date?, notes: String?, createdDate: Date, lastModified: Date) {
        self.id = id
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.notes = notes
        self.createdDate = createdDate
        self.lastModified = lastModified
    }
    
    var displayName: String { 
        name 
    }
    
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
    
    var privacyName: String {
        let components = name.components(separatedBy: " ")
        guard components.count > 1 else { return name }
        let firstName = components.first ?? ""
        let lastInitial = String(components.last?.prefix(1) ?? "")
        return "\(firstName) \(lastInitial)."
    }
}