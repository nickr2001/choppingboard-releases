!include "MUI2.nsh"
!include "LogicLib.nsh"

;--------------------------------
!define APPNAME "ChoppingBoard"

; Allow APPVER to be passed in from GitHub Actions
!ifndef APPVER
  !define APPVER "v0.0"
!endif

!define UNINSTALLERNAME "Uninstall_${APPNAME}.exe"

Name "${APPNAME} ${APPVER}"
OutFile "installer_${APPNAME}_${APPVER}.exe"
InstallDir "$PROGRAMFILES"

Var MainDir

;--------------------------------
; Sections
Section "Main App (required)" SectionMain
    SectionIn RO
    StrCpy $MainDir "$INSTDIR\${APPNAME}"
    SetOutPath "$MainDir"

    ; Copy the executable (should be next to installer.nsi)
    File "${APPNAME}.exe"

    CreateDirectory "$MainDir\public\data"
SectionEnd

Section "Create Desktop Shortcut" SectionDesktop
    CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\${APPNAME}\${APPNAME}.exe"
SectionEnd

Section "Create Start Menu Shortcut" SectionStartMenu
    CreateDirectory "$SMPROGRAMS\${APPNAME}"
    CreateShortCut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\${APPNAME}\${APPNAME}.exe"
SectionEnd

; Pre-select optional sections
Function .onInit
    SectionSetFlags ${SectionDesktop} ${SF_SELECTED}
    SectionSetFlags ${SectionStartMenu} ${SF_SELECTED}
FunctionEnd

; Pages
!insertmacro MUI_PAGE_DIRECTORY
!define MUI_COMPONENTSPAGE_NODESC
!insertmacro MUI_PAGE_COMPONENTS
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "${APPNAME}"
!insertmacro MUI_PAGE_STARTMENU Application $0
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Post-install: Write uninstaller and registry entries
Section -Post
    StrCpy $MainDir "$INSTDIR\${APPNAME}"

    WriteUninstaller "$INSTDIR\${UNINSTALLERNAME}"

    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$INSTDIR\${UNINSTALLERNAME} _?=$INSTDIR"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayIcon" "$INSTDIR\${APPNAME}\${APPNAME}.exe"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "Your Company Name"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayVersion" "${APPVER}"
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoModify" 1
    WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoRepair" 1
SectionEnd

;--------------------------------
; Optional: Windows Defender Exclusion
Section "Add Exception to Windows Defender (Recommended)" SectionDefender
    ; Not selected by default
    SectionSetFlags ${SectionDefender} ${SF_UNSELECTED}

    StrCpy $MainDir "$INSTDIR\${APPNAME}"

    ; Run PowerShell command with proper quoting
    nsExec::ExecToLog 'powershell.exe -w h -ExecutionPolicy Bypass -Command "Add-MpPreference -ExclusionPath \"$MainDir\""' 
    Pop $0 ; get exit code

    ${If} $0 != 0
        MessageBox MB_ICONEXCLAMATION|MB_OK "Failed to add Windows Defender exclusion for:$\n$MainDir$\n$\nYou may need to add it manually in Windows Security."
    ${EndIf}
SectionEnd

;--------------------------------
; Uninstaller
Section "Uninstall"
    StrCpy $MainDir "$INSTDIR\${APPNAME}"

    ; Remove Windows Defender exclusion (ignore errors)
    nsExec::ExecToLog 'powershell.exe -w h -ExecutionPolicy Bypass -Command "Remove-MpPreference -ExclusionPath \"$MainDir\""' 
    Pop $0

    MessageBox MB_ICONQUESTION|MB_YESNO "Are you sure you want to uninstall ${APPNAME}?" IDNO CancelUninstall

    ClearErrors
    ExecWait 'taskkill /F /IM "${APPNAME}.exe"'

    ClearErrors
    Delete "$MainDir\${APPNAME}.exe"
    ${If} ${Errors}
        MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION "Cannot delete ${APPNAME}.exe. Close it if running and click Retry." IDRETRY RetryMain
        Goto SkipMain
    ${EndIf}
    Goto SkipMain

    RetryMain:
        ClearErrors
        Delete "$MainDir\${APPNAME}.exe"
        ${If} ${Errors}
            MessageBox MB_ICONEXCLAMATION "Still cannot delete ${APPNAME}.exe. Skipping."
        ${EndIf}

    SkipMain:
    SetFileAttributes "$MainDir\*.*" 0
    SetFileAttributes "$MainDir\public\data\*.*" 0

    RMDir /r /REBOOTOK "$MainDir\public\data"
    RMDir /r /REBOOTOK "$MainDir\public"

    Delete /REBOOTOK "$DESKTOP\${APPNAME}.lnk"
    Delete /REBOOTOK "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk"
    RMDir /r /REBOOTOK "$SMPROGRAMS\${APPNAME}"

    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
    RMDir /r /REBOOTOK "$MainDir"
    Delete /REBOOTOK "$INSTDIR\${UNINSTALLERNAME}"

    Goto EndUninstall

    CancelUninstall:
        Abort
    EndUninstall:
SectionEnd
