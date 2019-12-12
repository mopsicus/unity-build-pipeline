#!/bin/bash

clear

START=$(date +"%s")
PROJECT_PATH="$(dirname "$(PWD)")"

# 
# PARAMS TO CHANGE
#

BRANCH='master'

COMPANY='my_company'
GAME_NAME='new_game'
BUNDLE='com.mygames.game'
TEAM='ios_team_id'
REMOTE_PATH='url_my_builds_server'

SSH_LOGIN='my_login'
SSH_PASS='my_pass'
SSH_HOST='my_builds_server.ru'
SSH_PATH='~/domains/my_builds_server.ru/builds'

TEMPLATE_FILE=$(PWD)'/template.html'
MANIFEST_FILE=$(PWD)'/manifest.plist'
VERSION_FILE=$(PWD)'/version.txt'

LOGS_PATH=$PROJECT_PATH'/Logs'
ANDROID_PATH=$PROJECT_PATH'/Builds/Android'
BUILDS_PATH=$PROJECT_PATH'/Builds'
IOS_PATH=$PROJECT_PATH'/Builds/iOS'
IOS_BUILD_PATH=$PROJECT_PATH'/Builds/iOS/build'
IOS_DEVELOPMENT=$PROJECT_PATH'/Builds/iOS/build/development'
IOS_RELEASE=$PROJECT_PATH'/Builds/iOS/build/release'

BOT_TOKEN='my_bot_token'
BOT_PROXY='--proxy 185.189.211.70:8080'
CHAT_ID='123456798'

UNITY='/Applications/Unity/Hub/Editor/2019.3.0f1/Unity.app/Contents/MacOS/Unity'

#
#
#

[ -d "$LOGS_PATH" ] || mkdir "$LOGS_PATH"
[ -d "$ANDROID_PATH" ] || mkdir "$ANDROID_PATH"
[ -d "$BUILDS_PATH" ] || mkdir "$BUILDS_PATH"
[ -d "$IOS_PATH" ] || mkdir "$IOS_PATH"
[ -d "$IOS_BUILD_PATH" ] || mkdir "$IOS_BUILD_PATH"
[ -d "$IOS_DEVELOPMENT" ] || mkdir "$IOS_DEVELOPMENT"
[ -d "$IOS_RELEASE" ] || mkdir "$IOS_RELEASE"

function UpdateRepo {
echo ''
echo "update branch $BRANCH..." 
echo ''     
git fetch > "$LOGS_PATH/git.log" 2>&1
git reset --hard HEAD >> "$LOGS_PATH/git.log" 2>&1
git checkout $BRANCH >> "$LOGS_PATH/git.log" 2>&1
git pull >> "$LOGS_PATH/git.log" 2>&1
echo ''
echo "$BRANCH updated" 
echo ''     
}

function SendTelegramMessage {
curl $BOT_PROXY https://api.telegram.org/bot$BOT_TOKEN/sendMessage -m 60 -s -X POST -d chat_id=$CHAT_ID -d text="$1" > "$LOGS_PATH/bot.log" 2>&1
}

function ShowElapsedTime {
echo '' 
end=$(date +"%s")
elapsed=$(($end-$START))
echo "$(($elapsed / 60)) minutes $(($elapsed % 60)) seconds"
echo '' 
}

function GenerateHTML {
platform=$1
echo ''
echo "generate HTML for $platform download page..." 
echo '' 
build=$2
out="$3/$1.$build.html"
version=$(<$VERSION_FILE)
url="$REMOTE_PATH\/$GAME_NAME.$version.$build.apk"
if [ "$platform" == "ios" ]; then
url="itms-services:\/\/?action=download-manifest\&url=$REMOTE_PATH\/manifest.$build.plist"
fi
time=$(date +"%d.%m.%Y %T")
sed -e "s/\${TITLE}/$GAME_NAME/g" -e "s/\${PLATFORM}/$platform/" -e "s/\${VERSION}/$version $build/" -e "s/\${DATE}/$time/" -e "s/\${URL}/$url/" "$TEMPLATE_FILE" > "$out"
}

function PatchManifest {
echo ''
echo 'patch manifest...' 
echo ''     
version=$(<$VERSION_FILE)
url="$REMOTE_PATH\/$GAME_NAME.$version.$1.ipa"
icon="$REMOTE_PATH\/icon.png"
itunes="$REMOTE_PATH\/itunes.png"
mv "$2/Unity-iPhone.ipa" "$2/$GAME_NAME.$version.$1.ipa"
out="$2/manifest.$1.plist"
sed -e "s/\${IPA}/$url/" -e "s/\${ICON}/$icon/" -e "s/\${ITUNES}/$itunes/" -e "s/\${BUNDLE}/$BUNDLE/" -e "s/\${VERSION}/$version/" -e "s/\${COMPANY}/$COMPANY/" -e "s/\${TITLE}/$GAME_NAME/" "$MANIFEST_FILE" > "$out"
}

