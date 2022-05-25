import Foundation
import AVFoundation
import Combine
import Helpers

public final class NoiseRecorder {

    private let audioEngine = AVAudioEngine()

    private let outputFileProvider: AudioFileProvider
    private var bufferPublisher: AnyPublisher<AVAudioPCMBuffer, Never>?

    var cancellables = Set<AnyCancellable>()

    public init(pathGenerator: @escaping () -> URL) {
        outputFileProvider = AudioFileProvider(pathGenerator)
    }

    /// Installs tap and attaches publisher that will poduce buffers of audio data
    public func activateAudioEngine() {
        bufferPublisher = audioEngine.tapBuffer()
    }

    public func prepare() {

        if bufferPublisher == nil {
            guard Thread.isMainThread else {
                fatalError("audio engine should be activated from foreground")
            }
            activateAudioEngine()
        }

        // pause engine while setting up subscriptions because there may be some input in buffer from pevious player session
        audioEngine.pause()
        
        let bufferHandlingQueue = DispatchQueue(label: "sleep.recorder.bufferOutput.serial.queue")

        let bufferFilePairPublisher = bufferPublisher!
            .combineLatest(outputFileProvider.outputFile)
            .subscribe(on: bufferHandlingQueue)
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
        if !audioEngine.isRunning {
            try? audioEngine.start()
        }
    }

    public func pause() {
        audioEngine.pause()
        outputFileProvider.action = .closeFile
    }

    public func stop() {
        audioEngine.cleanupRecording()
        outputFileProvider.action = .closeFile
    }
}
