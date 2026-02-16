@ECHO OFF

REM PowerShellスクリプトをバイパスモードで実行
SET SCRIPTPATH=%~dp0lib\LoginGui.ps1
powershell -ExecutionPolicy Bypass -File "%SCRIPTPATH%"
