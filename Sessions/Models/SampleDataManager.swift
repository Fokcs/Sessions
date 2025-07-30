import Foundation

class SampleDataManager {
    private let repository: any TherapyRepository
    
    init(repository: any TherapyRepository = SimpleCoreDataRepository.shared) {
        self.repository = repository
    }
    
    func generateSampleData() async throws {
        let clients = generateSampleClients()
        
        for client in clients {
            try await repository.createClient(client)
            
            let goalTemplates = generateGoalTemplates(for: client.id, clientAge: client.age)
            for template in goalTemplates {
                try await repository.createGoalTemplate(template)
            }
        }
    }
    
    func clearSampleData() async throws {
        let clients = try await repository.fetchClients()
        
        for client in clients {
            let goalTemplates = try await repository.fetchGoalTemplates(for: client.id)
            for template in goalTemplates {
                try await repository.deleteGoalTemplate(template.id)
            }
            try await repository.deleteClient(client.id)
        }
    }
    
    private func generateSampleClients() -> [Client] {
        let sampleClients: [(name: String, age: Int?, notes: String?)] = [
            ("Emma Johnson", 5, "Articulation disorder, working on /r/ and /l/ sounds"),
            ("Liam Rodriguez", 7, "Language delay, focusing on sentence structure and vocabulary"),
            ("Sophia Chen", 4, "Childhood apraxia of speech, motor speech planning"),
            ("Aiden Williams", 6, "Autism spectrum disorder, communication and social skills"),
            ("Maya Patel", 8, "ADHD, attention and social pragmatics"),
            ("Noah Thompson", 5, "Down syndrome, speech and language development"),
            ("Isabella Garcia", 9, "Stuttering, fluency intervention"),
            ("Ethan Davis", 12, "Voice disorder, vocal hygiene and therapy"),
            ("Olivia Wilson", 15, "Selective mutism, gradual exposure therapy"),
            ("Mason Anderson", 10, "Hearing impaired, speech and language support"),
            ("David Miller", 45, "Post-stroke aphasia, language rehabilitation"),
            ("Sarah Davis", 32, "Professional voice user, vocal efficiency"),
            ("Michael Brown", 28, "Adult stuttering, fluency strategies"),
            ("Jennifer Martinez", 38, "Voice therapy for teachers, vocal care"),
            ("Robert Johnson", 52, "Parkinson's disease, speech clarity"),
            ("Emily Wilson", 67, "Post-surgical speech therapy, head and neck cancer"),
            ("James Anderson", 41, "Traumatic brain injury, cognitive-communication"),
            ("Lisa Thompson", 29, "Gender-affirming voice therapy"),
            ("Christopher Lee", 35, "Foreign accent modification"),
            ("Amanda Rodriguez", 24, "Graduate student, public speaking anxiety")
        ]
        
        let baseDate = Calendar.current.date(byAdding: .day, value: -365, to: Date()) ?? Date()
        
        return sampleClients.enumerated().map { index, clientData in
            let createdDate = Calendar.current.date(byAdding: .day, value: index * 15, to: baseDate) ?? baseDate
            let dateOfBirth = clientData.age.map { age in
                Calendar.current.date(byAdding: .year, value: -age, to: Date()) ?? Date()
            }
            
            return Client(
                id: UUID(),
                name: clientData.name,
                dateOfBirth: dateOfBirth,
                notes: clientData.notes,
                createdDate: createdDate,
                lastModified: createdDate
            )
        }
    }
    
    private func generateGoalTemplates(for clientId: UUID, clientAge: Int?) -> [GoalTemplate] {
        let age = clientAge ?? 25
        let isChild = age < 18
        
        var templates: [GoalTemplate] = []
        let categories = getRelevantCategories(for: age)
        
        for category in categories {
            let categoryTemplates = getGoalTemplatesForCategory(category, isChild: isChild, clientId: clientId)
            templates.append(contentsOf: categoryTemplates)
        }
        
        return templates
    }
    
    private func getRelevantCategories(for age: Int) -> [String] {
        if age <= 12 {
            return ["Articulation", "Language Development", "Social Skills", "Play Skills"]
        } else if age <= 17 {
            return ["Articulation", "Language Development", "Social Skills", "Academic Skills"]
        } else if age <= 65 {
            return ["Speech Clarity", "Voice Therapy", "Communication Skills", "Professional Voice"]
        } else {
            return ["Speech Clarity", "Voice Therapy", "Cognitive Communication", "Swallowing"]
        }
    }
    
    private func getGoalTemplatesForCategory(_ category: String, isChild: Bool, clientId: UUID) -> [GoalTemplate] {
        let goalData = getGoalDataForCategory(category, isChild: isChild)
        let selectedGoals = Array(goalData.shuffled().prefix(Int.random(in: 2...4)))
        
        return selectedGoals.map { goalInfo in
            GoalTemplate(
                title: goalInfo.title,
                description: goalInfo.description,
                category: category,
                defaultCueLevel: goalInfo.defaultCueLevel,
                clientId: clientId
            )
        }
    }
    