function PrepareOptions {
echo ''
echo 'prepare manifest options...' 
echo ''     
out="$2/options.plist"
sed -e "s/\${TEAM}/$TEAM/" "$(PWD)/$1.plist" > "$out"
}

function Upload {
platform=$1
echo ''
echo "upload $platform data..." 
echo '' 
version=$(<$VERSION_FILE)
build=$2
folder=$3
if [ "$platform" == "ios" ]; then
echo '' 
sshpass -p $SSH_PASS scp "$folder/$GAME_NAME.$version.$build.ipa" "$folder/$platform.$build.html" "$folder/manifest.$build.plist" $SSH_LOGIN@$SSH_HOST:$SSH_PATH
else
sshpass -p $SSH_PASS scp "$folder/$GAME_NAME.$version.$build.apk" "$folder/$platform.$build.html" $SSH_LOGIN@$SSH_HOST:$SSH_PATH
fi    
}

function GetInstallUrl {
echo ''
url=$(echo $REMOTE_PATH | sed -e "s/\\\//g")
echo "$url/$1.$2.html"
}

function AndroidDevelopment {
echo '' 
echo '|||||||||||||||||||||||||||||||' 
echo '|                             |' 
echo '|     Android development     |' 
echo '|                             |' 
echo '|||||||||||||||||||||||||||||||' 
echo ''
echo ''
echo 'build unity and archive APK...' 
echo '' 
$UNITY -batchmode -quit -projectPath "$PROJECT_PATH" -executeMethod Game.BuildActions.AndroidDevelopment -buildTarget android -logFile "$LOGS_PATH/android_development.log"
if [ $? -ne 0 ]; then
echo ''
echo 'Operation failed!'
echo '' 
exit 1
fi
GenerateHTML "android" "development" "$ANDROID_PATH"
Upload "android" "development" "$ANDROID_PATH"
echo ''
echo 'build completed' 
echo '' 
}

function AndroidRelease {
echo '' 
echo '|||||||||||||||||||||||||||||||' 
echo '|                             |' 
echo '|       Android release       |' 
echo '|                             |' 
echo '|||||||||||||||||||||||||||||||' 
echo ''
echo ''
echo 'build unity and archive APK...' 
echo '' 
$UNITY -batchmode -quit -projectPath "$PROJECT_PATH" -executeMethod Game.BuildActions.AndroidRelease -buildTarget android -logFile "$LOGS_PATH/android_release.log"
if [ $? -ne 0 ]; then
echo ''
echo 'Operation failed!'
echo '' 
exit 1
fi
GenerateHTML "android" "release" "$ANDROID_PATH"
Upload
echo ''
echo 'build completed' 
echo '' 
}

function iOSDevelopment {
echo '' 
echo '|||||||||||||||||||||||||||||||' 
echo '|                             |' 
echo '|       iOS development       |' 
echo '|                             |' 
echo '|||||||||||||||||||||||||||||||' 
echo ''
if [ -d "$IOS_PATH" ]; then
echo ''
echo 'clean ios directory...' 
echo ''
rm -r $IOS_PATH
fi
echo ''
echo 'build unity...' 
echo '' 
$UNITY -batchmode -quit -projectPath "$PROJECT_PATH" -executeMethod Game.BuildActions.iOSDevelopment -buildTarget ios -logFile "$LOGS_PATH/ios_development.log"
if [ $? -ne 0 ]; then
echo ''
echo 'Operation failed!'
echo '' 
exit 1
fi
echo ''
echo 'build xcode...' 
echo '' 
xcodebuild -project "$IOS_PATH/Unity-iPhone.xcodeproj" -quiet > "$LOGS_PATH/ios_build_development.log" 2>&1
echo ''
echo 'archive xcode...' 
echo '' 
xcodebuild -project "$IOS_PATH/Unity-iPhone.xcodeproj" -scheme "Unity-iPhone" archive -archivePath "$IOS_DEVELOPMENT/Unity-iPhone.xcarchive" -quiet > "$LOGS_PATH/ios_archive_development.log" 2>&1
PrepareOptions "development" "$IOS_DEVELOPMENT"
echo ''
echo 'export ipa...' 
echo '' 
xcodebuild -exportArchive -archivePath "$IOS_DEVELOPMENT/Unity-iPhone.xcarchive" -exportOptionsPlist "$IOS_DEVELOPMENT/options.plist" -exportPath $IOS_DEVELOPMENT -allowProvisioningUpdates -quiet > "$LOGS_PATH/ios_export_development.log" 2>&1
PatchManifest "development" "$IOS_DEVELOPMENT"
GenerateHTML "ios" "development" "$IOS_DEVELOPMENT"
Upload "ios" "development" "$IOS_DEVELOPMENT"
echo ''
echo 'build completed' 
echo ''
}

