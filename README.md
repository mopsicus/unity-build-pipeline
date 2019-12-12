# Unity Build Pipeline
Custom BASH script for build, archive, export and upload APK and IPA to server with Telegram notification

## Features
1. Works without running Unity and Xcode
2. Update from GIT
3. Run tests
4. Build Android APK
5. Build Xcode project
6. Run post build script
7. Compile, archive and export to IPA with configurated manifests
8. Generate HTML for install links
9. Upload all object to remote server via sshpass
10. Notify by Telegram bot
11. Demos and full C# and BASH source code are all included

## How to use
1. Edit params in ```SupportFiles/build.sh``` and manifests
2. Run build.sh
3. Make cup of tea

## Demo
Run build.sh script in terminal and select build type

![Demo build steps](https://habrastorage.org/webt/-2/nz/hp/-2nzhpzyu5qm1b0zpl_mqmff5fk.gif)
