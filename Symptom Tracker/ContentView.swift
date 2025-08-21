import SwiftUI
import LocalAuthentication
import Foundation
import UniformTypeIdentifiers
import PDFKit

// MARK: - Data Models
struct SymptomEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    
    // Head / Neurological
    var headacheSeverity: Int = 0
    var headacheNotes: String = ""
    var dizzinessSeverity: Int = 0
    var dizziness: String = ""
    var tinnitusSeverity: Int = 0
    var tinnitus: String = ""
    var visionProblemsSeverity: Int = 0
    var visionProblems: String = ""
    var memoryIssuesSeverity: Int = 0
    var memoryIssues: String = ""
    
    // Mental Health / Sleep
    var moodSeverity: Int = 0
    var mood: String = ""
    var ptsdSeverity: Int = 0
    var ptsdSymptoms: String = ""
    var sleepQualitySeverity: Int = 0
    var sleepQuality: String = ""
    var fatigueLevel: Int = 0
    
    // Respiratory / Airway
    var throatPainSeverity: Int = 0
    var throatPain: String = ""
    var coughSeverity: Int = 0
    var cough: String = ""
    var breathingProblemsSeverity: Int = 0
    var breathingProblems: String = ""
    
    // Cardio / Renal
    var swelling: String = ""
    var urinationIssues: String = ""
    var bloodPressure: String = ""
    
    // GI / Digestive
    var refluxSeverity: Int = 0
    var reflux: String = ""
    var stomachPainSeverity: Int = 0
    var stomachPain: String = ""
    var bowelIssuesSeverity: Int = 0
    var bowelIssues: String = ""
    var appetiteChangesSeverity: Int = 0
    var appetiteChanges: String = ""
    
    // Skin / Extremities
    var alopecia: String = ""
    var footFungus: String = ""
    var dryHands: String = ""
    
    // Musculoskeletal
    var backPainSeverity: Int = 0
    var neckShoulderPainSeverity: Int = 0
    var neckShoulderPain: String = ""
    var flareUpsSeverity: Int = 0
    var flareUps: String = ""
    var limitationsSeverity: Int = 0
    var limitations: String = ""
    
    // Overall Impact
    var workDaysMissed: String = ""
    var activitiesCouldntDo: String = ""
    var treatmentsUsed: String = ""
    var otherNotes: String = ""
    
    init(date: Date = Date()) {
        self.id = UUID()
        self.date = date
    }
}

// MARK: - Data Manager
class SymptomDataManager: ObservableObject {
    @Published var entries: [SymptomEntry] = []
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    init() {
        loadEntries()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.saveEntries()
            print("App entered background - data saved")
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.saveEntries()
            print("App will terminate - data saved")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addEntry(_ entry: SymptomEntry) {
        entries.append(entry)
        saveEntries()
    }
    
    func updateEntry(_ entry: SymptomEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            saveEntries()
        }
    }
    
