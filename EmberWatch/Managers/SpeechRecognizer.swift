import AVFoundation
import Speech
import SwiftUI

/// On-device-when-available speech recognition for food, workout, and weight voice entry.
@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published private(set) var transcript: String = ""
    @Published private(set) var completedTranscript: String = ""
    @Published private(set) var isListening: Bool = false
    @Published var errorMessage: String?

    private let speechRecognizer: SFSpeechRecognizer?
    private let recognitionRelay = RecognitionRelay()
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var silenceTask: Task<Void, Never>?
    private var maxDurationTask: Task<Void, Never>?

    init() {
        let preferred = Locale(identifier: "en-US")
        if let recognizer = SFSpeechRecognizer(locale: preferred) {
            speechRecognizer = recognizer
        } else {
            speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        }
        recognitionRelay.owner = self
    }

    func toggleListening() {
        if isListening {
            stopListening()
            return
        }
        Task { @MainActor in
            await startListening()
        }
    }

    func startListening() async {
        errorMessage = nil
        transcript = ""
        completedTranscript = ""

        let permitted = await Self.ensurePermissions()
        if !permitted {
            errorMessage = "Allow Microphone and Speech Recognition in Settings to log by voice."
            return
        }

        do {
            try beginEngine()
            isListening = true
            scheduleMaxDurationStop()
        } catch {
            errorMessage = "Could not start listening. Try again."
            resetSession()
        }
    }

    func stopListening() {
        let spoken = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        resetSession()
        if !spoken.isEmpty {
            completedTranscript = spoken
        }
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Permissions

    nonisolated private static func ensurePermissions() async -> Bool {
        let speechOK = await speechAuthorized()
        if !speechOK {
            return false
        }
        let micOK = await microphoneAuthorized()
        return micOK
    }

    nonisolated private static func speechAuthorized() async -> Bool {
        let current = SFSpeechRecognizer.authorizationStatus()
        switch current {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            break
        @unknown default:
            return false
        }

        let status: SFSpeechRecognizerAuthorizationStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { newStatus in
                continuation.resume(returning: newStatus)
            }
        }
        return status == .authorized
    }

    nonisolated private static func microphoneAuthorized() async -> Bool {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            break
        @unknown default:
            return false
        }

        let granted: Bool = await withCheckedContinuation { continuation in
            session.requestRecordPermission { value in
                continuation.resume(returning: value)
            }
        }
        return granted
    }

    // MARK: - Engine

    private func beginEngine() throws {
        resetSession()

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw SpeechStartError.unavailable
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request
        let requestBox = AudioRequestBox(request: request)

        let engine = AVAudioEngine()
        audioEngine = engine
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            requestBox.append(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            audioEngine = nil
            recognitionRequest = nil
            throw error
        }

        let relay = recognitionRelay
        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            let spoken: String
            if let result {
                spoken = result.bestTranscription.formattedString
            } else {
                spoken = ""
            }
            let isFinal = result?.isFinal ?? false
            let failed = error != nil && spoken.isEmpty
            relay.deliver(spoken: spoken, isFinal: isFinal, failed: failed)
        }
    }

    fileprivate func handleRecognition(spoken: String, isFinal: Bool, failed: Bool) {
        guard isListening else { return }
        if failed {
            errorMessage = "Could not understand that. Try again."
            resetSession()
            return
        }
        if !spoken.isEmpty {
            transcript = spoken
            scheduleSilenceStop()
        }
        if isFinal {
            stopListening()
        }
    }

    private func resetSession() {
        silenceTask?.cancel()
        silenceTask = nil
        maxDurationTask?.cancel()
        maxDurationTask = nil

        isListening = false

        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        if let engine = audioEngine {
            if engine.isRunning {
                engine.stop()
            }
            engine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil

        deactivateAudioSession()
    }

    private func deactivateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Another session may still be using audio.
        }
    }

    private func scheduleSilenceStop() {
        silenceTask?.cancel()
        silenceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            guard !Task.isCancelled else { return }
            guard self.isListening else { return }
            let text = self.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                self.stopListening()
            }
        }
    }

    private func scheduleMaxDurationStop() {
        maxDurationTask?.cancel()
        maxDurationTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 15_000_000_000)
            guard !Task.isCancelled else { return }
            guard self.isListening else { return }
            self.stopListening()
        }
    }
}

private enum SpeechStartError: Error {
    case unavailable
}

/// Sendable wrapper so the audio tap does not capture `SFSpeechAudioBufferRecognitionRequest` directly.
private final class AudioRequestBox: @unchecked Sendable {
    let request: SFSpeechAudioBufferRecognitionRequest