function iOSRelease {
echo '' 
echo '|||||||||||||||||||||||||||||||' 
echo '|                             |' 
echo '|         iOS release         |' 
echo '|                             |' 
echo '|||||||||||||||||||||||||||||||' 
echo ''
if [ -d "$IOS_PATH" ]; then
echo ''
echo 'clean ios directory...' 
echo ''
rm -r $IOS_PATH
fi
echo '' 
echo 'build unity...' 
echo '' 
$UNITY -batchmode -quit -projectPath "$PROJECT_PATH" -executeMethod Game.BuildActions.iOSRelease -buildTarget ios -logFile "$LOGS_PATH/ios_release.log"
if [ $? -ne 0 ]; then
echo ''
echo 'Operation failed!'
echo '' 
exit 1
fi
echo ''
echo 'build xcode...' 
echo ''
xcodebuild -project "$IOS_PATH/Unity-iPhone.xcodeproj" -quiet > "$LOGS_PATH/ios_build_release.log" 2>&1
echo ''
echo 'archive xcode...' 
echo '' 
xcodebuild -project "$IOS_PATH/Unity-iPhone.xcodeproj" -scheme "Unity-iPhone" archive -archivePath "$IOS_RELEASE/Unity-iPhone.xcarchive" -quiet > "$LOGS_PATH/ios_archive_release.log" 2>&1
PrepareOptions "release" "$IOS_RELEASE"
echo ''
echo 'export ipa...' 
echo '' 
xcodebuild -exportArchive -archivePath "$IOS_RELEASE/Unity-iPhone.xcarchive" -exportOptionsPlist "$IOS_RELEASE/options.plist" -exportPath $IOS_RELEASE -allowProvisioningUpdates -quiet > "$LOGS_PATH/ios_export_release.log" 2>&1
echo ''
echo 'build completed' 
echo ''
}

function Tests {
echo '' 
echo '|||||||||||||||||||||||||||||||' 
echo '|                             |' 
echo '|        Project test         |' 
echo '|                             |' 
echo '|||||||||||||||||||||||||||||||' 
echo ''
echo ''
echo 'test unity...' 
echo '' 
$UNITY -runTests -batchmode -projectPath "$PROJECT_PATH" -testResults "$LOGS_PATH/test.xml"
echo ''
echo 'tests completed' 
echo ''
}

echo '' 
echo '' 
echo '' 
echo '|||||||||||||||||||||||||||||||' 
echo '|                             |' 
echo '|       Build pipeline        |' 
echo '|                             |' 
echo '|||||||||||||||||||||||||||||||' 
echo ''
echo ''
echo ''
echo "0 – Update branch $BRANCH"
echo ''
echo '1 – Run tests'
echo ''
echo '2 – Android development'
echo '3 – Android release'
echo '4 – iOS development'
echo '5 – iOS release'
echo '' 
echo '6 – iOS & Android development'
echo '7 – iOS & Android release'
echo '' 
echo '' 
read -n 1 -s -r -p 'Select build type, ESC to cancel...' key
echo ''
if [ "$key" == $'\e' ]; then
echo '' 
echo '' 
echo 'Operation canceled!'
echo '' 
echo '' 
exit 1
fi
clear
case $key in
0)
UpdateRepo
;; 
1)
Tests
;; 
2)
AndroidDevelopment
url=$(GetInstallUrl "android" "development")
SendTelegramMessage "android: $url"
;;
3)
AndroidRelease
url=$(GetInstallUrl "android" "release")
SendTelegramMessage "android: $url"
;;
4)
iOSDevelopment
url=$(GetInstallUrl "ios" "development")
SendTelegramMessage "ios: $url"
;;
5)
iOSRelease
url=$(GetInstallUrl "ios" "release")
SendTelegramMessage "ios: $url"
;;    
6)
AndroidDevelopment
iOSDevelopment
url=$(GetInstallUrl "android" "development")
SendTelegramMessage "android: $url"
url=$(GetInstallUrl "ios" "development")
SendTelegramMessage "ios: $url"
;;  
7)
AndroidRelease
iOSRelease
url=$(GetInstallUrl "android" "release")
SendTelegramMessage "android: $url"
url=$(GetInstallUrl "ios" "release")
SendTelegramMessage "ios: $url"
;; 
*)
echo '' 
echo '' 
echo 'Unknown operation type!'
echo '' 
echo '' 
exit 1
;;
esac
ShowElapsedTime
