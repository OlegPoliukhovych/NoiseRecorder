# SleepRecorder

**SleepRecorder** is a package that incapsulates audio recording feature when audio is recorded only if there is "hearable" input in recording buffer. When there is no noticeable sound then file is closed and next time new file will be automatically generated. 

## Usage

Create `SleepRecorder` object that requires only one input - function of type `() -> URL` that provides full path to location for each potentially created file. Do not provide file extension in path. Each path internally will be extended with `.aac` file extension.

```swift
let path: URL = ...some url to recordings folder 
/// provide function that will generate path to file. For example use UUID string as a file name
let pathGeneratorFunction = { path.appendingPathComponent(UUID().uuidString) }
/// create sleep recorder instance
let sleepRecorder = SleepRecorder(pathGenerator: pathGeneratorFunction)
```
Before sleep recorder can start to monitor audio input it should configure internal bindings. Call `prepare()` to do that.
Make sure to prepare object while in foreground because `AVAudioEngine` will not be started on background.
```swift
sleepRecorder.prepare()
```
Then session can start monitoring audio input and write it to files.
```swift
sleepRecorder.run()
```
Audio recording can be paused or finished.
```swift
/// pause recoring sessiion
sleepRecorder.pause()
/// stop recording session
sleepRecorder.finish()
```





