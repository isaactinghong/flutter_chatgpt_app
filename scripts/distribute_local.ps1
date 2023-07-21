# navigate back to root
Set-Location -Path $PSScriptRoot
Set-Location -Path ".."


# Flutter build into windows
flutter build windows --release

# !!! This will install the Windows app on the local machine
# copy the build output into C:/ChatGPT Flutter/
Copy-Item -Path "build\windows\runner\Release\*" -Destination "C:\ChatGPT Flutter" -Recurse -Force