    func deleteEntry(_ entry: SymptomEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    func saveDraft(_ entry: SymptomEntry) {
        let url = documentsDirectory.appendingPathComponent("symptom_draft.json")
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entry)
            try data.write(to: url)
            print("Draft saved successfully")
        } catch {
            print("Failed to save draft: \(error)")
        }
    }
    
    func loadDraft() -> SymptomEntry? {
        let url = documentsDirectory.appendingPathComponent("symptom_draft.json")
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(SymptomEntry.self, from: data)
        } catch {
            print("Failed to load draft: \(error)")
            return nil
        }
    }
    
    func clearDraft() {
        let url = documentsDirectory.appendingPathComponent("symptom_draft.json")
        try? FileManager.default.removeItem(at: url)
    }
    
    func generatePDF(for entry: SymptomEntry) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // 8.5" x 11"
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let title = "Symptom Log Entry"
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            let dateString = dateFormatter.string(from: entry.date)
            
            var yPosition: CGFloat = 50
            
            // Title
            drawText(title, at: CGPoint(x: 50, y: yPosition), fontSize: 24, bold: true)
            yPosition += 40
            
            // Date
            drawText("Date: \(dateString)", at: CGPoint(x: 50, y: yPosition), fontSize: 16)
            yPosition += 30
            
            // Head / Neurological
            if entry.headacheSeverity > 0 || !entry.headacheNotes.isEmpty || 
               entry.dizzinessSeverity > 0 || !entry.dizziness.isEmpty ||
               entry.tinnitusSeverity > 0 || !entry.tinnitus.isEmpty ||
               entry.visionProblemsSeverity > 0 || !entry.visionProblems.isEmpty ||
               entry.memoryIssuesSeverity > 0 || !entry.memoryIssues.isEmpty {
                yPosition = drawSection("Head / Neurological", yPosition: yPosition)
                
                if entry.headacheSeverity > 0 {
                    yPosition = drawSymptom("Headache Severity", severity: entry.headacheSeverity, notes: entry.headacheNotes, yPosition: yPosition)
                }
                if entry.dizzinessSeverity > 0 {
                    yPosition = drawSymptom("Dizziness Severity", severity: entry.dizzinessSeverity, notes: entry.dizziness, yPosition: yPosition)
                }
                if entry.tinnitusSeverity > 0 {
                    yPosition = drawSymptom("Tinnitus Severity", severity: entry.tinnitusSeverity, notes: entry.tinnitus, yPosition: yPosition)
                }
                if entry.visionProblemsSeverity > 0 {
                    yPosition = drawSymptom("Vision Problems Severity", severity: entry.visionProblemsSeverity, notes: entry.visionProblems, yPosition: yPosition)
                }
                if entry.memoryIssuesSeverity > 0 {
                    yPosition = drawSymptom("Memory Issues Severity", severity: entry.memoryIssuesSeverity, notes: entry.memoryIssues, yPosition: yPosition)
                }
            }
            
            // Mental Health / Sleep
            if entry.moodSeverity > 0 || !entry.mood.isEmpty ||
               entry.ptsdSeverity > 0 || !entry.ptsdSymptoms.isEmpty ||
               entry.sleepQualitySeverity > 0 || !entry.sleepQuality.isEmpty ||
               entry.fatigueLevel > 0 {
                yPosition = drawSection("Mental Health / Sleep", yPosition: yPosition)
                
                if entry.moodSeverity > 0 {
                    yPosition = drawSymptom("Mood Severity", severity: entry.moodSeverity, notes: entry.mood, yPosition: yPosition)
                }
                if entry.ptsdSeverity > 0 {
                    yPosition = drawSymptom("PTSD Severity", severity: entry.ptsdSeverity, notes: entry.ptsdSymptoms, yPosition: yPosition)
                }
                if entry.sleepQualitySeverity > 0 {
                    yPosition = drawSymptom("Sleep Quality Severity", severity: entry.sleepQualitySeverity, notes: entry.sleepQuality, yPosition: yPosition)
                }
                if entry.fatigueLevel > 0 {
                    yPosition = drawSymptom("Fatigue Level", severity: entry.fatigueLevel, notes: "", yPosition: yPosition)
                }
            }
            
            // Respiratory / Airway
            if entry.throatPainSeverity > 0 || !entry.throatPain.isEmpty ||
               entry.coughSeverity > 0 || !entry.cough.isEmpty ||
               entry.breathingProblemsSeverity > 0 || !entry.breathingProblems.isEmpty {
                yPosition = drawSection("Respiratory / Airway", yPosition: yPosition)
                
                if entry.throatPainSeverity > 0 {
                    yPosition = drawSymptom("Throat Pain Severity", severity: entry.throatPainSeverity, notes: entry.throatPain, yPosition: yPosition)
                }
                if entry.coughSeverity > 0 {
                    yPosition = drawSymptom("Cough Severity", severity: entry.coughSeverity, notes: entry.cough, yPosition: yPosition)
                }
                if entry.breathingProblemsSeverity > 0 {
                    yPosition = drawSymptom("Breathing Problems Severity", severity: entry.breathingProblemsSeverity, notes: entry.breathingProblems, yPosition: yPosition)
                }
            }
            
            // Cardio / Renal
            if !entry.swelling.isEmpty || !entry.urinationIssues.isEmpty || !entry.bloodPressure.isEmpty {
                yPosition = drawSection("Cardio / Renal", yPosition: yPosition)
                
                if !entry.swelling.isEmpty {
                    yPosition = drawField("Swelling", value: entry.swelling, yPosition: yPosition)
                }
                if !entry.urinationIssues.isEmpty {
                    yPosition = drawField("Urination Issues", value: entry.urinationIssues, yPosition: yPosition)
                }
                if !entry.bloodPressure.isEmpty {
                    yPosition = drawField("Blood Pressure", value: entry.bloodPressure, yPosition: yPosition)
                }
            }
            
            // GI / Digestive
            if entry.refluxSeverity > 0 || !entry.reflux.isEmpty ||
               entry.stomachPainSeverity > 0 || !entry.stomachPain.isEmpty ||
               entry.bowelIssuesSeverity > 0 || !entry.bowelIssues.isEmpty ||
               entry.appetiteChangesSeverity > 0 || !entry.appetiteChanges.isEmpty {
                yPosition = drawSection("GI / Digestive", yPosition: yPosition)
                
                if entry.refluxSeverity > 0 {
                    yPosition = drawSymptom("Reflux Severity", severity: entry.refluxSeverity, notes: entry.reflux, yPosition: yPosition)
                }
                if entry.stomachPainSeverity > 0 {
                    yPosition = drawSymptom("Stomach Pain Severity", severity: entry.stomachPainSeverity, notes: entry.stomachPain, yPosition: yPosition)
                }
                if entry.bowelIssuesSeverity > 0 {
                    yPosition = drawSymptom("Bowel Issues Severity", severity: entry.bowelIssuesSeverity, notes: entry.bowelIssues, yPosition: yPosition)
                }
                if entry.appetiteChangesSeverity > 0 {
                    yPosition = drawSymptom("Appetite Changes Severity", severity: entry.appetiteChangesSeverity, notes: entry.appetiteChanges, yPosition: yPosition)
                }
            }
            
            // Skin / Extremities
            if !entry.alopecia.isEmpty || !entry.footFungus.isEmpty || !entry.dryHands.isEmpty {
                yPosition = drawSection("Skin / Extremities", yPosition: yPosition)
                
                if !entry.alopecia.isEmpty {
                    yPosition = drawField("Alopecia", value: entry.alopecia, yPosition: yPosition)
                }
                if !entry.footFungus.isEmpty {
                    yPosition = drawField("Foot Fungus", value: entry.footFungus, yPosition: yPosition)
                }
                if !entry.dryHands.isEmpty {
                    yPosition = drawField("Dry Hands/Feet", value: entry.dryHands, yPosition: yPosition)
                }
            }
            
            // Add page breaks as needed
            if yPosition > 700 {
                context.beginPage()
                yPosition = 50
            }
            
            // Musculoskeletal
            if entry.backPainSeverity > 0 || entry.neckShoulderPainSeverity > 0 || !entry.neckShoulderPain.isEmpty ||
               entry.flareUpsSeverity > 0 || !entry.flareUps.isEmpty ||
               entry.limitationsSeverity > 0 || !entry.limitations.isEmpty {
                yPosition = drawSection("Musculoskeletal", yPosition: yPosition)
                
                if entry.backPainSeverity > 0 {
                    yPosition = drawSymptom("Back Pain Severity", severity: entry.backPainSeverity, notes: "", yPosition: yPosition)
                }
                if entry.neckShoulderPainSeverity > 0 {
                    yPosition = drawSymptom("Neck/Shoulder Pain Severity", severity: entry.neckShoulderPainSeverity, notes: entry.neckShoulderPain, yPosition: yPosition)
                }
                if entry.flareUpsSeverity > 0 {
                    yPosition = drawSymptom("Flare-ups Severity", severity: entry.flareUpsSeverity, notes: entry.flareUps, yPosition: yPosition)
                }
                if entry.limitationsSeverity > 0 {
                    yPosition = drawSymptom("Limitations Severity", severity: entry.limitationsSeverity, notes: entry.limitations, yPosition: yPosition)
                }
            }
            
            // Overall Impact
            if !entry.workDaysMissed.isEmpty || !entry.activitiesCouldntDo.isEmpty || !entry.treatmentsUsed.isEmpty || !entry.otherNotes.isEmpty {
                yPosition = drawSection("Overall Impact", yPosition: yPosition)
                
                if !entry.workDaysMissed.isEmpty {
                    yPosition = drawField("Work Days Missed", value: entry.workDaysMissed, yPosition: yPosition)
                }
                if !entry.activitiesCouldntDo.isEmpty {
                    yPosition = drawField("Activities Couldn't Do", value: entry.activitiesCouldntDo, yPosition: yPosition)
                }
                if !entry.treatmentsUsed.isEmpty {
                    yPosition = drawField("Treatments Used", value: entry.treatmentsUsed, yPosition: yPosition)
                }
                if !entry.otherNotes.isEmpty {
                    yPosition = drawField("Other Notes", value: entry.otherNotes, yPosition: yPosition)
                }
            }
            
            func drawSection(_ title: String, yPosition: CGFloat) -> CGFloat {
                drawText(title, at: CGPoint(x: 50, y: yPosition), fontSize: 18, bold: true)
                return yPosition + 25
            }
            
            func drawSymptom(_ name: String, severity: Int, notes: String, yPosition: CGFloat) -> CGFloat {
                var currentY = yPosition
                drawText("\(name): \(severity)/10", at: CGPoint(x: 70, y: currentY), fontSize: 14)
                currentY += 20
                if !notes.isEmpty {
                    currentY = drawWrappedText("Notes: \(notes)", at: CGPoint(x: 70, y: currentY), fontSize: 12, maxWidth: 500)
                    currentY += 10
                }
                return currentY
            }
            
            func drawField(_ name: String, value: String, yPosition: CGFloat) -> CGFloat {
                var currentY = yPosition
                drawText("\(name):", at: CGPoint(x: 70, y: currentY), fontSize: 14, bold: true)
                currentY += 20
                currentY = drawWrappedText(value, at: CGPoint(x: 70, y: currentY), fontSize: 12, maxWidth: 500)
                return currentY + 10
            }
            
            func drawText(_ text: String, at point: CGPoint, fontSize: CGFloat, bold: Bool = false) {
                let font = bold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.black
                ]
                text.draw(at: point, withAttributes: attributes)
            }
            
            func drawWrappedText(_ text: String, at point: CGPoint, fontSize: CGFloat, maxWidth: CGFloat) -> CGFloat {
                let font = UIFont.systemFont(ofSize: fontSize)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.black
                ]
                
                let boundingRect = text.boundingRect(
                    with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
                
                text.draw(in: CGRect(x: point.x, y: point.y, width: maxWidth, height: boundingRect.height), withAttributes: attributes)
                return point.y + boundingRect.height
            }
        }
    }
    
    func generateSummaryPDF(for period: String, entries: [SymptomEntry]) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        print("Generating Summary PDF for period: \(period) with \(entries.count) entries")
        
        return renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 50
            
            // Title
            drawText("Symptom Summary Report - \(period)", at: CGPoint(x: 50, y: yPosition), fontSize: 24, bold: true)
            yPosition += 40
            
            // Summary Statistics
            drawText("Summary Statistics", at: CGPoint(x: 50, y: yPosition), fontSize: 18, bold: true)
            yPosition += 30
            
            drawText("Total Entries: \(entries.count)", at: CGPoint(x: 70, y: yPosition), fontSize: 14)
            yPosition += 20
            
            if !entries.isEmpty {
                let avgHeadache = entries.map { $0.headacheSeverity }.reduce(0, +) / entries.count
                let avgFatigue = entries.map { $0.fatigueLevel }.reduce(0, +) / entries.count
                let avgBackPain = entries.map { $0.backPainSeverity }.reduce(0, +) / entries.count
                let avgMood = entries.map { $0.moodSeverity }.reduce(0, +) / entries.count
                
                drawText("Average Headache Severity: \(avgHeadache)/10", at: CGPoint(x: 70, y: yPosition), fontSize: 14)
                yPosition += 20
                drawText("Average Fatigue Level: \(avgFatigue)/10", at: CGPoint(x: 70, y: yPosition), fontSize: 14)
                yPosition += 20
                drawText("Average Back Pain: \(avgBackPain)/10", at: CGPoint(x: 70, y: yPosition), fontSize: 14)
                yPosition += 20
                drawText("Average Mood Severity: \(avgMood)/10", at: CGPoint(x: 70, y: yPosition), fontSize: 14)
                yPosition += 40
                
                // Add trend chart (if we have entries)
                if entries.count > 0 {
                    if yPosition > 600 {
                        context.beginPage()
                        yPosition = 50
                    }
                    yPosition = drawTrendChart(entries: entries, yPosition: yPosition, context: context)
                }
                
                // Individual entries summary
                drawText("Individual Entries", at: CGPoint(x: 50, y: yPosition), fontSize: 18, bold: true)
                yPosition += 30
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                
                for entry in entries.sorted(by: { $0.date > $1.date }) {
                    if yPosition > 700 {
                        context.beginPage()
                        yPosition = 50
                    }
                    
                    let dateString = dateFormatter.string(from: entry.date)
                    drawText(dateString, at: CGPoint(x: 70, y: yPosition), fontSize: 14, bold: true)
                    yPosition += 20
                    
                    var symptoms: [String] = []
                    if entry.headacheSeverity > 0 { symptoms.append("Headache: \(entry.headacheSeverity)") }
                    if entry.fatigueLevel > 0 { symptoms.append("Fatigue: \(entry.fatigueLevel)") }
                    if entry.backPainSeverity > 0 { symptoms.append("Back Pain: \(entry.backPainSeverity)") }
                    if entry.moodSeverity > 0 { symptoms.append("Mood: \(entry.moodSeverity)") }
                    
                    if !symptoms.isEmpty {
                        let symptomsText = symptoms.joined(separator: ", ")
                        yPosition = drawWrappedText(symptomsText, at: CGPoint(x: 90, y: yPosition), fontSize: 12, maxWidth: 450)
                    }
                    yPosition += 15
                }
            }
            
            func drawText(_ text: String, at point: CGPoint, fontSize: CGFloat, bold: Bool = false) {
                let font = bold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.black
                ]
                text.draw(at: point, withAttributes: attributes)
            }
            
            func drawWrappedText(_ text: String, at point: CGPoint, fontSize: CGFloat, maxWidth: CGFloat) -> CGFloat {
                let font = UIFont.systemFont(ofSize: fontSize)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.black
                ]
                
                let boundingRect = text.boundingRect(
                    with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
                
                text.draw(in: CGRect(x: point.x, y: point.y, width: maxWidth, height: boundingRect.height), withAttributes: attributes)
                return point.y + boundingRect.height
            }
            
            func drawTrendChart(entries: [SymptomEntry], yPosition: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
                let chartHeight: CGFloat = 120
                let chartWidth: CGFloat = 400
                let chartX: CGFloat = 70
                let chartY = yPosition + 20
                
                // Chart title
                drawText("Symptom Severity Trends", at: CGPoint(x: chartX, y: yPosition), fontSize: 16, bold: true)
                
                // Draw chart background
                let chartRect = CGRect(x: chartX, y: chartY, width: chartWidth, height: chartHeight)
                context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
                context.cgContext.setLineWidth(1.0)
                context.cgContext.stroke(chartRect)
                
                // Draw grid lines
                for i in 1...9 {
                    let y = chartY + (chartHeight / 10) * CGFloat(i)
                    context.cgContext.move(to: CGPoint(x: chartX, y: y))
                    context.cgContext.addLine(to: CGPoint(x: chartX + chartWidth, y: y))
                    context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
                    context.cgContext.setLineWidth(0.5)
                    context.cgContext.strokePath()
                }
                
                if !entries.isEmpty {
                    let sortedEntries = entries.sorted { $0.date < $1.date }
                    let maxEntries = min(sortedEntries.count, 10) // Show last 10 entries
                    let recentEntries = Array(sortedEntries.suffix(maxEntries))
                    
                    if recentEntries.count >= 1 {
                        let barWidth = chartWidth / CGFloat(recentEntries.count)
                        
                        // Draw headache severity bars
                        for (index, entry) in recentEntries.enumerated() {
                            let x = chartX + CGFloat(index) * barWidth + 5
                            let barHeight = (CGFloat(entry.headacheSeverity) / 10.0) * chartHeight
                            let barRect = CGRect(x: x, y: chartY + chartHeight - barHeight, width: barWidth - 10, height: barHeight)
                            
                            context.cgContext.setFillColor(UIColor.red.withAlphaComponent(0.7).cgColor)
                            context.cgContext.fill(barRect)
                        }
                        
                        // Draw fatigue level bars (slightly offset)
                        for (index, entry) in recentEntries.enumerated() {
                            let x = chartX + CGFloat(index) * barWidth + barWidth/3
                            let barHeight = (CGFloat(entry.fatigueLevel) / 10.0) * chartHeight
                            let barRect = CGRect(x: x, y: chartY + chartHeight - barHeight, width: barWidth/3 - 2, height: barHeight)
                            
                            context.cgContext.setFillColor(UIColor.orange.withAlphaComponent(0.7).cgColor)
                            context.cgContext.fill(barRect)
                        }
                        
                        // Draw back pain bars (offset further)
                        for (index, entry) in recentEntries.enumerated() {
                            let x = chartX + CGFloat(index) * barWidth + 2*barWidth/3
                            let barHeight = (CGFloat(entry.backPainSeverity) / 10.0) * chartHeight
                            let barRect = CGRect(x: x, y: chartY + chartHeight - barHeight, width: barWidth/3 - 2, height: barHeight)
                            
                            context.cgContext.setFillColor(UIColor.purple.withAlphaComponent(0.7).cgColor)
                            context.cgContext.fill(barRect)
                        }
                    }
                }
                
                // Y-axis labels
                for i in 0...10 {
                    let y = chartY + chartHeight - (chartHeight / 10) * CGFloat(i)
                    drawText("\(i)", at: CGPoint(x: chartX - 20, y: y - 8), fontSize: 10)
                }
                
                // Legend
                let legendY = chartY + chartHeight + 15
                drawText("Red: Headache", at: CGPoint(x: chartX, y: legendY), fontSize: 10)
                drawText("Orange: Fatigue", at: CGPoint(x: chartX + 100, y: legendY), fontSize: 10)
                drawText("Purple: Back Pain", at: CGPoint(x: chartX + 200, y: legendY), fontSize: 10)
                
                return legendY + 30
            }
        }
    }
    
    func generateDetailedEntriesPDF(for entries: [SymptomEntry], title: String) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { context in
            var currentEntry = 0
            let sortedEntries = entries.sorted { $0.date > $1.date }
            
            for entry in sortedEntries {
                context.beginPage()
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .full
                let dateString = dateFormatter.string(from: entry.date)
                
                var yPosition: CGFloat = 50
                
                // Title for first page
                if currentEntry == 0 {
                    drawText(title, at: CGPoint(x: 50, y: yPosition), fontSize: 20, bold: true)
                    yPosition += 30
                    drawText("Generated: \(dateFormatter.string(from: Date()))", at: CGPoint(x: 50, y: yPosition), fontSize: 12)
                    yPosition += 40
                }
                
                // Entry title
                drawText("Entry for: \(dateString)", at: CGPoint(x: 50, y: yPosition), fontSize: 18, bold: true)
                yPosition += 30
                
                // Head / Neurological
                if entry.headacheSeverity > 0 || !entry.headacheNotes.isEmpty || 
                   entry.dizzinessSeverity > 0 || !entry.dizziness.isEmpty ||
                   entry.tinnitusSeverity > 0 || !entry.tinnitus.isEmpty ||
                   entry.visionProblemsSeverity > 0 || !entry.visionProblems.isEmpty ||
                   entry.memoryIssuesSeverity > 0 || !entry.memoryIssues.isEmpty {
                    yPosition = drawSection("Head / Neurological", yPosition: yPosition)
                    
                    if entry.headacheSeverity > 0 {
                        yPosition = drawSymptom("Headache Severity", severity: entry.headacheSeverity, notes: entry.headacheNotes, yPosition: yPosition)
                    }
                    if entry.dizzinessSeverity > 0 {
                        yPosition = drawSymptom("Dizziness Severity", severity: entry.dizzinessSeverity, notes: entry.dizziness, yPosition: yPosition)
                    }
                    if entry.tinnitusSeverity > 0 {
                        yPosition = drawSymptom("Tinnitus Severity", severity: entry.tinnitusSeverity, notes: entry.tinnitus, yPosition: yPosition)
                    }
                    if entry.visionProblemsSeverity > 0 {
                        yPosition = drawSymptom("Vision Problems", severity: entry.visionProblemsSeverity, notes: entry.visionProblems, yPosition: yPosition)
                    }
                    if entry.memoryIssuesSeverity > 0 {
                        yPosition = drawSymptom("Memory Issues", severity: entry.memoryIssuesSeverity, notes: entry.memoryIssues, yPosition: yPosition)
                    }
                }
                
                // Mental Health / Sleep
                if entry.moodSeverity > 0 || !entry.mood.isEmpty ||
                   entry.ptsdSeverity > 0 || !entry.ptsdSymptoms.isEmpty ||
                   entry.sleepQualitySeverity > 0 || !entry.sleepQuality.isEmpty ||
                   entry.fatigueLevel > 0 {
                    yPosition = drawSection("Mental Health / Sleep", yPosition: yPosition)
                    
                    if entry.moodSeverity > 0 {
                        yPosition = drawSymptom("Mood", severity: entry.moodSeverity, notes: entry.mood, yPosition: yPosition)
                    }
                    if entry.ptsdSeverity > 0 {
                        yPosition = drawSymptom("PTSD", severity: entry.ptsdSeverity, notes: entry.ptsdSymptoms, yPosition: yPosition)
                    }
                    if entry.sleepQualitySeverity > 0 {
                        yPosition = drawSymptom("Sleep Quality", severity: entry.sleepQualitySeverity, notes: entry.sleepQuality, yPosition: yPosition)
                    }
                    if entry.fatigueLevel > 0 {
                        yPosition = drawSymptom("Fatigue", severity: entry.fatigueLevel, notes: "", yPosition: yPosition)
                    }
                }
                
                // All other sections...
                if entry.throatPainSeverity > 0 || !entry.throatPain.isEmpty ||
                   entry.coughSeverity > 0 || !entry.cough.isEmpty ||
                   entry.breathingProblemsSeverity > 0 || !entry.breathingProblems.isEmpty {
                    yPosition = drawSection("Respiratory", yPosition: yPosition)
                    
                    if entry.throatPainSeverity > 0 {
                        yPosition = drawSymptom("Throat Pain", severity: entry.throatPainSeverity, notes: entry.throatPain, yPosition: yPosition)
                    }
                    if entry.coughSeverity > 0 {
                        yPosition = drawSymptom("Cough", severity: entry.coughSeverity, notes: entry.cough, yPosition: yPosition)
                    }
                    if entry.breathingProblemsSeverity > 0 {
                        yPosition = drawSymptom("Breathing", severity: entry.breathingProblemsSeverity, notes: entry.breathingProblems, yPosition: yPosition)
                    }
                }
                
                if entry.refluxSeverity > 0 || !entry.reflux.isEmpty ||
                   entry.stomachPainSeverity > 0 || !entry.stomachPain.isEmpty ||
                   entry.bowelIssuesSeverity > 0 || !entry.bowelIssues.isEmpty ||
                   entry.appetiteChangesSeverity > 0 || !entry.appetiteChanges.isEmpty {
                    yPosition = drawSection("Digestive", yPosition: yPosition)
                    
                    if entry.refluxSeverity > 0 {
                        yPosition = drawSymptom("Reflux", severity: entry.refluxSeverity, notes: entry.reflux, yPosition: yPosition)
                    }
                    if entry.stomachPainSeverity > 0 {
                        yPosition = drawSymptom("Stomach Pain", severity: entry.stomachPainSeverity, notes: entry.stomachPain, yPosition: yPosition)
                    }
                    if entry.bowelIssuesSeverity > 0 {
                        yPosition = drawSymptom("Bowel Issues", severity: entry.bowelIssuesSeverity, notes: entry.bowelIssues, yPosition: yPosition)
                    }
                    if entry.appetiteChangesSeverity > 0 {
                        yPosition = drawSymptom("Appetite", severity: entry.appetiteChangesSeverity, notes: entry.appetiteChanges, yPosition: yPosition)
                    }
                }
                
                if entry.backPainSeverity > 0 || entry.neckShoulderPainSeverity > 0 || !entry.neckShoulderPain.isEmpty ||
                   entry.flareUpsSeverity > 0 || !entry.flareUps.isEmpty ||
                   entry.limitationsSeverity > 0 || !entry.limitations.isEmpty {
                    yPosition = drawSection("Musculoskeletal", yPosition: yPosition)
                    
                    if entry.backPainSeverity > 0 {
                        yPosition = drawSymptom("Back Pain", severity: entry.backPainSeverity, notes: "", yPosition: yPosition)
                    }
                    if entry.neckShoulderPainSeverity > 0 {
                        yPosition = drawSymptom("Neck/Shoulder", severity: entry.neckShoulderPainSeverity, notes: entry.neckShoulderPain, yPosition: yPosition)
                    }
                    if entry.flareUpsSeverity > 0 {
                        yPosition = drawSymptom("Flare-ups", severity: entry.flareUpsSeverity, notes: entry.flareUps, yPosition: yPosition)
                    }
                    if entry.limitationsSeverity > 0 {
                        yPosition = drawSymptom("Limitations", severity: entry.limitationsSeverity, notes: entry.limitations, yPosition: yPosition)
                    }
                }
                
                // Overall Impact
                if !entry.workDaysMissed.isEmpty || !entry.activitiesCouldntDo.isEmpty || !entry.treatmentsUsed.isEmpty || !entry.otherNotes.isEmpty {
                    yPosition = drawSection("Overall Impact", yPosition: yPosition)
                    
                    if !entry.workDaysMissed.isEmpty {
                        yPosition = drawField("Work Days Missed", value: entry.workDaysMissed, yPosition: yPosition)
                    }
                    if !entry.activitiesCouldntDo.isEmpty {
                        yPosition = drawField("Activities Missed", value: entry.activitiesCouldntDo, yPosition: yPosition)
                    }
                    if !entry.treatmentsUsed.isEmpty {
                        yPosition = drawField("Treatments", value: entry.treatmentsUsed, yPosition: yPosition)
                    }
                    if !entry.otherNotes.isEmpty {
                        yPosition = drawField("Notes", value: entry.otherNotes, yPosition: yPosition)
                    }
                }
                
                currentEntry += 1
            }
            
            func drawSection(_ title: String, yPosition: CGFloat) -> CGFloat {
                drawText(title, at: CGPoint(x: 50, y: yPosition), fontSize: 16, bold: true)
                return yPosition + 20
            }
            
            func drawSymptom(_ name: String, severity: Int, notes: String, yPosition: CGFloat) -> CGFloat {
                var currentY = yPosition
                drawText("\(name): \(severity)/10", at: CGPoint(x: 70, y: currentY), fontSize: 12)
                currentY += 15
                if !notes.isEmpty {
                    currentY = drawWrappedText("Notes: \(notes)", at: CGPoint(x: 70, y: currentY), fontSize: 10, maxWidth: 450)
                    currentY += 5
                }
                return currentY
            }
            
            func drawField(_ name: String, value: String, yPosition: CGFloat) -> CGFloat {
                var currentY = yPosition
                drawText("\(name):", at: CGPoint(x: 70, y: currentY), fontSize: 12, bold: true)
                currentY += 15
                currentY = drawWrappedText(value, at: CGPoint(x: 70, y: currentY), fontSize: 10, maxWidth: 450)
                return currentY + 5
            }
            
            func drawText(_ text: String, at point: CGPoint, fontSize: CGFloat, bold: Bool = false) {
                let font = bold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.black
                ]
                text.draw(at: point, withAttributes: attributes)
            }
            
            func drawWrappedText(_ text: String, at point: CGPoint, fontSize: CGFloat, maxWidth: CGFloat) -> CGFloat {
                let font = UIFont.systemFont(ofSize: fontSize)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.black
                ]
                
                let boundingRect = text.boundingRect(
                    with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
                
                text.draw(in: CGRect(x: point.x, y: point.y, width: maxWidth, height: boundingRect.height), withAttributes: attributes)
                return point.y + boundingRect.height
            }
        }
    }
    
    func saveEntries() {
        let url = documentsDirectory.appendingPathComponent("symptom_entries.json")
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(entries)
            try data.write(to: url)
            print("Successfully saved \(entries.count) entries to: \(url.path)")
        } catch {
            print("Failed to save entries: \(error)")
            print("Error details: \(error.localizedDescription)")
        }
    }
    
    private func loadEntries() {
        let url = documentsDirectory.appendingPathComponent("symptom_entries.json")
        
        // Check if file exists
        if !FileManager.default.fileExists(atPath: url.path) {
            print("Entries file does not exist at: \(url.path)")
            entries = []
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            print("Loaded data size: \(data.count) bytes")
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            entries = try decoder.decode([SymptomEntry].self, from: data)
            print("Successfully loaded \(entries.count) entries")
        } catch {
            print("Failed to load entries: \(error)")
            print("Error details: \(error.localizedDescription)")
            
            // Try to recover by creating a backup and starting fresh
            let backupURL = documentsDirectory.appendingPathComponent("symptom_entries_backup.json")
            try? FileManager.default.copyItem(at: url, to: backupURL)
            print("Created backup at: \(backupURL.path)")
            
            entries = []
        }
    }
    
    func exportToCSV() -> String {
        let header = "Date,Headache Severity,Headache Notes,Dizziness Severity,Dizziness,Tinnitus Severity,Tinnitus,Vision Problems Severity,Vision Problems,Memory Issues Severity,Memory Issues,Mood Severity,Mood,PTSD Severity,PTSD Symptoms,Sleep Quality Severity,Sleep Quality,Fatigue Level,Throat Pain Severity,Throat Pain,Cough Severity,Cough,Breathing Problems Severity,Breathing Problems,Swelling,Urination Issues,Blood Pressure,Reflux Severity,Reflux,Stomach Pain Severity,Stomach Pain,Bowel Issues Severity,Bowel Issues,Appetite Changes Severity,Appetite Changes,Alopecia,Foot Fungus,Dry Hands,Back Pain Severity,Neck/Shoulder Pain Severity,Neck/Shoulder Pain,Flare-ups Severity,Flare-ups,Limitations Severity,Limitations,Work Days Missed,Activities Couldn't Do,Treatments Used,Other Notes\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        let rows = entries.map { entry in
            let date = dateFormatter.string(from: entry.date)
            return "\"\(date)\",\(entry.headacheSeverity),\"\(entry.headacheNotes)\",\(entry.dizzinessSeverity),\"\(entry.dizziness)\",\(entry.tinnitusSeverity),\"\(entry.tinnitus)\",\(entry.visionProblemsSeverity),\"\(entry.visionProblems)\",\(entry.memoryIssuesSeverity),\"\(entry.memoryIssues)\",\(entry.moodSeverity),\"\(entry.mood)\",\(entry.ptsdSeverity),\"\(entry.ptsdSymptoms)\",\(entry.sleepQualitySeverity),\"\(entry.sleepQuality)\",\(entry.fatigueLevel),\(entry.throatPainSeverity),\"\(entry.throatPain)\",\(entry.coughSeverity),\"\(entry.cough)\",\(entry.breathingProblemsSeverity),\"\(entry.breathingProblems)\",\"\(entry.swelling)\",\"\(entry.urinationIssues)\",\"\(entry.bloodPressure)\",\(entry.refluxSeverity),\"\(entry.reflux)\",\(entry.stomachPainSeverity),\"\(entry.stomachPain)\",\(entry.bowelIssuesSeverity),\"\(entry.bowelIssues)\",\(entry.appetiteChangesSeverity),\"\(entry.appetiteChanges)\",\"\(entry.alopecia)\",\"\(entry.footFungus)\",\"\(entry.dryHands)\",\(entry.backPainSeverity),\(entry.neckShoulderPainSeverity),\"\(entry.neckShoulderPain)\",\(entry.flareUpsSeverity),\"\(entry.flareUps)\",\(entry.limitationsSeverity),\"\(entry.limitations)\",\"\(entry.workDaysMissed)\",\"\(entry.activitiesCouldntDo)\",\"\(entry.treatmentsUsed)\",\"\(entry.otherNotes)\""
        }.joined(separator: "\n")
        
        return header + rows
    }
    
    func getWeeklySummary() -> [SymptomEntry] {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { $0.date >= oneWeekAgo }.sorted { $0.date > $1.date }
    }
    
    func getMonthlySummary() -> [SymptomEntry] {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return entries.filter { $0.date >= oneMonthAgo }.sorted { $0.date > $1.date }
    }
    
    func getYearlySummary() -> [SymptomEntry] {
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        return entries.filter { $0.date >= oneYearAgo }.sorted { $0.date > $1.date }
    }
}

