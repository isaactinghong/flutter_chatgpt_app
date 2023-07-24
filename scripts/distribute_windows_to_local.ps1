# navigate back to root
Set-Location -Path $PSScriptRoot
Set-Location -Path ".."


# Flutter build into windows
# flutter build windows --release

# !!! This will install the Windows app on the local machine
# copy the build output into C:/ChatGPT Flutter/
#Copy-Item -Path "build\windows\runner\Release\*" -Destination "C:\ChatGPT Flutter" -Recurse -Force

# use innosetup to create an installer
# the installer path:  C:\Program Files (x86)\Inno Setup 6\ISCC.exe
# run the innosetup script
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "scripts\innosetup.iss"

# run the installer in scripts/output folder
& "scripts\output\FlutterGPTSetup.exe"