    init(request: SFSpeechAudioBufferRecognitionRequest) {
        self.request = request
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        request.append(buffer)
    }
}

/// Sendable hop from the Speech recognition callback onto the main actor.
private final class RecognitionRelay: @unchecked Sendable {
    weak var owner: SpeechRecognizer?

    func deliver(spoken: String, isFinal: Bool, failed: Bool) {
        Task { @MainActor in
            self.owner?.handleRecognition(spoken: spoken, isFinal: isFinal, failed: failed)
        }
    }
}

// MARK: - Mic button

struct SpeechMicButton: View {
    @ObservedObject var recognizer: SpeechRecognizer
    let accessibilityName: String

    @State private var pulseOn = false

    var body: some View {
        Button {
            recognizer.toggleListening()
        } label: {
            Image(systemName: recognizer.isListening ? "mic.fill" : "mic")
                .font(.body.weight(.semibold))
                .foregroundColor(micColor)
                .scaleEffect(pulseOn ? 1.18 : 1.0)
                .opacity(pulseOn ? 0.7 : 1.0)
                .padding(6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(recognizer.isListening ? "Stop listening" : accessibilityName)
        .accessibilityHint("Speak to fill this field")
        .onChange(of: recognizer.isListening) { _, listening in
            updatePulse(listening)
        }
        .onAppear {
            updatePulse(recognizer.isListening)
        }
    }

    private var micColor: Color {
        if recognizer.isListening {
            return EmberColors.ember
        }
        return EmberColors.cream.opacity(0.65)
    }

    private func updatePulse(_ listening: Bool) {
        if listening {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                pulseOn = true
            }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                pulseOn = false
            }
        }
    }
}

extension View {
    func speechPermissionAlert(_ recognizer: SpeechRecognizer) -> some View {
        alert(
            "Voice entry unavailable",
            isPresented: Binding(
                get: { recognizer.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        recognizer.clearError()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                recognizer.clearError()
            }
        } message: {
            Text(recognizer.errorMessage ?? "")
        }
    }
}

// MARK: - Transcript parsers

enum SpokenFoodParser {
    /// Splits a spoken food phrase on commas and "and" so the user can pick a query.
    static func queries(from transcript: String) -> [String] {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return []
        }

        var chunks: [String] = []
        let commaParts = trimmed.split(separator: ",", omittingEmptySubsequences: true)
        for commaPart in commaParts {
            let andParts = splitOnAnd(String(commaPart))
            for part in andParts {
                let item = part.trimmingCharacters(in: .whitespacesAndNewlines)
                if item.count >= 2 {
                    chunks.append(item)
                }
            }
        }

        if chunks.isEmpty {
            return [trimmed]
        }
        return chunks
    }

    private static func splitOnAnd(_ text: String) -> [String] {
        let lowered = text.lowercased()
        var ranges: [Range<String.Index>] = []
        var searchStart = lowered.startIndex
        while searchStart < lowered.endIndex {
            if let found = lowered.range(of: " and ", range: searchStart..<lowered.endIndex) {
                ranges.append(found)
                searchStart = found.upperBound
            } else {
                break
            }
        }

        if ranges.isEmpty {
            return [text]
        }

        var parts: [String] = []
        var cursor = text.startIndex
        for range in ranges {
            parts.append(String(text[cursor..<range.lowerBound]))
            cursor = range.upperBound
        }
        parts.append(String(text[cursor..<text.endIndex]))
        return parts
    }
}

enum SpokenWorkoutParser {
    struct ParsedWorkout: Sendable {
        let exerciseID: String
        let minutes: Int
        let calories: Double?
    }

    static func parse(_ transcript: String) -> ParsedWorkout? {
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if text.isEmpty {
            return nil
        }
        let exerciseID = matchExercise(in: text) ?? "other"
        let minutes = matchMinutes(in: text) ?? 30
        let calories = matchCalories(in: text)
        return ParsedWorkout(
            exerciseID: exerciseID,
            minutes: max(1, minutes),
            calories: calories
        )
    }