// MARK: - Content View
// Legacy ContentView - kept for compatibility
struct ContentView: View {
    var body: some View {
        TrackerMainView()
    }
}

// MARK: - Daily Log View
struct DailyLogView: View {
    @EnvironmentObject var dataManager: SymptomDataManager
    @State private var currentEntry = SymptomEntry(date: Date())
    @State private var showingSaveAlert = false
    @State private var showingDraftAlert = false
    @State private var hasDraft = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Date") {
                    DatePicker("Entry Date", selection: Binding(
                        get: { currentEntry.date },
                        set: { currentEntry.date = $0 }
                    ), displayedComponents: .date)
                }
                
                // Head / Neurological
                Section("Head / Neurological") {
                    VStack(alignment: .leading) {
                        Text("Headache Severity (1-10): \(currentEntry.headacheSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.headacheSeverity) },
                            set: { currentEntry.headacheSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Headache Notes", text: Binding(
                        get: { currentEntry.headacheNotes },
                        set: { currentEntry.headacheNotes = $0 }
                    ), axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Dizziness Severity (1-10): \(currentEntry.dizzinessSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.dizzinessSeverity) },
                            set: { currentEntry.dizzinessSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Dizziness / Balance Issues Notes", text: Binding(
                        get: { currentEntry.dizziness },
                        set: { currentEntry.dizziness = $0 }
                    ), axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Tinnitus Severity (1-10): \(currentEntry.tinnitusSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.tinnitusSeverity) },
                            set: { currentEntry.tinnitusSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Tinnitus / Hearing Issues Notes", text: Binding(
                        get: { currentEntry.tinnitus },
                        set: { currentEntry.tinnitus = $0 }
                    ), axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Vision Problems Severity (1-10): \(currentEntry.visionProblemsSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.visionProblemsSeverity) },
                            set: { currentEntry.visionProblemsSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Vision Problems Notes", text: Binding(
                        get: { currentEntry.visionProblems },
                        set: { currentEntry.visionProblems = $0 }
                    ), axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Memory/Concentration Severity (1-10): \(currentEntry.memoryIssuesSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.memoryIssuesSeverity) },
                            set: { currentEntry.memoryIssuesSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Memory / Concentration Issues Notes", text: Binding(
                        get: { currentEntry.memoryIssues },
                        set: { currentEntry.memoryIssues = $0 }
                    ), axis: .vertical)
                }
                
                // Mental Health / Sleep
                Section("Mental Health / Sleep") {
                    VStack(alignment: .leading) {
                        Text("Mood Severity (1-10): \(currentEntry.moodSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.moodSeverity) },
                            set: { currentEntry.moodSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Mood Notes (Depression/Anxiety/Irritability)", text: Binding(
                        get: { currentEntry.mood },
                        set: { currentEntry.mood = $0 }
                    ), axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("PTSD Severity (1-10): \(currentEntry.ptsdSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.ptsdSeverity) },
                            set: { currentEntry.ptsdSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("PTSD Symptoms Notes", text: Binding(
                        get: { currentEntry.ptsdSymptoms },
                        set: { currentEntry.ptsdSymptoms = $0 }
                    ), axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Sleep Quality Severity (1-10): \(currentEntry.sleepQualitySeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.sleepQualitySeverity) },
                            set: { currentEntry.sleepQualitySeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Sleep Quality Notes (hours/night terrors/awakenings)", text: Binding(
                        get: { currentEntry.sleepQuality },
                        set: { currentEntry.sleepQuality = $0 }
                    ), axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Fatigue Level (1-10): \(currentEntry.fatigueLevel)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.fatigueLevel) },
                            set: { currentEntry.fatigueLevel = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                }
                
                // Respiratory / Airway
                Section("Respiratory / Airway") {
                    VStack(alignment: .leading) {
                        Text("Throat Pain Severity (1-10): \(currentEntry.throatPainSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.throatPainSeverity) },
                            set: { currentEntry.throatPainSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Throat pain/swelling Notes (uvulitis)", text: Binding(
                        get: { currentEntry.throatPain },
                        set: { currentEntry.throatPain = $0 }
                    ), axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Cough Severity (1-10): \(currentEntry.coughSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.coughSeverity) },
                            set: { currentEntry.coughSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Cough / Phlegm Notes", text: Binding(
                        get: { currentEntry.cough },
                        set: { currentEntry.cough = $0 }
                    ), axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Breathing Problems Severity (1-10): \(currentEntry.breathingProblemsSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.breathingProblemsSeverity) },
                            set: { currentEntry.breathingProblemsSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Breathing Problems Notes", text: Binding(
                        get: { currentEntry.breathingProblems },
                        set: { currentEntry.breathingProblems = $0 }
                    ), axis: .vertical)
                }
                
                // Cardio / Renal
                Section("Cardio / Renal") {
                    TextField("Swelling (legs/ankles/feet)", text: Binding(
                        get: { currentEntry.swelling },
                        set: { currentEntry.swelling = $0 }
                    ), axis: .vertical)
                    TextField("Urination issues", text: Binding(
                        get: { currentEntry.urinationIssues },
                        set: { currentEntry.urinationIssues = $0 }
                    ), axis: .vertical)
                    TextField("Blood Pressure", text: Binding(
                        get: { currentEntry.bloodPressure },
                        set: { currentEntry.bloodPressure = $0 }
                    ), axis: .vertical)
                }
                
                // GI / Digestive
                Section("GI / Digestive") {
                    VStack(alignment: .leading) {
                        Text("Reflux Severity (1-10): \(currentEntry.refluxSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.refluxSeverity) },
                            set: { currentEntry.refluxSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Reflux / Heartburn Notes", text: Binding(
                        get: { currentEntry.reflux },
                        set: { currentEntry.reflux = $0 }
                    ), axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Stomach Pain Severity (1-10): \(currentEntry.stomachPainSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.stomachPainSeverity) },
                            set: { currentEntry.stomachPainSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Stomach pain / Nausea Notes", text: Binding(
                        get: { currentEntry.stomachPain },
                        set: { currentEntry.stomachPain = $0 }
                    ), axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Bowel Issues Severity (1-10): \(currentEntry.bowelIssuesSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.bowelIssuesSeverity) },
                            set: { currentEntry.bowelIssuesSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Diarrhea / Constipation Notes", text: Binding(
                        get: { currentEntry.bowelIssues },
                        set: { currentEntry.bowelIssues = $0 }
                    ), axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Appetite Changes Severity (1-10): \(currentEntry.appetiteChangesSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.appetiteChangesSeverity) },
                            set: { currentEntry.appetiteChangesSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Appetite changes Notes", text: Binding(
                        get: { currentEntry.appetiteChanges },
                        set: { currentEntry.appetiteChanges = $0 }
                    ), axis: .vertical)
                }
                
                // Skin / Extremities
                Section("Skin / Extremities") {
                    TextField("Alopecia (hair loss areas noticed today)", text: Binding(
                        get: { currentEntry.alopecia },
                        set: { currentEntry.alopecia = $0 }
                    ), axis: .vertical)
                    TextField("Foot Fungus (itching, cracking, redness)", text: Binding(
                        get: { currentEntry.footFungus },
                        set: { currentEntry.footFungus = $0 }
                    ), axis: .vertical)
                    TextField("Dry/Cracked Hands or Feet", text: Binding(
                        get: { currentEntry.dryHands },
                        set: { currentEntry.dryHands = $0 }
                    ), axis: .vertical)
                }
                
                // Musculoskeletal
                Section("Musculoskeletal") {
                    VStack(alignment: .leading) {
                        Text("Back Pain Severity (1-10): \(currentEntry.backPainSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.backPainSeverity) },
                            set: { currentEntry.backPainSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    VStack(alignment: .leading) {
                        Text("Neck/Shoulder Pain Severity (1-10): \(currentEntry.neckShoulderPainSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.neckShoulderPainSeverity) },
                            set: { currentEntry.neckShoulderPainSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Neck / Shoulder / Joint Pain Notes", text: Binding(
                        get: { currentEntry.neckShoulderPain },
                        set: { currentEntry.neckShoulderPain = $0 }
                    ), axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Flare-ups Severity (1-10): \(currentEntry.flareUpsSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.flareUpsSeverity) },
                            set: { currentEntry.flareUpsSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Flare-ups today Notes", text: Binding(
                        get: { currentEntry.flareUps },
                        set: { currentEntry.flareUps = $0 }
                    ), axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Limitations Severity (1-10): \(currentEntry.limitationsSeverity)")
                        Slider(value: Binding(
                            get: { Double(currentEntry.limitationsSeverity) },
                            set: { currentEntry.limitationsSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Limitations Notes (walking, sitting, lifting, daily activities)", text: Binding(
                        get: { currentEntry.limitations },
                        set: { currentEntry.limitations = $0 }
                    ), axis: .vertical)
                }
                
                // Overall Daily Impact
                Section("Overall Daily Impact") {
                    TextField("Work/School Days Missed or Limited", text: Binding(
                        get: { currentEntry.workDaysMissed },
                        set: { currentEntry.workDaysMissed = $0 }
                    ), axis: .vertical)
                    TextField("Activities I Couldn't Do Today", text: Binding(
                        get: { currentEntry.activitiesCouldntDo },
                        set: { currentEntry.activitiesCouldntDo = $0 }
                    ), axis: .vertical)
                    TextField("Treatments / Medications Used", text: Binding(
                        get: { currentEntry.treatmentsUsed },
                        set: { currentEntry.treatmentsUsed = $0 }
                    ), axis: .vertical)
                    TextField("Other Notes", text: Binding(
                        get: { currentEntry.otherNotes },
                        set: { currentEntry.otherNotes = $0 }
                    ), axis: .vertical)
                }
            }
            .navigationTitle("Daily Symptom Log")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                hideKeyboard()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Save Draft") {
                        dataManager.saveDraft(currentEntry)
                        showingSaveAlert = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Entry") {
                        dataManager.addEntry(currentEntry)
                        dataManager.clearDraft()
                        currentEntry = SymptomEntry(date: Date())
                        showingSaveAlert = true
                    }
                }
            }
            .onAppear {
                if let draft = dataManager.loadDraft() {
                    hasDraft = true
                    showingDraftAlert = true
                }
            }
            .onChange(of: currentEntry) { _ in
                dataManager.saveDraft(currentEntry)
            }
            .alert("Entry Saved", isPresented: $showingSaveAlert) {
                Button("OK") { }
            } message: {
                Text("Your symptom log has been saved successfully.")
            }
            .alert("Draft Found", isPresented: $showingDraftAlert) {
                Button("Load Draft") {
                    if let draft = dataManager.loadDraft() {
                        currentEntry = draft
                    }
                }
                Button("Start Fresh") {
                    dataManager.clearDraft()
                }
            } message: {
                Text("You have an unsaved draft. Would you like to continue where you left off?")
            }
        }
    }
}

