get-content config/dev.env | ForEach-Object {
  $name, $value = $_.split('=')
  set-content env:\$name $value
}

# configure the target distribution folder path here
Write-Output "Target distribution folder: $env:TARGET_DISTRIBUTION_FOLDER"

# set location at the current script location
Set-Location -Path $PSScriptRoot
Set-Location -Path ".."
$rootPath = (Get-Location).Path

# read the version number from pubspec.yaml
$version = (Get-Content pubspec.yaml | Select-String "version:").ToString().Split(":")[1].Trim()
$version_without_built_number = $version.Split("+")[0]

# print the version number
Write-Output $version
Write-Output $version_without_built_number

# copy CHANGELOG.md to target distribution folder
Copy-Item -Path "CHANGELOG.md" -Destination $env:TARGET_DISTRIBUTION_FOLDER\v$version\CHANGELOG.md -Force


# extract from CHANGELOG.md the release note for the current version
# until the next version log
$changelog = Get-Content -Path "CHANGELOG.md"
$releaseNote = New-Object System.Collections.ArrayList
$foundFirstVersion = $false

foreach ($line in $changelog) {
  if ($line -match "^## \[\d+\.\d+\.\d+\]") {
    if ($foundFirstVersion) {
      break
    }
    else {
      $foundFirstVersion = $true
    }
  }
  if ($foundFirstVersion) {
    $releaseNote.Add($line) | Out-Null
  }
}

# convert release note to string and then trim
$releaseNote = $releaseNote -join "`n"

Write-Output $releaseNote

# output the release note to a RELEASE_NOTE.md file in root folder
$releaseNote | Out-File -FilePath $rootPath\RELEASE_NOTE.md -Encoding utf8

# gh release create with RELEASE_NOTE.md
gh release create v$version_without_built_number -F $rootPath\RELEASE_NOTE.md

# gh release upload every zip/apk files in the folder
# Get-ChildItem -Path $env:TARGET_DISTRIBUTION_FOLDER\v$version\*.zip | ForEach-Object {
Get-ChildItem -Path $env:TARGET_DISTRIBUTION_FOLDER\v$version\* -Include *.zip, *.apk, *.exe | ForEach-Object {
  gh release upload v$version_without_built_number $_.FullName
}