    private static func matchExercise(in text: String) -> String? {
        if containsAny(text, ["indoor run", "indoor running", "treadmill"]) {
            return "indoor-run"
        }
        if containsAny(text, ["outdoor run", "outdoor running"]) {
            return "outdoor-run"
        }
        if containsAny(text, ["ran", "run", "running", "jog", "jogging"]) {
            return "outdoor-run"
        }
        if containsAny(text, ["indoor walk", "indoor walking"]) {
            return "indoor-walk"
        }
        if containsAny(text, ["outdoor walk", "outdoor walking"]) {
            return "outdoor-walk"
        }
        if containsAny(text, ["walked", "walk", "walking"]) {
            return "outdoor-walk"
        }
        if containsAny(text, ["indoor cycle", "indoor bike", "spin"]) {
            return "indoor-cycle"
        }
        if containsAny(text, ["outdoor cycle", "outdoor bike"]) {
            return "outdoor-cycle"
        }
        if containsAny(text, ["cycled", "cycling", "cycle", "biked", "biking", "bike"]) {
            return "outdoor-cycle"
        }
        if containsAny(text, ["open water", "open-water"]) {
            return "open-water-swim"
        }
        if containsAny(text, ["pool swim", "laps"]) {
            return "pool-swim"
        }
        if containsAny(text, ["swam", "swim", "swimming"]) {
            return "pool-swim"
        }
        if containsAny(text, ["weightlifting", "weight lifting", "weights", "lifting", "strength", "dumbbell"]) {
            return "strength"
        }
        if containsAny(text, ["hiit", "high intensity", "interval training"]) {
            return "hiit"
        }
        if text.contains("yoga") {
            return "yoga"
        }
        if text.contains("elliptical") {
            return "elliptical"
        }
        if containsAny(text, ["hike", "hiking"]) {
            return "hiking"
        }
        if containsAny(text, ["indoor row", "indoor rowing"]) {
            return "indoor-rowing"
        }
        if containsAny(text, ["outdoor row", "outdoor rowing"]) {
            return "outdoor-rowing"
        }
        if containsAny(text, ["rowed", "rowing", "row"]) {
            return "indoor-rowing"
        }
        if containsAny(text, ["stair", "stairs", "stepper"]) {
            return "stair-stepper"
        }
        if text.contains("triathlon") {
            return "triathlon"
        }
        return nil
    }

    private static func matchMinutes(in text: String) -> Int? {
        if containsAny(text, ["hour and a half", "hour and half"]) {
            return 90
        }
        if containsAny(text, ["half an hour", "half hour"]) {
            return 30
        }
        if let hours = number(before: ["hours", "hour"], in: text) {
            return Int(hours * 60)
        }
        if containsAny(text, ["an hour", "one hour"]) {
            return 60
        }
        if let mins = number(before: ["minutes", "minute", "mins", "min"], in: text) {
            return Int(mins)
        }
        return nil
    }

    private static func matchCalories(in text: String) -> Double? {
        number(before: ["calories", "calorie", "cals", "cal"], in: text)
    }

    private static func number(before keywords: [String], in text: String) -> Double? {
        let words = text
            .replacingOccurrences(of: "-", with: " ")
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        var index = 0
        while index < words.count {
            let word = words[index]
            if keywords.contains(word), index > 0 {
                if let value = parseNumberToken(words[index - 1]) {
                    return value
                }
            }
            index += 1
        }
        return nil
    }

    private static func parseNumberToken(_ token: String) -> Double? {
        if let value = Double(token) {
            return value
        }
        switch token {
        case "one": return 1
        case "two": return 2
        case "three": return 3
        case "four": return 4
        case "five": return 5
        case "six": return 6
        case "seven": return 7
        case "eight": return 8
        case "nine": return 9
        case "ten": return 10
        case "fifteen": return 15
        case "twenty": return 20
        case "thirty": return 30
        case "forty": return 40
        case "fortyfive", "forty-five": return 45
        case "fifty": return 50
        case "sixty": return 60
        default:
            return nil
        }
    }

    private static func containsAny(_ text: String, _ needles: [String]) -> Bool {
        var index = 0
        while index < needles.count {
            if text.contains(needles[index]) {
                return true
            }
            index += 1
        }
        return false
    }
}

enum SpokenWeightParser {
    /// Parses spoken weight such as "182 point 4" or "182.4 pounds" into a Double.
    static func parse(_ transcript: String) -> Double? {
        var text = transcript.lowercased()
        text = text.replacingOccurrences(of: "point", with: ".")
        text = text.replacingOccurrences(of: "dot", with: ".")

        let units = ["pounds", "pound", "lbs", "lb", "kilograms", "kilogram", "kilos", "kilo", "kg"]
        var unitIndex = 0
        while unitIndex < units.count {
            text = text.replacingOccurrences(of: units[unitIndex], with: " ")
            unitIndex += 1
        }

        var compact = ""
        for character in text {
            if character.isNumber || character == "." || character == "," {
                if character == "," {
                    compact.append(".")
                } else {
                    compact.append(character)
                }
            }
        }

        guard let value = Double(compact), value > 0, value < 2000 else {
            return nil
        }
        return value
    }
}