// MARK: - Entry List View
struct EntryListView: View {
    @EnvironmentObject var dataManager: SymptomDataManager
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.entries.sorted { $0.date > $1.date }) { entry in
                    NavigationLink(destination: EntryDetailView(entry: entry)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.date, style: .date)
                                .font(.headline)
                            HStack {
                                if entry.headacheSeverity > 0 {
                                    Label("\(entry.headacheSeverity)", systemImage: "head.profile.arrow.forward.and.visionpro")
                                        .foregroundColor(.red)
                                }
                                if entry.fatigueLevel > 0 {
                                    Label("\(entry.fatigueLevel)", systemImage: "battery.25")
                                        .foregroundColor(.orange)
                                }
                                if entry.backPainSeverity > 0 {
                                    Label("\(entry.backPainSeverity)", systemImage: "figure.walk")
                                        .foregroundColor(.purple)
                                }
                                if entry.moodSeverity > 0 {
                                    Label("\(entry.moodSeverity)", systemImage: "brain.head.profile")
                                        .foregroundColor(.blue)
                                }
                                if entry.stomachPainSeverity > 0 {
                                    Label("\(entry.stomachPainSeverity)", systemImage: "stomach")
                                        .foregroundColor(.green)
                                }
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .onDelete(perform: deleteEntries)
            }
            .navigationTitle("Symptom Entries")
            .toolbar {
                EditButton()
            }
        }
    }
    
    private func deleteEntries(offsets: IndexSet) {
        let sortedEntries = dataManager.entries.sorted { $0.date > $1.date }
        for index in offsets {
            dataManager.deleteEntry(sortedEntries[index])
        }
    }
}

