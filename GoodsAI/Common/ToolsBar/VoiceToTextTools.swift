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
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
            blockError?("Failed to set up audio recording")
            return
        }
        
        // Create English recognizer
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
              recognizer.isAvailable else {
            print("English recognizer unavailable")
            blockError?("Speech recognition is unavailable")
            return
        }
        
        // Create a fresh audio engine
        audioEngine = AVAudioEngine()

        // Configure audio input
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            blockError?("Failed to initialize speech recognition")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
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
        } catch {
            print("Audio engine failed to start: \(error.localizedDescription)")
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
                print("Recognition result: \(text)")
                self.blockInputText?(text)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // Stop recognizing if we get an error or final result
                if let error = error {
                    print("Recognition error: \(error.localizedDescription)")
                    // Only show error to user if we haven't captured any text yet
                    if self.currentText.isEmpty {
                        self.blockError?("Voice recognition error, please try again")
                    }
                }
                
                // Don't stop the audio engine here, let the user explicitly call stop
                // when they're done speaking
            }
        }
    }
    
    
    func stopLiveTranscribe() {
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
    }
    
    deinit {
        stopLiveTranscribe()
    }
}
