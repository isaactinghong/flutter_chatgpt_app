[Setup]
AppName=FlutterGPT
AppVersion=1.0
DefaultDirName={pf}\FlutterGPT
DefaultGroupName=FlutterGPT
OutputDir=output
OutputBaseFilename=FlutterGPTSetup
Compression=lzma2
SolidCompression=yes

[Files]
Source: "C:\Users\isaac\source\repos\flutter_chatgpt_app\build\windows\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\FlutterGPT"; Filename: "{app}\flutter_chat.exe"

[Run]
Filename: "{app}\flutter_chat.exe"; Description: "Launch Your Application"; Flags: nowait postinstall skipifsilent