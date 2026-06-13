; Script Inno Setup pour compiler l'application BOUSSELHA CARS
#define MyAppName "BOUSSELHA CARS"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "BOUSSELHA CARS"
#define MyAppExeName "bousselha_flutter.exe"
#define MyBuildPath "..\build\windows\x64\runner\Release"

[Setup]
AppId={{C3D4D540-3B45-4A76-805F-23E98A53B250}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\build\windows\installer
OutputBaseFilename=BousselhaCarsSetup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le Bureau"; Flags: unchecked

[Files]
Source: "{#MyBuildPath}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyBuildPath}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Inclure le fichier config.json par défaut à côté de l'exécutable s'il n'existe pas déjà
Source: "..\assets\config.json"; DestDir: "{app}"; Flags: onlyifdoesntexist

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Lancer BOUSSELHA CARS"; Flags: nowait postinstall skipifsilent
