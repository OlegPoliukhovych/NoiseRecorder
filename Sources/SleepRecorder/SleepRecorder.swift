import Foundation
import AVFoundation
import Combine
import Helpers

public final class SleepRecorder {

    private let audioEngine = AVAudioEngine()

    @Published private var shouldActuallyRecord: Bool = false

    private let outputFileProvider: AudioFileProvider

    var cancellables = Set<AnyCancellable>()

    public init(pathGenerator: @escaping () -> URL) {
        outputFileProvider = AudioFileProvider(pathGenerator)
    }

    // MARK: AudioItemHandler

    public func prepare() {

        let bufferHandlingQueue = DispatchQueue(label: "sleep.recorder.bufferOutput.serial.queue")

        /// provide buffer only when it is actually needed: shouldActuallyRecord == true
        let bufferPublisher = audioEngine.recordingBufferPublisher
            .combineLatest($shouldActuallyRecord)
            .filter { $0.1 }
            .map { $0.0 }
            .subscribe(on: bufferHandlingQueue, options: .none)
            .share()

        let bufferFilePairPublisher = bufferPublisher
            .combineLatest(outputFileProvider.outputFile)
            .receive(on: bufferHandlingQueue)
            .share()

        /// create new file if there is recognizable noise in buffer and output file is not exist
        bufferFilePairPublisher
            .filter { $0.1 == nil && isSoundLevelRecognizable(buffer: $0.0) }
            .map { _ in AudioFileProvider.Action.createFile }
            .assign(to: \.action, on: self.outputFileProvider)
            .store(in: &cancellables)

        /// Write buffer into a file
        bufferFilePairPublisher
            .filter { $0.1 != nil }
            .sink { buffer, file in
                try? file?.write(from: buffer)
            }
            .store(in: &cancellables)

        /// Close currently used file after 2 seconds of "silence" in audio input
        bufferFilePairPublisher
            .filter { $0.1 != nil && isSoundLevelRecognizable(buffer: $0.0) }
            .debounce(for: .seconds(2), scheduler: bufferHandlingQueue)
            .map { _ in AudioFileProvider.Action.closeFile }
            .assign(to: \.action, on: self.outputFileProvider)
            .store(in: &cancellables)
    }

    public func run() {
        // audioengine is running initially because it should be started in foreground.
        // this guard check fires up actual recording once for already running session.
        // otherwise we should control the audio engine state explicitly in case session was paused or interrupted.
        guard shouldActuallyRecord else {
            shouldActuallyRecord = true
            return
        }

        audioEngine.prepare()
        try? audioEngine.start()
    }

    public func pause() {
        audioEngine.pause()
        outputFileProvider.action = .closeFile
    }

    public func finish() {
        shouldActuallyRecord = false
        audioEngine.cleanupRecording()
        outputFileProvider.action = .closeFile
    }
}
