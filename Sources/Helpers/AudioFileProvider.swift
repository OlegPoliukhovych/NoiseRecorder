import Foundation
import AVFoundation
import Combine

public final class AudioFileProvider {

    public enum Action {
        case createFile, closeFile
    }

    let pathGenetor: () -> URL

    public var outputFile: AnyPublisher<AVAudioFile?, Never> {
        $action
            .map { [unowned self] action -> AVAudioFile? in
                switch action {
                case .createFile:
                    return self.file
                case .closeFile:
                    return nil
                }
            }
            .eraseToAnyPublisher()
    }

    @Published public var action: AudioFileProvider.Action = .createFile

    public init(_ pathGenerator: @escaping () -> URL) {
        self.pathGenetor = pathGenerator
    }

    private var file: AVAudioFile? {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]

        let filename = pathGenetor().appendingPathExtension("aac")
        return try? AVAudioFile(forWriting: filename, settings: settings)
    }
}
