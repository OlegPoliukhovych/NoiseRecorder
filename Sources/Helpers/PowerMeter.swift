import Foundation
import AVFoundation

/// Checking if average power of sample is "hearable" to prevent writing silent samples into the file
/// - Parameter buffer: buffer of audio samples
/// - Parameter threshold: threshold level
/// - Returns: Bool value indicating if average power of provided samples is high enough to be recognized as hearable noise
public func isSoundLevelRecognizable(
    buffer: AVAudioPCMBuffer,
    threshold: Float = -40
) -> Bool {
    guard let channelData = buffer.floatChannelData else { return false }
    let channelDataValue = channelData.pointee
    let channelDataValueArray = stride(from: 0,
                                       to: Int(buffer.frameLength),
                                       by: buffer.stride)
        .map { channelDataValue[$0] }

    let rms = channelDataValueArray
        .map { $0 * $0 }
        .reduce(0, +) / Float(buffer.frameLength)
    let avgPower = 20 * log10(sqrt(rms))

    return avgPower > threshold
}
