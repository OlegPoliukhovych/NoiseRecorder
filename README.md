# SleepRecorder

**SleepRecorder** is a package that incapsulates audio recording feature when audio is recorded only if there is "hearable" output in recording buffer. When there is no noticeable sound then file is closed and next time new file will be automatically generated. 

## Usage

`SleepRecorder` object requires only one input - function of type `() -> URL` that provides full path to location for each potentially created file. Do not provide file extension in path. Each path internally will be extended with ``.aac`` file extension.

```swift
let path: URL = ...some url to recordings folder 
/// function that will generate path to file with UUID string as a file name
let pathGeneratorFunction = { path.appendingPathComponent(UUID().uuidString) }
/// create sleep recorder instance
let sleepRecorder = SleepRecorder(pathGenerator: pathGeneratorFunction)
/// tell to do preparation
sleepRecorder.prepare()
/// start recording session
sleepRecorder.run()
/// pause recoring sessiion
sleepRecorder.pause()
/// stop recording session
sleepRecorder.finish()
```