    private func getGoalDataForCategory(_ category: String, isChild: Bool) -> [(title: String, description: String?, defaultCueLevel: CueLevel)] {
        switch category {
        case "Articulation":
            return [
                ("Produce /r/ sound accurately", "Practice /r/ in all word positions with 80% accuracy", .moderate),
                ("Improve /s/ sound production", "Eliminate frontal lisp in conversational speech", .minimal),
                ("Correct /th/ substitutions", "Produce /th/ sounds in structured activities", .moderate),
                ("Reduce stopping of fricatives", "Produce /f/, /v/, /s/, /z/ sounds correctly", .maximal),
                ("Eliminate cluster reduction", "Produce consonant clusters in initial position", .moderate)
            ]
            
        case "Language Development":
            if isChild {
                return [
                    ("Expand mean length of utterance", "Increase MLU to 4-5 words consistently", .moderate),
                    ("Follow multi-step directions", "Follow 3-step directions independently", .minimal),
                    ("Use descriptive vocabulary", "Use color, size, and shape adjectives", .moderate),
                    ("Ask wh-questions appropriately", "Use who, what, where questions functionally", .moderate),
                    ("Improve narrative skills", "Tell stories with beginning, middle, end", .maximal)
                ]
            } else {
                return [
                    ("Improve word retrieval", "Reduce word-finding difficulties in conversation", .moderate),
                    ("Enhance sentence formulation", "Construct complex sentences accurately", .minimal),
                    ("Expand vocabulary usage", "Use varied vocabulary in professional settings", .minimal),
                    ("Improve reading comprehension", "Comprehend complex written material", .moderate),
                    ("Strengthen auditory processing", "Process rapid speech more effectively", .moderate)
                ]
            }
            
        case "Social Skills":
            return [
                ("Maintain appropriate eye contact", "Sustain eye contact for 3-5 seconds during interaction", .moderate),
                ("Take turns in conversation", "Wait for conversational turns appropriately", .minimal),
                ("Use appropriate greetings", "Initiate greetings with familiar and unfamiliar people", .moderate),
                ("Understand nonverbal cues", "Interpret facial expressions and body language", .maximal),
                ("Practice conversation skills", "Engage in back-and-forth conversation topics", .moderate)
            ]
            
        case "Play Skills":
            return [
                ("Engage in parallel play", "Play alongside peers for 10 minutes", .moderate),
                ("Share toys and materials", "Take turns with preferred items", .maximal),
                ("Follow game rules", "Participate in simple board games", .moderate),
                ("Use pretend play", "Engage in symbolic play scenarios", .minimal),
                ("Interact with peers", "Initiate play interactions with others", .moderate)
            ]
            
        case "Academic Skills":
            return [
                ("Improve reading fluency", "Read grade-level text with appropriate rate", .moderate),
                ("Enhance writing skills", "Organize written thoughts coherently", .moderate),
                ("Follow classroom instructions", "Complete multi-step academic tasks", .minimal),
                ("Participate in group discussions", "Contribute to classroom conversations", .moderate),
                ("Use organizational strategies", "Manage academic materials and assignments", .maximal)
            ]
            
        case "Speech Clarity":
            return [
                ("Improve overall intelligibility", "Increase speech clarity to 90% in conversation", .moderate),
                ("Reduce rate of speech", "Use appropriate speaking rate for clarity", .minimal),
                ("Enhance breath support", "Use diaphragmatic breathing for speech", .moderate),
                ("Improve articulation precision", "Produce clear consonants and vowels", .moderate),
                ("Practice speaking techniques", "Use clear speech strategies consistently", .minimal)
            ]
            
        case "Voice Therapy":
            return [
                ("Reduce vocal strain", "Use relaxed voice production techniques", .moderate),
                ("Improve vocal hygiene", "Implement voice care strategies daily", .minimal),
                ("Optimize pitch range", "Use appropriate fundamental frequency", .moderate),
                ("Enhance vocal projection", "Project voice without strain", .moderate),
                ("Practice breath coordination", "Coordinate breathing with voice production", .moderate)
            ]
            
        case "Communication Skills":
            return [
                ("Improve conversational skills", "Engage in effective workplace communication", .minimal),
                ("Enhance presentation skills", "Deliver clear, organized presentations", .moderate),
                ("Practice active listening", "Demonstrate understanding through responses", .minimal),
                ("Use nonverbal communication", "Employ appropriate gestures and expressions", .moderate),
                ("Develop assertiveness skills", "Express needs and opinions appropriately", .moderate)
            ]
            
        case "Professional Voice":
            return [
                ("Develop vocal endurance", "Maintain voice quality throughout workday", .moderate),
                ("Practice projection techniques", "Project voice without amplification", .moderate),
                ("Improve vocal variety", "Use pitch and volume changes effectively", .minimal),
                ("Reduce vocal fatigue", "Implement voice conservation strategies", .moderate),
                ("Master microphone technique", "Use amplification systems effectively", .minimal)
            ]
            
        case "Cognitive Communication":
            return [
                ("Improve attention skills", "Sustain attention for 15-20 minutes", .moderate),
                ("Enhance memory strategies", "Use memory aids for daily activities", .moderate),
                ("Practice problem-solving", "Work through multi-step problems", .maximal),
                ("Improve executive function", "Plan and organize daily activities", .maximal),
                ("Strengthen reasoning skills", "Make logical connections in conversation", .moderate)
            ]
            
        case "Swallowing":
            return [
                ("Improve oral intake safety", "Swallow liquids without aspiration", .maximal),
                ("Strengthen swallowing muscles", "Increase tongue and throat muscle strength", .moderate),
                ("Practice safe swallowing", "Use compensatory swallowing strategies", .moderate),
                ("Expand diet consistency", "Progress to more challenging food textures", .maximal),
                ("Implement swallowing techniques", "Use therapeutic swallowing exercises", .moderate)
            ]
            
        default:
            return [
                ("General communication goal", "Improve overall communication effectiveness", .moderate)
            ]
        }
    }
}