# Unity Build Pipeline
Custom BASH script for build, archive, export and upload APK and IPA to server with Telegram notification

## Features
1. Works without running Unity and Xcode
2. Run tests
3. Build Android APK
4. Build Xcode project
5. Run post build script
6. Compile, archive and export to IPA with configurated manifests
7. Generate HTML for install links
8. Upload all object to remote server via sshpass
9. Notify by Telegram bot
10. Demos, tutorials and full C# source code are all included

## How to use
1. Edit params in ```SupportFiles/build.sh``` and manifests
2. Run build.sh
3. Make cup of tea

## Demo
Run build.sh script in terminal and select build type

![Demo build steps](https://habrastorage.org/webt/-2/nz/hp/-2nzhpzyu5qm1b0zpl_mqmff5fk.gif)
