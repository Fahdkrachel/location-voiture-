Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "cmd.exe /c standalone_bundle\start_server.bat", 0, True
WshShell.Run "bousselha_flutter.exe", 1, False
Set WshShell = Nothing
