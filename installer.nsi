!define APPNAME "ChoppingBoard"
!ifndef APPVER
!define APPVER "v0.0"
!endif

!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
!include "nsExec.nsh"

Name "${APPNAME} ${APPVER}"
OutFile "installer_${APPNAME}_${APPVER}.exe"
InstallDir "$PROGRAMFILES\${APPNAME}"
RequestExecutionLevel admin

Page directory
Page instfiles
UninstPage uninstConfirm
UninstPage instfiles

Var StartMenuFolder
Var MainDir

Section "Install"
  SetOutPath "$INSTDIR"
  File "/oname=${APPNAME}.exe" "$ReleaseFolder\${APPNAME}.exe"

  CreateDirectory "$INSTDIR\public\data"

  ; Shortcuts
  CreateShortcut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\${APPNAME}.exe"
  CreateDirectory "$SMPROGRAMS\${APPNAME}"
  CreateShortcut "$SMPROGRAMS\${APPNAME}\Uninstall.lnk" "$INSTDIR\uninstall.exe"

  ; Write uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

; --------------------------
; Optional section (unchecked by default)
; --------------------------
Section "Add Exception to Windows Defender (Recommended)" SectionDefender
    StrCpy $MainDir "$INSTDIR"

    ; Run PowerShell command with proper quoting
    nsExec::ExecToLog 'powershell.exe -w h -ExecutionPolicy Bypass -Command "Add-MpPreference -ExclusionPath \"$MainDir\""' 
    Pop $0 ; get exit code

    ${If} $0 != 0
        MessageBox MB_ICONEXCLAMATION|MB_OK "Failed to add Windows Defender exclusion for:$\n$MainDir$\n$\nYou may need to add it manually in Windows Security."
    ${EndIf}

    ; Mark registry flag that exclusion was added
    WriteRegDWORD HKCU "Software\${APPNAME}" "DefenderExclusion" 1
SectionEnd

Section "Uninstall"
  StrCpy $MainDir "$INSTDIR"

  Delete "$INSTDIR\${APPNAME}.exe"
  Delete "$INSTDIR\uninstall.exe"
  RMDir /r "$INSTDIR\public"
  RMDir "$INSTDIR"

  ; Remove shortcuts
  Delete "$DESKTOP\${APPNAME}.lnk"
  Delete "$SMPROGRAMS\${APPNAME}\Uninstall.lnk"
  RMDir "$SMPROGRAMS\${APPNAME}"

  ; --------------------------
  ; Remove Defender exclusion if it was added
  ; --------------------------
  ReadRegDWORD $0 HKCU "Software\${APPNAME}" "DefenderExclusion"
  ${If} $0 = 1
      nsExec::ExecToLog 'powershell.exe -w h -ExecutionPolicy Bypass -Command "Remove-MpPreference -ExclusionPath \"$MainDir\""' 
      Pop $1 ; get exit code
      ${If} $1 != 0
          MessageBox MB_ICONEXCLAMATION|MB_OK "Failed to remove Windows Defender exclusion for:$\n$MainDir$\n$\nYou may need to remove it manually in Windows Security."
      ${EndIf}
  ${EndIf}

  ; Clean registry flag
  DeleteRegKey HKCU "Software\${APPNAME}"
SectionEnd
