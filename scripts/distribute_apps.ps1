# set location at the current script location
Set-Location -Path $PSScriptRoot

# navigate to root "cd .."
Set-Location -Path ".."

# read the version number from pubspec.yaml
$version = (Get-Content pubspec.yaml | Select-String "version:").ToString().Split(":")[1].Trim()

# print the version number
Write-Output $version

# cd to target distribution folder: D:\Google Drive\Work\ZACDEV\ZD Projects\ChatGPT Flutter
Set-Location -Path "D:\Google Drive\Work\ZACDEV\ZD Projects\ChatGPT Flutter"

# create folder with the version number from pubspec.yaml, in v1.0.0 format
New-Item -ItemType Directory -Force -Path v$version

# navigate back to root
Set-Location -Path $PSScriptRoot
Set-Location -Path ".."


# Flutter build into windows
flutter build windows --release

# zip the build output into a new zip file
Compress-Archive -Path "build\windows\runner\Release\*" -DestinationPath "D:\Google Drive\Work\ZACDEV\ZD Projects\ChatGPT Flutter\v$version\windows.zip"

# copy the build output into C:/ChatGPT Flutter/
Copy-Item -Path "build\windows\runner\Release\*" -Destination "C:\ChatGPT Flutter" -Recurse -Force

# Flutter build into apk
flutter build apk --release

# move the apk to the distribution folder
Move-Item -Path "build\app\outputs\flutter-apk\app-release.apk" -Destination "D:\Google Drive\Work\ZACDEV\ZD Projects\ChatGPT Flutter\v$version\app-release.apk"