// MARK: - Entry Detail View
struct EntryDetailView: View {
    @EnvironmentObject var dataManager: SymptomDataManager
    @State private var entry: SymptomEntry
    @State private var isEditing = false
    @State private var showingSaveAlert = false
    
    init(entry: SymptomEntry) {
        self._entry = State(initialValue: entry)
    }
    
    var body: some View {
        if isEditing {
            editableForm
        } else {
            readOnlyForm
        }
    }
    
    private var readOnlyForm: some View {
        Form {
            Section("Date") {
                Text(entry.date, style: .date)
            }
            
            if entry.headacheSeverity > 0 || !entry.headacheNotes.isEmpty || entry.dizzinessSeverity > 0 || !entry.dizziness.isEmpty || entry.tinnitusSeverity > 0 || !entry.tinnitus.isEmpty || entry.visionProblemsSeverity > 0 || !entry.visionProblems.isEmpty || entry.memoryIssuesSeverity > 0 || !entry.memoryIssues.isEmpty {
                Section("Head / Neurological") {
                    if entry.headacheSeverity > 0 {
                        Text("Headache Severity: \(entry.headacheSeverity)/10")
                    }
                    if !entry.headacheNotes.isEmpty {
                        Text("Notes: \(entry.headacheNotes)")
                    }
                    if entry.dizzinessSeverity > 0 {
                        Text("Dizziness Severity: \(entry.dizzinessSeverity)/10")
                    }
                    if !entry.dizziness.isEmpty {
                        Text("Dizziness: \(entry.dizziness)")
                    }
                    if entry.tinnitusSeverity > 0 {
                        Text("Tinnitus Severity: \(entry.tinnitusSeverity)/10")
                    }
                    if !entry.tinnitus.isEmpty {
                        Text("Tinnitus: \(entry.tinnitus)")
                    }
                    if entry.visionProblemsSeverity > 0 {
                        Text("Vision Severity: \(entry.visionProblemsSeverity)/10")
                    }
                    if !entry.visionProblems.isEmpty {
                        Text("Vision: \(entry.visionProblems)")
                    }
                    if entry.memoryIssuesSeverity > 0 {
                        Text("Memory Severity: \(entry.memoryIssuesSeverity)/10")
                    }
                    if !entry.memoryIssues.isEmpty {
                        Text("Memory: \(entry.memoryIssues)")
                    }
                }
            }
            
            if entry.fatigueLevel > 0 || entry.moodSeverity > 0 || !entry.mood.isEmpty || entry.ptsdSeverity > 0 || !entry.ptsdSymptoms.isEmpty || entry.sleepQualitySeverity > 0 || !entry.sleepQuality.isEmpty {
                Section("Mental Health / Sleep") {
                    if entry.moodSeverity > 0 {
                        Text("Mood Severity: \(entry.moodSeverity)/10")
                    }
                    if !entry.mood.isEmpty {
                        Text("Mood: \(entry.mood)")
                    }
                    if entry.ptsdSeverity > 0 {
                        Text("PTSD Severity: \(entry.ptsdSeverity)/10")
                    }
                    if !entry.ptsdSymptoms.isEmpty {
                        Text("PTSD: \(entry.ptsdSymptoms)")
                    }
                    if entry.sleepQualitySeverity > 0 {
                        Text("Sleep Quality Severity: \(entry.sleepQualitySeverity)/10")
                    }
                    if !entry.sleepQuality.isEmpty {
                        Text("Sleep: \(entry.sleepQuality)")
                    }
                    if entry.fatigueLevel > 0 {
                        Text("Fatigue: \(entry.fatigueLevel)/10")
                    }
                }
            }
            
            if entry.throatPainSeverity > 0 || !entry.throatPain.isEmpty || entry.coughSeverity > 0 || !entry.cough.isEmpty || entry.breathingProblemsSeverity > 0 || !entry.breathingProblems.isEmpty {
                Section("Respiratory / Airway") {
                    if entry.throatPainSeverity > 0 {
                        Text("Throat Pain Severity: \(entry.throatPainSeverity)/10")
                    }
                    if !entry.throatPain.isEmpty {
                        Text("Throat: \(entry.throatPain)")
                    }
                    if entry.coughSeverity > 0 {
                        Text("Cough Severity: \(entry.coughSeverity)/10")
                    }
                    if !entry.cough.isEmpty {
                        Text("Cough: \(entry.cough)")
                    }
                    if entry.breathingProblemsSeverity > 0 {
                        Text("Breathing Severity: \(entry.breathingProblemsSeverity)/10")
                    }
                    if !entry.breathingProblems.isEmpty {
                        Text("Breathing: \(entry.breathingProblems)")
                    }
                }
            }
            
            if !entry.swelling.isEmpty || !entry.urinationIssues.isEmpty || !entry.bloodPressure.isEmpty {
                Section("Cardio / Renal") {
                    if !entry.swelling.isEmpty {
                        Text("Swelling: \(entry.swelling)")
                    }
                    if !entry.urinationIssues.isEmpty {
                        Text("Urination: \(entry.urinationIssues)")
                    }
                    if !entry.bloodPressure.isEmpty {
                        Text("Blood Pressure: \(entry.bloodPressure)")
                    }
                }
            }
            
            if entry.refluxSeverity > 0 || !entry.reflux.isEmpty || entry.stomachPainSeverity > 0 || !entry.stomachPain.isEmpty || entry.bowelIssuesSeverity > 0 || !entry.bowelIssues.isEmpty || entry.appetiteChangesSeverity > 0 || !entry.appetiteChanges.isEmpty {
                Section("GI / Digestive") {
                    if entry.refluxSeverity > 0 {
                        Text("Reflux Severity: \(entry.refluxSeverity)/10")
                    }
                    if !entry.reflux.isEmpty {
                        Text("Reflux: \(entry.reflux)")
                    }
                    if entry.stomachPainSeverity > 0 {
                        Text("Stomach Pain Severity: \(entry.stomachPainSeverity)/10")
                    }
                    if !entry.stomachPain.isEmpty {
                        Text("Stomach: \(entry.stomachPain)")
                    }
                    if entry.bowelIssuesSeverity > 0 {
                        Text("Bowel Issues Severity: \(entry.bowelIssuesSeverity)/10")
                    }
                    if !entry.bowelIssues.isEmpty {
                        Text("Bowel: \(entry.bowelIssues)")
                    }
                    if entry.appetiteChangesSeverity > 0 {
                        Text("Appetite Severity: \(entry.appetiteChangesSeverity)/10")
                    }
                    if !entry.appetiteChanges.isEmpty {
                        Text("Appetite: \(entry.appetiteChanges)")
                    }
                }
            }
            
            if !entry.alopecia.isEmpty || !entry.footFungus.isEmpty || !entry.dryHands.isEmpty {
                Section("Skin / Extremities") {
                    if !entry.alopecia.isEmpty {
                        Text("Alopecia: \(entry.alopecia)")
                    }
                    if !entry.footFungus.isEmpty {
                        Text("Foot Fungus: \(entry.footFungus)")
                    }
                    if !entry.dryHands.isEmpty {
                        Text("Dry Hands/Feet: \(entry.dryHands)")
                    }
                }
            }
            
            if entry.backPainSeverity > 0 || entry.neckShoulderPainSeverity > 0 || !entry.neckShoulderPain.isEmpty || entry.flareUpsSeverity > 0 || !entry.flareUps.isEmpty || entry.limitationsSeverity > 0 || !entry.limitations.isEmpty {
                Section("Musculoskeletal") {
                    if entry.backPainSeverity > 0 {
                        Text("Back Pain: \(entry.backPainSeverity)/10")
                    }
                    if entry.neckShoulderPainSeverity > 0 {
                        Text("Neck/Shoulder Severity: \(entry.neckShoulderPainSeverity)/10")
                    }
                    if !entry.neckShoulderPain.isEmpty {
                        Text("Neck/Shoulder: \(entry.neckShoulderPain)")
                    }
                    if entry.flareUpsSeverity > 0 {
                        Text("Flare-ups Severity: \(entry.flareUpsSeverity)/10")
                    }
                    if !entry.flareUps.isEmpty {
                        Text("Flare-ups: \(entry.flareUps)")
                    }
                    if entry.limitationsSeverity > 0 {
                        Text("Limitations Severity: \(entry.limitationsSeverity)/10")
                    }
                    if !entry.limitations.isEmpty {
                        Text("Limitations: \(entry.limitations)")
                    }
                }
            }
            
            if !entry.workDaysMissed.isEmpty || !entry.activitiesCouldntDo.isEmpty || !entry.treatmentsUsed.isEmpty || !entry.otherNotes.isEmpty {
                Section("Overall Impact") {
                    if !entry.workDaysMissed.isEmpty {
                        Text("Work Missed: \(entry.workDaysMissed)")
                    }
                    if !entry.activitiesCouldntDo.isEmpty {
                        Text("Activities Missed: \(entry.activitiesCouldntDo)")
                    }
                    if !entry.treatmentsUsed.isEmpty {
                        Text("Treatments: \(entry.treatmentsUsed)")
                    }
                    if !entry.otherNotes.isEmpty {
                        Text("Notes: \(entry.otherNotes)")
                    }
                }
            }
        }
        .navigationTitle("Entry Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Export PDF") {
                    let pdfData = dataManager.generatePDF(for: entry)
                    let fileName = "SymptomEntry-\(entry.date.formatted(date: .abbreviated, time: .omitted)).pdf"
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                    
                    do {
                        try pdfData.write(to: tempURL)
                        let activityController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController?.present(activityController, animated: true)
                        }
                    } catch {
                        print("Failed to create PDF file: \(error)")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
    }
    
    private var editableForm: some View {
        NavigationView {
            Form {
                Section("Date") {
                    DatePicker("Entry Date", selection: $entry.date, displayedComponents: .date)
                }
                
                // Head / Neurological
                Section("Head / Neurological") {
                    VStack(alignment: .leading) {
                        Text("Headache Severity (1-10): \(entry.headacheSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.headacheSeverity) },
                            set: { entry.headacheSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Headache Notes", text: $entry.headacheNotes, axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Dizziness Severity (1-10): \(entry.dizzinessSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.dizzinessSeverity) },
                            set: { entry.dizzinessSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Dizziness / Balance Issues Notes", text: $entry.dizziness, axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Tinnitus Severity (1-10): \(entry.tinnitusSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.tinnitusSeverity) },
                            set: { entry.tinnitusSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Tinnitus / Hearing Issues Notes", text: $entry.tinnitus, axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Vision Problems Severity (1-10): \(entry.visionProblemsSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.visionProblemsSeverity) },
                            set: { entry.visionProblemsSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Vision Problems Notes", text: $entry.visionProblems, axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Memory/Concentration Severity (1-10): \(entry.memoryIssuesSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.memoryIssuesSeverity) },
                            set: { entry.memoryIssuesSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Memory / Concentration Issues Notes", text: $entry.memoryIssues, axis: .vertical)
                }
                
                // Mental Health / Sleep
                Section("Mental Health / Sleep") {
                    VStack(alignment: .leading) {
                        Text("Mood Severity (1-10): \(entry.moodSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.moodSeverity) },
                            set: { entry.moodSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Mood Notes (Depression/Anxiety/Irritability)", text: $entry.mood, axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("PTSD Severity (1-10): \(entry.ptsdSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.ptsdSeverity) },
                            set: { entry.ptsdSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("PTSD Symptoms Notes", text: $entry.ptsdSymptoms, axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Sleep Quality Severity (1-10): \(entry.sleepQualitySeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.sleepQualitySeverity) },
                            set: { entry.sleepQualitySeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Sleep Quality Notes (hours/night terrors/awakenings)", text: $entry.sleepQuality, axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Fatigue Level (1-10): \(entry.fatigueLevel)")
                        Slider(value: Binding(
                            get: { Double(entry.fatigueLevel) },
                            set: { entry.fatigueLevel = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                }
                
                // Respiratory / Airway
                Section("Respiratory / Airway") {
                    VStack(alignment: .leading) {
                        Text("Throat Pain Severity (1-10): \(entry.throatPainSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.throatPainSeverity) },
                            set: { entry.throatPainSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Throat pain/swelling Notes (uvulitis)", text: $entry.throatPain, axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Cough Severity (1-10): \(entry.coughSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.coughSeverity) },
                            set: { entry.coughSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Cough / Phlegm Notes", text: $entry.cough, axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Breathing Problems Severity (1-10): \(entry.breathingProblemsSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.breathingProblemsSeverity) },
                            set: { entry.breathingProblemsSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Breathing Problems Notes", text: $entry.breathingProblems, axis: .vertical)
                }
                
                // Cardio / Renal
                Section("Cardio / Renal") {
                    TextField("Swelling (legs/ankles/feet)", text: $entry.swelling, axis: .vertical)
                    TextField("Urination issues", text: $entry.urinationIssues, axis: .vertical)
                    TextField("Blood Pressure", text: $entry.bloodPressure, axis: .vertical)
                }
                
                // GI / Digestive
                Section("GI / Digestive") {
                    VStack(alignment: .leading) {
                        Text("Reflux Severity (1-10): \(entry.refluxSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.refluxSeverity) },
                            set: { entry.refluxSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Reflux / Heartburn Notes", text: $entry.reflux, axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Stomach Pain Severity (1-10): \(entry.stomachPainSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.stomachPainSeverity) },
                            set: { entry.stomachPainSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Stomach pain / Nausea Notes", text: $entry.stomachPain, axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Bowel Issues Severity (1-10): \(entry.bowelIssuesSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.bowelIssuesSeverity) },
                            set: { entry.bowelIssuesSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Diarrhea / Constipation Notes", text: $entry.bowelIssues, axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Appetite Changes Severity (1-10): \(entry.appetiteChangesSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.appetiteChangesSeverity) },
                            set: { entry.appetiteChangesSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Appetite changes Notes", text: $entry.appetiteChanges, axis: .vertical)
                }
                
                // Skin / Extremities
                Section("Skin / Extremities") {
                    TextField("Alopecia (hair loss areas noticed today)", text: $entry.alopecia, axis: .vertical)
                    TextField("Foot Fungus (itching, cracking, redness)", text: $entry.footFungus, axis: .vertical)
                    TextField("Dry/Cracked Hands or Feet", text: $entry.dryHands, axis: .vertical)
                }
                
                // Musculoskeletal
                Section("Musculoskeletal") {
                    VStack(alignment: .leading) {
                        Text("Back Pain Severity (1-10): \(entry.backPainSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.backPainSeverity) },
                            set: { entry.backPainSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    VStack(alignment: .leading) {
                        Text("Neck/Shoulder Pain Severity (1-10): \(entry.neckShoulderPainSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.neckShoulderPainSeverity) },
                            set: { entry.neckShoulderPainSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Neck / Shoulder / Joint Pain Notes", text: $entry.neckShoulderPain, axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Flare-ups Severity (1-10): \(entry.flareUpsSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.flareUpsSeverity) },
                            set: { entry.flareUpsSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Flare-ups today Notes", text: $entry.flareUps, axis: .vertical)
                    VStack(alignment: .leading) {
                        Text("Limitations Severity (1-10): \(entry.limitationsSeverity)")
                        Slider(value: Binding(
                            get: { Double(entry.limitationsSeverity) },
                            set: { entry.limitationsSeverity = Int($0) }
                        ), in: 0...10, step: 1)
                    }
                    TextField("Limitations Notes (walking, sitting, lifting, daily activities)", text: $entry.limitations, axis: .vertical)
                }
                
                // Overall Daily Impact
                Section("Overall Daily Impact") {
                    TextField("Work/School Days Missed or Limited", text: $entry.workDaysMissed, axis: .vertical)
                    TextField("Activities I Couldn't Do Today", text: $entry.activitiesCouldntDo, axis: .vertical)
                    TextField("Treatments / Medications Used", text: $entry.treatmentsUsed, axis: .vertical)
                    TextField("Other Notes", text: $entry.otherNotes, axis: .vertical)
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                hideKeyboard()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isEditing = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dataManager.updateEntry(entry)
                        isEditing = false
                        showingSaveAlert = true
                    }
                }
            }
            .alert("Entry Updated", isPresented: $showingSaveAlert) {
                Button("OK") { }
            } message: {
                Text("Your symptom entry has been updated successfully.")
            }
        }
    }
}

// MARK: - Summary View
struct SummaryView: View {
    @EnvironmentObject var dataManager: SymptomDataManager
    @State private var selectedPeriod = 0
    
    private let periods = ["Week", "Month", "Year"]
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Time Period", selection: $selectedPeriod) {
                    ForEach(0..<periods.count, id: \.self) { index in
                        Text(periods[index])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                ScrollView {
                    let entries = getEntriesForPeriod()
                    
                    VStack(spacing: 20) {
                        // Summary Statistics
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Summary Statistics")
                                .font(.headline)
                                .padding(.leading)
                            
                            VStack(spacing: 8) {
                                HStack {
                            Text("Total Entries:")
                            Spacer()
                            Text("\(entries.count)")
                                .fontWeight(.semibold)
                        }
                        
                        if !entries.isEmpty {
                            AverageStatsView(entries: entries, selectedPeriod: selectedPeriod)
                        }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // Add Visual Chart Section
                        if !entries.isEmpty {
                            SymptomTrendsView(entries: entries, selectedPeriod: selectedPeriod)
                        }
                        
                        // Individual Entries List
                        Text("Recent Entries")
                            .font(.headline)
                            .padding(.leading)
                    }
                    
                    ForEach(entries) { entry in
                        NavigationLink(destination: EntryDetailView(entry: entry)) {
                            VStack(alignment: .leading) {
                                Text(entry.date, style: .date)
                                    .font(.headline)
                                HStack {
                                    if entry.headacheSeverity > 0 {
                                        Text("H: \(entry.headacheSeverity)")
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                    if entry.fatigueLevel > 0 {
                                        Text("F: \(entry.fatigueLevel)")
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                    if entry.backPainSeverity > 0 {
                                        Text("B: \(entry.backPainSeverity)")
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.purple.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                                .font(.caption)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("\(periods[selectedPeriod]) Summary")
        }
    }
    
    private func getEntriesForPeriod() -> [SymptomEntry] {
        switch selectedPeriod {
        case 0: return dataManager.getWeeklySummary()
        case 1: return dataManager.getMonthlySummary()
        case 2: return dataManager.getYearlySummary()
        default: return []
        }
    }
}

// MARK: - Average Stats Helper View
struct AverageStatsView: View {
    let entries: [SymptomEntry]
    let selectedPeriod: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Text(getStatsTitle())
                .font(.headline)
                .padding(.bottom, 4)
            
            if !entries.isEmpty {
                let avgHeadache = entries.map { $0.headacheSeverity }.reduce(0, +) / entries.count
                let avgFatigue = entries.map { $0.fatigueLevel }.reduce(0, +) / entries.count
                let avgBackPain = entries.map { $0.backPainSeverity }.reduce(0, +) / entries.count
                let avgMood = entries.map { $0.moodSeverity }.reduce(0, +) / entries.count
                
                VStack(spacing: 8) {
                    StatRow(label: "Headache Severity", value: avgHeadache, color: .red)
                    StatRow(label: "Fatigue Level", value: avgFatigue, color: .orange)
                    StatRow(label: "Back Pain Severity", value: avgBackPain, color: .purple)
                    StatRow(label: "Mood Severity", value: avgMood, color: .blue)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Additional stats
                HStack {
                    VStack {
                        Text("\(entries.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(getEntryCountLabel())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text(getDateRangeText())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
            } else {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    private func getStatsTitle() -> String {
        switch selectedPeriod {
        case 0: return "Weekly Summary"
        case 1: return "Monthly Summary"
        case 2: return "Yearly Summary"
        default: return "Summary Statistics"
        }
    }
    
    private func getEntryCountLabel() -> String {
        switch selectedPeriod {
        case 0: return "entries this week"
        case 1: return "entries this month"
        case 2: return "entries this year"
        default: return "entries"
        }
    }
    
    private func getDateRangeText() -> String {
        guard !entries.isEmpty else { return "" }
        
        let sortedEntries = entries.sorted { $0.date < $1.date }
        let firstDate = sortedEntries.first?.date ?? Date()
        let lastDate = sortedEntries.last?.date ?? Date()
        
        if Calendar.current.isDate(firstDate, inSameDayAs: lastDate) {
            return firstDate.formatted(.dateTime.month().day().year())
        } else {
            return "\(firstDate.formatted(.dateTime.month(.abbreviated).day())) - \(lastDate.formatted(.dateTime.month(.abbreviated).day().year()))"
        }
    }
}

struct StatRow: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(color.opacity(0.8))
                    .frame(width: 8, height: 8)
                Text("Avg \(label):")
            }
            Spacer()
            HStack(spacing: 4) {
                Text("\(value)")
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                Text("/10")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Symptom Trends Chart View
struct SymptomTrendsView: View {
    let entries: [SymptomEntry]
    let selectedPeriod: Int
    
    var body: some View {
        let chartData = getChartData()
        
        VStack(spacing: 16) {
            Text(getChartTitle())
                .font(.headline)
            
            if !chartData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LineChartView(data: chartData, selectedPeriod: selectedPeriod)
                        .frame(height: 200)
                        .padding(.horizontal)
                }
                
                // Chart legend
                VStack(spacing: 8) {
                    HStack(spacing: 20) {
                        ChartLegendItem(color: .red, label: "Headache")
                        ChartLegendItem(color: .orange, label: "Fatigue")
                    }
                    HStack(spacing: 20) {
                        ChartLegendItem(color: .purple, label: "Back Pain")
                        ChartLegendItem(color: .blue, label: "Mood")
                    }
                }
                .padding(.top, 8)
            } else {
                Text("No data available for selected period")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding(.horizontal)
    }
    
    private func getChartData() -> [ChartDataPoint] {
        let sortedEntries = entries.sorted { $0.date < $1.date }
        
        switch selectedPeriod {
        case 0: // Week - show last 7 days
            let recent = Array(sortedEntries.suffix(7))
            return recent.map { entry in
                ChartDataPoint(
                    date: entry.date,
                    headache: entry.headacheSeverity,
                    fatigue: entry.fatigueLevel,
                    backPain: entry.backPainSeverity,
                    mood: entry.moodSeverity
                )
            }
        case 1: // Month - show weekly averages for last 4 weeks
            return getWeeklyAverages(from: sortedEntries, weeks: 4)
        case 2: // Year - show monthly averages for last 12 months
            return getMonthlyAverages(from: sortedEntries, months: 12)
        default:
            return []
        }
    }
    
    private func getWeeklyAverages(from entries: [SymptomEntry], weeks: Int) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        var dataPoints: [ChartDataPoint] = []
        
        for week in 0..<weeks {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -week, to: endDate) ?? endDate
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? endDate
            
            let weekEntries = entries.filter { entry in
                entry.date >= weekStart && entry.date <= weekEnd
            }
            
            if !weekEntries.isEmpty {
                let avgHeadache = weekEntries.map { $0.headacheSeverity }.reduce(0, +) / weekEntries.count
                let avgFatigue = weekEntries.map { $0.fatigueLevel }.reduce(0, +) / weekEntries.count
                let avgBackPain = weekEntries.map { $0.backPainSeverity }.reduce(0, +) / weekEntries.count
                let avgMood = weekEntries.map { $0.moodSeverity }.reduce(0, +) / weekEntries.count
                
                dataPoints.append(ChartDataPoint(
                    date: weekStart,
                    headache: avgHeadache,
                    fatigue: avgFatigue,
                    backPain: avgBackPain,
                    mood: avgMood
                ))
            }
        }
        
        return dataPoints.reversed()
    }
    
    private func getMonthlyAverages(from entries: [SymptomEntry], months: Int) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        var dataPoints: [ChartDataPoint] = []
        
        for month in 0..<months {
            let monthStart = calendar.date(byAdding: .month, value: -month, to: endDate) ?? endDate
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? endDate
            
            let monthEntries = entries.filter { entry in
                entry.date >= monthStart && entry.date < monthEnd
            }
            
            if !monthEntries.isEmpty {
                let avgHeadache = monthEntries.map { $0.headacheSeverity }.reduce(0, +) / monthEntries.count
                let avgFatigue = monthEntries.map { $0.fatigueLevel }.reduce(0, +) / monthEntries.count
                let avgBackPain = monthEntries.map { $0.backPainSeverity }.reduce(0, +) / monthEntries.count
                let avgMood = monthEntries.map { $0.moodSeverity }.reduce(0, +) / monthEntries.count
                
                dataPoints.append(ChartDataPoint(
                    date: monthStart,
                    headache: avgHeadache,
                    fatigue: avgFatigue,
                    backPain: avgBackPain,
                    mood: avgMood
                ))
            }
        }
        
        return dataPoints.reversed()
    }
    
    private func getChartTitle() -> String {
        switch selectedPeriod {
        case 0: return "Daily Symptoms (Last 7 Days)"
        case 1: return "Weekly Averages (Last 4 Weeks)"
        case 2: return "Monthly Averages (Last 12 Months)"
        default: return "Symptom Trends"
        }
    }
    
    private func formatDateLabel(_ date: Date) -> String {
        switch selectedPeriod {
        case 0: // Daily
            return date.formatted(.dateTime.month(.abbreviated).day())
        case 1: // Weekly
            return "Week\n" + date.formatted(.dateTime.month(.abbreviated).day())
        case 2: // Monthly
            return date.formatted(.dateTime.month(.abbreviated).year(.twoDigits))
        default:
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }
}

// MARK: - Chart Data Models
struct ChartDataPoint {
    let date: Date
    let headache: Int
    let fatigue: Int
    let backPain: Int
    let mood: Int
}

struct ChartLegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(color.opacity(0.8))
                .frame(width: 12, height: 8)
                .cornerRadius(2)
            Text(label)
                .font(.caption2)
        }
    }
}

// MARK: - Line Chart View
struct LineChartView: View {
    let data: [ChartDataPoint]
    let selectedPeriod: Int
    
    private let chartHeight: CGFloat = 160
    private let maxValue: CGFloat = 10
    private let pointRadius: CGFloat = 4
    
    var body: some View {
        let chartPadding: CGFloat = 40
        let topPadding: CGFloat = 20
        let bottomPadding: CGFloat = 40
        let availableWidth = max(CGFloat(data.count) * 80, 300) - (chartPadding * 2)
        let totalWidth = availableWidth + (chartPadding * 2)
        let totalHeight = chartHeight + topPadding + bottomPadding
        
        ZStack {
            // Background grid
            GridLinesView(chartHeight: chartHeight, maxValue: maxValue, totalWidth: totalWidth, topPadding: topPadding)
            
            // Line charts for each symptom
            LineView(points: data.map { CGPoint(x: getXPosition(for: $0, availableWidth: availableWidth) + chartPadding, y: getYPosition(for: $0.headache, topPadding: topPadding)) },
                    color: .red, totalWidth: totalWidth)
            
            LineView(points: data.map { CGPoint(x: getXPosition(for: $0, availableWidth: availableWidth) + chartPadding, y: getYPosition(for: $0.fatigue, topPadding: topPadding)) },
                    color: .orange, totalWidth: totalWidth)
            
            LineView(points: data.map { CGPoint(x: getXPosition(for: $0, availableWidth: availableWidth) + chartPadding, y: getYPosition(for: $0.backPain, topPadding: topPadding)) },
                    color: .purple, totalWidth: totalWidth)
            
            LineView(points: data.map { CGPoint(x: getXPosition(for: $0, availableWidth: availableWidth) + chartPadding, y: getYPosition(for: $0.mood, topPadding: topPadding)) },
                    color: .blue, totalWidth: totalWidth)
            
            // Data points and labels
            ForEach(Array(data.enumerated()), id: \.offset) { index, dataPoint in
                let xPos = getXPosition(for: dataPoint, availableWidth: availableWidth) + chartPadding
                
                ZStack {
                    // Data points for each symptom
                    if dataPoint.headache > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: pointRadius * 2, height: pointRadius * 2)
                            .position(x: xPos, y: getYPosition(for: dataPoint.headache, topPadding: topPadding))
                    }
                    
                    if dataPoint.fatigue > 0 {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: pointRadius * 2, height: pointRadius * 2)
                            .position(x: xPos, y: getYPosition(for: dataPoint.fatigue, topPadding: topPadding))
                    }
                    
                    if dataPoint.backPain > 0 {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: pointRadius * 2, height: pointRadius * 2)
                            .position(x: xPos, y: getYPosition(for: dataPoint.backPain, topPadding: topPadding))
                    }
                    
                    if dataPoint.mood > 0 {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: pointRadius * 2, height: pointRadius * 2)
                            .position(x: xPos, y: getYPosition(for: dataPoint.mood, topPadding: topPadding))
                    }
                    
                    // Date label
                    Text(formatDateLabel(dataPoint.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(width: 70)
                        .position(x: xPos, y: chartHeight + topPadding + 20)
                }
            }
        }
        .frame(width: totalWidth, height: totalHeight)
    }
    
    private func getXPosition(for dataPoint: ChartDataPoint, availableWidth: CGFloat) -> CGFloat {
        guard data.count > 1 else { return availableWidth / 2 }
        
        if let index = data.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: dataPoint.date) }) {
            let spacing = availableWidth / CGFloat(max(data.count - 1, 1))
            return spacing * CGFloat(index)
        }
        return 0
    }
    
    private func getYPosition(for value: Int, topPadding: CGFloat) -> CGFloat {
        return topPadding + chartHeight - (CGFloat(value) / maxValue * chartHeight)
    }
    
    private func formatDateLabel(_ date: Date) -> String {
        switch selectedPeriod {
        case 0: // Daily
            return date.formatted(.dateTime.month(.abbreviated).day())
        case 1: // Weekly
            return "Week\n" + date.formatted(.dateTime.month(.abbreviated).day())
        case 2: // Monthly
            return date.formatted(.dateTime.month(.abbreviated).year(.twoDigits))
        default:
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }
}

// MARK: - Grid Lines View
struct GridLinesView: View {
    let chartHeight: CGFloat
    let maxValue: CGFloat
    let totalWidth: CGFloat
    let topPadding: CGFloat
    
    var body: some View {
        ZStack {
            // Horizontal grid lines
            ForEach(0..<6) { i in
                let y = topPadding + chartHeight - (CGFloat(i) * chartHeight / 5)
                Path { path in
                    path.move(to: CGPoint(x: 20, y: y))
                    path.addLine(to: CGPoint(x: totalWidth - 20, y: y))
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                
                // Y-axis labels
                Text("\(Int(maxValue * CGFloat(i) / 5))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .position(x: 15, y: y)
            }
        }
    }
}

// MARK: - Line View
struct LineView: View {
    let points: [CGPoint]
    let color: Color
    let totalWidth: CGFloat
    
    var body: some View {
        Path { path in
            guard points.count > 1 else { return }
            
            // Only connect points that have non-zero values
            let validPoints = points.filter { point in
                // Check if this point represents a non-zero value by checking Y position
                // Since we added topPadding, adjust the threshold accordingly
                point.y < (160 + 20) // chartHeight + topPadding, so y < this means value > 0
            }
            
            guard validPoints.count > 1 else { return }
            
            path.move(to: validPoints[0])
            for point in validPoints.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(color.opacity(0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        .frame(width: totalWidth)
    }
}

// MARK: - Bar View Helper
struct BarView: View {
    let value: Int
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(color)
            
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 20, height: 40)
                
                Rectangle()
                    .fill(color.opacity(0.8))
                    .frame(width: 20, height: CGFloat(value) * 4.0) // Scale: 10 = 40px height
            }
            .cornerRadius(2)
            
            Text(value > 0 ? "\(value)" : "")
                .font(.caption2)
                .foregroundColor(value > 0 ? .primary : .clear)
        }
    }
}

// MARK: - Authentication Manager
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var hasSetupPIN = false
    @Published var showingPINSetup = false
    @Published var showingPINEntry = false
    
    private let keychain = KeychainHelper()
    
    init() {
        checkPINSetup()
    }
    
    func checkPINSetup() {
        hasSetupPIN = keychain.getPIN() != nil
    }
    
    func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
            showingPINEntry = true
            return
        }
        
        let reason = "Access your health symptom data securely"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthenticated = true
                } else {
                    // Handle different authentication errors
                    if let error = authenticationError as? LAError {
                        switch error.code {
                        case .userCancel, .userFallback:
                            // User chose to use PIN instead
                            self?.showingPINEntry = true
                        case .biometryNotAvailable, .biometryNotEnrolled, .biometryLockout:
                            // Biometry not available, fallback to PIN
                            self?.showingPINEntry = true
                        default:
                            // Other errors, fallback to PIN
                            print("Biometric authentication error: \(error.localizedDescription)")
                            self?.showingPINEntry = true
                        }
                    } else {
                        // Fallback to PIN if biometrics fail
                        self?.showingPINEntry = true
                    }
                }
            }
        }
    }
    
    func setupPIN(_ pin: String) {
        keychain.savePIN(pin)
        hasSetupPIN = true
        showingPINSetup = false
        isAuthenticated = true
    }
    
    func authenticateWithPIN(_ pin: String) -> Bool {
        if let storedPIN = keychain.getPIN(), storedPIN == pin {
            isAuthenticated = true
            showingPINEntry = false
            return true
        }
        return false
    }
    
    func logout() {
        isAuthenticated = false
    }
}

// MARK: - Keychain Helper
class KeychainHelper {
    private let service = "SymptomTrackerApp"
    private let account = "UserPIN"
    
    func savePIN(_ pin: String) {
        let data = Data(pin.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getPIN() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }
}

// MARK: - Authentication Views
struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainAppView()
                    .environmentObject(authManager)
            } else if !authManager.hasSetupPIN {
                PINSetupView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            // Only attempt biometric authentication if PIN is already set up
            // and we're not in an error state
            if authManager.hasSetupPIN && !authManager.showingPINEntry {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authManager.authenticateWithBiometrics()
                }
            }
        }
    }
}

struct PINSetupView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var pin = ""
    @State private var confirmPIN = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 10) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Secure Your Health Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Set up a 4-digit PIN to protect your symptom tracking data")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                SecureField("Enter 4-digit PIN", text: $pin)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 200)
                
                SecureField("Confirm PIN", text: $confirmPIN)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 200)
            }
            
            Button("Set PIN") {
                setupPIN()
            }
            .buttonStyle(.borderedProminent)
            .disabled(pin.count != 4 || confirmPIN.count != 4)
            
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }
    
    private func setupPIN() {
        guard pin.count == 4, confirmPIN.count == 4 else {
            errorMessage = "PIN must be 4 digits"
            showError = true
            return
        }
        
        guard pin == confirmPIN else {
            errorMessage = "PINs don't match"
            showError = true
            return
        }
        
        guard pin.allSatisfy({ $0.isNumber }) else {
            errorMessage = "PIN must contain only numbers"
            showError = true
            return
        }
        
        authManager.setupPIN(pin)
    }
}

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var enteredPIN = ""
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 10) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Symptom Tracker")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Enter your PIN or use biometric authentication")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                SecureField("Enter PIN", text: $enteredPIN)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 200)
                    .onSubmit {
                        authenticateWithPIN()
                    }
                
                Button("Unlock") {
                    authenticateWithPIN()
                }
                .buttonStyle(.borderedProminent)
                .disabled(enteredPIN.count != 4)
                
                Button("Use Biometric Authentication") {
                    authManager.authenticateWithBiometrics()
                }
                .buttonStyle(.bordered)
            }
            
            if showError {
                Text("Incorrect PIN")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .onAppear {
            // Only try biometrics if we're not already showing PIN entry
            if !authManager.showingPINEntry {
                authManager.authenticateWithBiometrics()
            }
        }
    }
    
    private func authenticateWithPIN() {
        if !authManager.authenticateWithPIN(enteredPIN) {
            showError = true
            enteredPIN = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showError = false
            }
        }
    }
}

struct MainAppView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        TabView {
            TrackerMainView()
                .tabItem {
                    Image(systemName: "heart.text.square")
                    Text("Tracker")
                }
            
            HelpView()
                .tabItem {
                    Image(systemName: "questionmark.circle")
                    Text("Help")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}

// MARK: - Tracker Main View with Subitems
struct TrackerMainView: View {
    @State private var selectedTrackerTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Segmented Control for Tracker Subitems
                HStack(spacing: 0) {
                    ForEach(0..<4) { index in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTrackerTab = index
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: getTabIcon(for: index))
                                    .font(.system(size: 16, weight: .medium))
                                Text(getTabTitle(for: index))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(selectedTrackerTab == index ? .blue : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedTrackerTab == index ? Color.blue.opacity(0.1) : Color.clear)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Content based on selection
                TabView(selection: $selectedTrackerTab) {
                    DailyLogView()
                        .tag(0)
                    
                    EntryListView()
                        .tag(1)
                    
                    SummaryView()
                        .tag(2)
                    
                    ExportView()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle(getNavigationTitle())
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func getNavigationTitle() -> String {
        switch selectedTrackerTab {
        case 0: return "New Entry"
        case 1: return "Entry History"
        case 2: return "Summary & Trends"
        case 3: return "Export Data"
        default: return "Symptom Tracker"
        }
    }
    
    private func getTabIcon(for index: Int) -> String {
        switch index {
        case 0: return "plus.circle.fill"
        case 1: return "list.bullet.rectangle"
        case 2: return "chart.line.uptrend.xyaxis"
        case 3: return "square.and.arrow.up"
        default: return "questionmark"
        }
    }
    
    private func getTabTitle(for index: Int) -> String {
        switch index {
        case 0: return "New"
        case 1: return "List"
        case 2: return "Stats"
        case 3: return "Export"
        default: return ""
        }
    }
}

// MARK: - Help View
struct HelpView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // App Overview
                    HelpSection(title: "About Symptom Tracker", icon: "heart.text.square") {
                        Text("Symptom Tracker is a secure, private health application designed to help you log and monitor your daily symptoms for medical reporting, particularly for VA (Veterans Affairs) documentation.")
                    }
                    
                    // Key Features
                    HelpSection(title: "Key Features", icon: "star") {
                        VStack(alignment: .leading, spacing: 8) {
                            HelpFeature(icon: "slider.horizontal.3", title: "Severity Tracking", description: "Rate symptom severity on a 0-10 scale")
                            HelpFeature(icon: "square.and.pencil", title: "Draft Saving", description: "Save progress throughout the day and edit previous entries")
                            HelpFeature(icon: "doc.text", title: "PDF Export", description: "Export individual logs, summaries, and date ranges")
                            HelpFeature(icon: "chart.line.uptrend.xyaxis", title: "Trend Analysis", description: "View symptom trends with interactive charts")
                            HelpFeature(icon: "lock.shield", title: "Secure Access", description: "Protected with PIN and biometric authentication")
                        }
                    }
                    
                    // How to Use
                    HelpSection(title: "How to Use", icon: "book") {
                        VStack(alignment: .leading, spacing: 12) {
                            HelpStep(number: 1, text: "Navigate to 'Daily Log' to record today's symptoms")
                            HelpStep(number: 2, text: "Use severity sliders to rate each symptom from 0-10")
                            HelpStep(number: 3, text: "Add detailed notes for context")
                            HelpStep(number: 4, text: "Save drafts to continue logging throughout the day")
                            HelpStep(number: 5, text: "View 'Entry List' to see all previous entries")
                            HelpStep(number: 6, text: "Edit past entries by tapping on them")
                            HelpStep(number: 7, text: "Check 'Summary' for trends and statistics")
                            HelpStep(number: 8, text: "Export data as PDF from the 'Export' tab")
                        }
                    }
                    
                    // Privacy Notice
                    HelpSection(title: "Privacy & Security", icon: "lock.shield.fill") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your health data privacy is our top priority:")
                                .fontWeight(.semibold)
                            
                            PrivacyPoint(text: "All data is stored locally on your device only")
                            PrivacyPoint(text: "No data is transmitted to external servers")
                            PrivacyPoint(text: "No analytics, tracking, or data collection")
                            PrivacyPoint(text: "App is protected with PIN and biometric authentication")
                            PrivacyPoint(text: "Data is encrypted using iOS security features")
                            PrivacyPoint(text: "You have complete control over your data")
                            
                            Text("Data Usage:")
                                .fontWeight(.semibold)
                                .padding(.top, 8)
                            
                            Text("• No personal health information leaves your device\n• No third-party data sharing\n• No cloud storage or backup (unless you manually export)\n• No advertising or marketing use of your data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Export Information
                    HelpSection(title: "Exporting Data", icon: "square.and.arrow.up") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Export your symptom data for medical appointments:")
                            Text("• Individual daily logs as PDF")
                            Text("• Summary reports with statistics")
                            Text("• Custom date range exports")
                            Text("• Professional formatting for healthcare providers")
                        }
                        .font(.caption)
                    }
                    
                    // Support Information
                    HelpSection(title: "Support", icon: "lifepreserver") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("For technical support, feature requests, or bug reports:")
                            Link("Visit our Support Page", destination: URL(string: "https://stovalldav.github.io/SymptomTrackerSupport/")!)
                                .foregroundColor(.blue)
                            
                            Text("Contact us directly:")
                                .padding(.top, 8)
                            Link("symptomtrackerinfo@gmail.com", destination: URL(string: "mailto:symptomtrackerinfo@gmail.com")!)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Help & Privacy")
        }
    }
}

struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            content
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HelpFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct HelpStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 20, height: 20)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
            
            Text(text)
                .font(.caption)
        }
    }
}

struct PrivacyPoint: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            
            Text(text)
                .font(.caption)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingChangePIN = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Security") {
                    Button("Change PIN") {
                        showingChangePIN = true
                    }
                    
                    Button("Logout", role: .destructive) {
                        showingLogoutAlert = true
                    }
                }
                
                Section("App Information") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("100")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingChangePIN) {
            ChangePINView()
                .environmentObject(authManager)
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("Are you sure you want to logout? You'll need to authenticate again to access your data.")
        }
    }
}

struct ChangePINView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentPIN = ""
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 15) {
                    SecureField("Current PIN", text: $currentPIN)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    SecureField("New PIN", text: $newPIN)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    SecureField("Confirm New PIN", text: $confirmPIN)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Change PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        changePIN()
                    }
                    .disabled(currentPIN.count != 4 || newPIN.count != 4 || confirmPIN.count != 4)
                }
            }
        }
    }
    
