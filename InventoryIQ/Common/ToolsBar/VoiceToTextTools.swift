//
//  AudioRecorder.swift
//  GoodsAI
//
//  Created by Emily on 2025/3/20.
//

import AVFoundation
import Speech


class VoiceToTextTools {

    var blockInputText:((String)->())?
    var blockError:((String)->())?

    var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var currentText: String = ""
    
    func requestRecordPermission(completion: ((Bool) -> Void)? = nil){
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            guard granted else { 
                completion?(false)
                return 
            }
            
            SFSpeechRecognizer.requestAuthorization { status in
                let authorized = status == .authorized
                completion?(authorized)
            }
        }
    }

    
    func startLiveTranscribe() {
        // Cancel any previous task
        stopLiveTranscribe()
        
        print("=== VoiceToTextTools: Starting Transcription ===")
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("=== VoiceToTextTools: Failed to set up audio session: \(error.localizedDescription) ===")
            blockError?("Failed to set up audio recording")
            return
        }
        
        // Create English recognizer
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
              recognizer.isAvailable else {
            print("=== VoiceToTextTools: English recognizer unavailable ===")
            blockError?("Speech recognition is unavailable")
            return
        }
        
        // Create a fresh audio engine
        audioEngine = AVAudioEngine()

        // Configure audio input
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("=== VoiceToTextTools: Unable to create recognition request ===")
            blockError?("Failed to initialize speech recognition")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Add task hints to improve recognition
        if #available(iOS 13, *) {
            recognitionRequest.taskHint = .dictation
        }
        
        // Connect to input node
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start engine
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            print("=== VoiceToTextTools: Audio engine started successfully ===")
        } catch {
            print("=== VoiceToTextTools: Audio engine failed to start: \(error.localizedDescription) ===")
            blockError?("Failed to start audio recording")
            return
        }
        
        // Reset current text
        currentText = ""
        
        // Begin recognition task
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                self.currentText = text
                print("=== VoiceToTextTools: Recognition result: \"\(text)\" ===")
                
                // Update UI immediately with partial results while user is holding button
                // This gives better real-time feedback during recording
                DispatchQueue.main.async {
                    self.blockInputText?(text)
                    print("=== VoiceToTextTools: Called blockInputText with text: \"\(text)\" ===")
                }
                
                isFinal = result.isFinal
                
                // If we get a final result, make sure it's processed
                if isFinal {
                    print("=== VoiceToTextTools: Received final result from recognition ===")
                }
            }
            
            if error != nil || isFinal {
                // Only handle errors - don't stop on final since we want continuous recognition
                if let error = error {
                    print("=== VoiceToTextTools: Recognition error: \(error.localizedDescription) ===")
                    // Only show error to user if we haven't captured any text yet
                    if self.currentText.isEmpty {
                        DispatchQueue.main.async {
                            self.blockError?("Voice recognition error, please try again")
                        }
                    }
                }
            }
        }
    }
    
    
    func stopLiveTranscribe() {
        print("=== VoiceToTextTools: Stopping Transcription ===")
        
        // Store the final text before stopping
        let finalText = self.currentText
        
        // Stop audio engine and remove tap
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Clean up request
        recognitionRequest = nil
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        print("=== VoiceToTextTools: Transcription Stopped ===")
        
        // Always call the input block with the final text immediately
        // This is crucial for the press-and-hold interaction
        if !finalText.isEmpty {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                print("=== VoiceToTextTools: Calling blockInputText with final text: \"\(finalText)\" ===")
                self.blockInputText?(finalText)
            }
        }
    }
    
    deinit {
        stopLiveTranscribe()
    }
}
