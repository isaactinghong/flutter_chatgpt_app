get-content config/dev.env | ForEach-Object {
  $name, $value = $_.split('=')
  set-content env:\$name $value
}

# configure the target distribution folder path here
Write-Output "Target distribution folder: $env:TARGET_DISTRIBUTION_FOLDER"

# set location at the current script location
Set-Location -Path $PSScriptRoot
Set-Location -Path ".."

# read the version number from pubspec.yaml
$version = (Get-Content pubspec.yaml | Select-String "version:").ToString().Split(":")[1].Trim()

# print the version number
Write-Output $version

# cd to target distribution folder: D:\Google Drive\Work\ZACDEV\ZD Projects\ChatGPT Flutter
Set-Location -Path $env:TARGET_DISTRIBUTION_FOLDER

# create folder with the version number from pubspec.yaml, in v1.0.0 format
New-Item -ItemType Directory -Force -Path v$version

# navigate back to root
Set-Location -Path $PSScriptRoot
Set-Location -Path ".."

# copy CHANGELOG.md to target distribution folder
Copy-Item -Path "CHANGELOG.md" -Destination $env:TARGET_DISTRIBUTION_FOLDER\v$version\CHANGELOG.md -Force


# Flutter build into windows
flutter build windows --release

# zip the build output into a new zip file
# Compress-Archive -Path "build\windows\runner\Release\*" -DestinationPath $env:TARGET_DISTRIBUTION_FOLDER\v$version\windows.zip

# !!! This will install the Windows app on the local machine
# copy the build output into C:/ChatGPT Flutter/
# Copy-Item -Path "build\windows\runner\Release\*" -Destination "C:\Program Files (x86)\FlutterGPT" -Recurse -Force

# use innosetup to create an installer
# the installer path:  C:\Program Files (x86)\Inno Setup 6\ISCC.exe
# run the innosetup script
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "scripts\innosetup.iss"

# move the installer to the distribution folder
Copy-Item -Path "scripts\output\FlutterGPTSetup.exe" -Destination $env:TARGET_DISTRIBUTION_FOLDER\v$version\FlutterGPTSetup.exe -Force

# Flutter build into apk
flutter build apk --release

# move the apk to the distribution folder
Move-Item -Path "build\app\outputs\flutter-apk\app-release.apk" -Destination $env:TARGET_DISTRIBUTION_FOLDER\v$version\app-release.apk -Force