    private func changePIN() {
        guard newPIN == confirmPIN else {
            errorMessage = "New PINs don't match"
            showError = true
            return
        }
        
        guard newPIN.allSatisfy({ $0.isNumber }) else {
            errorMessage = "PIN must contain only numbers"
            showError = true
            return
        }
        
        // Verify current PIN
        let keychain = KeychainHelper()
        guard let storedPIN = keychain.getPIN(), storedPIN == currentPIN else {
            errorMessage = "Current PIN is incorrect"
            showError = true
            return
        }
        
        // Save new PIN
        keychain.savePIN(newPIN)
        dismiss()
    }
}

// MARK: - Export View
struct ExportView: View {
    @EnvironmentObject var dataManager: SymptomDataManager
    @State private var showingShareSheet = false
    @State private var csvContent = ""
    @State private var pdfData = Data()
    @State private var selectedPeriod = 0
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var showingDatePickers = false
    private let periods = ["Week", "Month", "Year", "All Time", "Custom Range"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Export Your Data")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Export your symptom entries as CSV or PDF files that you can share with healthcare providers.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Period Selection for PDF Summary
                VStack(alignment: .leading) {
                    Text("Export Period:")
                        .font(.headline)
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(0..<periods.count, id: \.self) { index in
                            Text(periods[index])
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Custom date range pickers
                    if selectedPeriod == 4 { // Custom Range
                        VStack(spacing: 12) {
                            HStack {
                                Text("From:")
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            HStack {
                                Text("To:")
                                DatePicker("", selection: $endDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("All symptom categories included")
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Date and severity ratings")
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Professional PDF reports")
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Ready for VA reporting")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Export Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        pdfData = Data() // Reset PDF data
                        csvContent = dataManager.exportToCSV()
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "tablecells")
                            Text("Export as CSV")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        csvContent = "" // Reset CSV content
                        let entries = getEntriesForPeriod()
                        print("Summary PDF: Exporting \(entries.count) entries for period: \(getPeriodTitle())")
                        pdfData = dataManager.generateSummaryPDF(for: getPeriodTitle(), entries: entries)
                        print("Summary PDF: Generated PDF data size: \(pdfData.count) bytes")
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "chart.bar.doc.horizontal")
                            Text("Export Summary PDF")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        csvContent = "" // Reset CSV content
                        let entries = getEntriesForPeriod()
                        print("Detailed PDF: Exporting \(entries.count) entries for period: \(getPeriodTitle())")
                        pdfData = dataManager.generateDetailedEntriesPDF(for: entries, title: "Detailed Symptom Report - \(getPeriodTitle())")
                        print("Detailed PDF: Generated PDF data size: \(pdfData.count) bytes")
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("Export Detailed PDF")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                VStack(spacing: 8) {
                    Text("Total Entries: \(dataManager.entries.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Force Save Data") {
                        dataManager.saveEntries()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .sheet(isPresented: $showingShareSheet) {
                if !csvContent.isEmpty {
                    ShareSheet(activityItems: [csvContent])
                } else if !pdfData.isEmpty {
                    let tempURL = createTempPDFFile(data: pdfData)
                    ShareSheet(activityItems: [tempURL])
                } else {
                    ShareSheet(activityItems: ["No data to export"])
                }
            }
        }
    }
    
    private func getEntriesForPeriod() -> [SymptomEntry] {
        switch selectedPeriod {
        case 0: return dataManager.getWeeklySummary()
        case 1: return dataManager.getMonthlySummary()
        case 2: return dataManager.getYearlySummary()
        case 3: return dataManager.entries
        case 4: // Custom Range
            return dataManager.entries.filter { entry in
                let calendar = Calendar.current
                let entryDate = calendar.startOfDay(for: entry.date)
                let start = calendar.startOfDay(for: startDate)
                let end = calendar.startOfDay(for: endDate)
                return entryDate >= start && entryDate <= end
            }
        default: return []
        }
    }
    
    private func getPeriodTitle() -> String {
        switch selectedPeriod {
        case 0: return "Week"
        case 1: return "Month"
        case 2: return "Year"
        case 3: return "All Time"
        case 4:
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "\(formatter.string(from: startDate)) to \(formatter.string(from: endDate))"
        default: return "Unknown"
        }
    }
    
    private func createTempPDFFile(data: Data) -> URL {
        let fileName = "SymptomReport-\(getPeriodTitle().replacingOccurrences(of: "/", with: "-")).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            print("Created temp PDF file at: \(tempURL.path)")
        } catch {
            print("Failed to write PDF to temp file: \(error)")
        }
        
        return tempURL
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Keyboard Dismissal Extension
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
