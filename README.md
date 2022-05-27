# NoiseRecorder

**NoiseRecorder** is a package that incapsulates audio recording feature when audio is recorded only if there is "hearable" input in recording buffer. When there is no noticeable sound then file is closed and next time new file will be automatically generated. 

## Usage

Create `NoiseRecorder` object that requires only one input - function of type `() -> URL` that provides full path to location for each potentially created file. Do not provide file extension in path. Each path internally will be extended with `.aac` file extension.

```swift
let path: URL = ...some url to recordings folder 
/// provide function that will generate path to file. For example use UUID string as a file name
let pathGeneratorFunction = { path.appendingPathComponent(UUID().uuidString) }
/// create noise recorder instance
let noiseRecorder = NoiseRecorder(pathGenerator: pathGeneratorFunction)
```
Next step is to activate audio engine and receive audio input buffer.
**Important** `activateAudioEngine()` should be called from foreground otherwise there will be runtime error.
```swift
noiseRecorder.activateAudioEngine()
```

Then configure internal subsciptions to handle audio input. Call `prepare()` for that.
```swift
noiseRecorder.prepare()
```
Then start session to actually handle audio input.
```swift
noiseRecorder.run()
```
Audio recording can be paused or stopped.
```swift
/// pause recording session
noiseRecorder.pause()
/// stop recording session
noiseRecorder.stop()
```





