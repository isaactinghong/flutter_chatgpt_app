get-content config/dev.env | ForEach-Object {
  $name, $value = $_.split('=')
  set-content env:\$name $value
}

# configure the target distribution folder path here
Write-Output "Target distribution folder: $env:TARGET_DISTRIBUTION_FOLDER"


# set location at the current script location
Set-Location -Path $PSScriptRoot
Set-Location -Path ".."

# copy CHANGELOG.md to target distribution folder
Copy-Item -Path "CHANGELOG.md" -Destination $env:TARGET_DISTRIBUTION_FOLDER\v$version\CHANGELOG.md -Force

# read the version number from pubspec.yaml
$version = (Get-Content pubspec.yaml | Select-String "version:").ToString().Split(":")[1].Trim()

# print the version number
Write-Output $version

# cd to target distribution folder: D:\Google Drive\Work\ZACDEV\ZD Projects\ChatGPT Flutter
# Set-Location -Path $env:TARGET_DISTRIBUTION_FOLDER\v$version\


# gh release create with CHANGELOG.md
gh release create v$version -F CHANGELOG.md

# gh release upload every zip/apk files in the folder
# Get-ChildItem -Path $env:TARGET_DISTRIBUTION_FOLDER\v$version\*.zip | ForEach-Object {
Get-ChildItem -Path $env:TARGET_DISTRIBUTION_FOLDER\v$version\* -Include *.zip, *.apk | ForEach-Object {
  gh release upload v$version $_.FullName
}
