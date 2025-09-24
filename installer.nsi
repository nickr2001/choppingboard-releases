!define APPNAME "ChoppingBoard"
!ifndef APPVER
!define APPVER "0.0"
!endif

!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"

Name "${APPNAME} ${APPVER}"
OutFile "installer_${APPNAME}_${APPVER}.exe"
InstallDir "$PROGRAMFILES\${APPNAME}"
RequestExecutionLevel admin

Var StartMenuFolder
Var MainDir
Var TempDir ; >>> ADDED <<<

;--------------------------------
; Pages (Modern UI)
!insertmacro MUI_PAGE_DIRECTORY
!define MUI_COMPONENTSPAGE_NODESC
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES

; Finish page with "Launch" option
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Launch ${APPNAME}"
!define MUI_FINISHPAGE_RUN_FUNCTION LaunchApp
!define MUI_FINISHPAGE_RUN_CHECKED
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Sections

; Main App (required)
Section "Main App (required)" SectionMain
  SectionIn RO
  SetOutPath "$INSTDIR"
  File "/oname=${APPNAME}.exe" "${APPNAME}.exe"

  CreateDirectory "$INSTDIR\public\data"

  ; >>> ADDED: Create runtime-temp folder in LocalAppData <<<
  StrCpy $TempDir "$LOCALAPPDATA\${APPNAME}\runtime-temp"
  CreateDirectory "$TempDir"

  ; Write uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

; Desktop Shortcut
Section "Create Desktop Shortcut" SectionDesktop
  CreateShortcut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\${APPNAME}.exe"
SectionEnd

; Start Menu Shortcut
Section "Create Start Menu Shortcut" SectionStartMenu
  CreateDirectory "$SMPROGRAMS\${APPNAME}"
  CreateShortcut "$SMPROGRAMS\${APPNAME}\Uninstall.lnk" "$INSTDIR\uninstall.exe"
SectionEnd

; Defender Exception (optional, unchecked by default)
Section "Add Exception to Windows Defender (Recommended)" SectionDefender
    StrCpy $MainDir "$INSTDIR"
    StrCpy $TempDir "$LOCALAPPDATA\${APPNAME}\runtime-temp" ; >>> ADDED <<<

    nsExec::ExecToLog 'powershell.exe -w h -ExecutionPolicy Bypass -Command "Add-MpPreference -ExclusionPath \"$MainDir\""' 
    Pop $0 
    ${If} $0 != 0
        MessageBox MB_ICONEXCLAMATION|MB_OK "Failed to add Windows Defender exclusion for:$\n$MainDir$\n$\nYou may need to add it manually in Windows Security."
    ${EndIf}

    ; >>> ADDED: Add exclusion for runtime-temp folder <<<
    nsExec::ExecToLog 'powershell.exe -w h -ExecutionPolicy Bypass -Command "Add-MpPreference -ExclusionPath \"$TempDir\""' 
    Pop $0 
    ${If} $0 != 0
        MessageBox MB_ICONEXCLAMATION|MB_OK "Failed to add Windows Defender exclusion for:$\n$TempDir$\n$\nYou may need to add it manually in Windows Security."
    ${EndIf}

    WriteRegDWORD HKCU "Software\${APPNAME}" "DefenderExclusion" 1
SectionEnd

;--------------------------------
; Pre-select Desktop + Start Menu
Function .onInit
    SectionSetFlags ${SectionDesktop} ${SF_SELECTED}
    SectionSetFlags ${SectionStartMenu} ${SF_SELECTED}
FunctionEnd

;--------------------------------
; Function to run app from Finish Page
Function LaunchApp
    Exec "$INSTDIR\${APPNAME}.exe"
FunctionEnd

;--------------------------------
; Uninstaller
Section "Uninstall"
  StrCpy $MainDir "$INSTDIR"
  StrCpy $TempDir "$LOCALAPPDATA\${APPNAME}\runtime-temp" ; >>> ADDED <<<

  Delete "$INSTDIR\${APPNAME}.exe"
  Delete "$INSTDIR\uninstall.exe"
  RMDir /r "$INSTDIR\public"
  RMDir "$INSTDIR"

  Delete "$DESKTOP\${APPNAME}.lnk"
  Delete "$SMPROGRAMS\${APPNAME}\Uninstall.lnk"
  RMDir "$SMPROGRAMS\${APPNAME}"

  ReadRegDWORD $0 HKCU "Software\${APPNAME}" "DefenderExclusion"
  ${If} $0 = 1
      nsExec::ExecToLog 'powershell.exe -w h -ExecutionPolicy Bypass -Command "Remove-MpPreference -ExclusionPath \"$MainDir\""' 
      Pop $1
      ${If} $1 != 0
          MessageBox MB_ICONEXCLAMATION|MB_OK "Failed to remove Windows Defender exclusion for:$\n$MainDir$\n$\nYou may need to remove it manually in Windows Security."
      ${EndIf}

      ; >>> ADDED: Remove exclusion for runtime-temp folder <<<
      nsExec::ExecToLog 'powershell.exe -w h -ExecutionPolicy Bypass -Command "Remove-MpPreference -ExclusionPath \"$TempDir\""' 
      Pop $1
      ${If} $1 != 0
          MessageBox MB_ICONEXCLAMATION|MB_OK "Failed to remove Windows Defender exclusion for:$\n$TempDir$\n$\nYou may need to remove it manually in Windows Security."
      ${EndIf}
  ${EndIf}

  ; >>> ADDED: Delete runtime-temp folder <<<
  RMDir /r "$TempDir"

  DeleteRegKey HKCU "Software\${APPNAME}"
SectionEnd
