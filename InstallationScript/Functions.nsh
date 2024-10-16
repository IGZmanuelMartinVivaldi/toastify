!include LogicLib.nsh
!include FileFunc.nsh
!include .\NSISpcre.nsh

!insertmacro REMatches


; FileExists is already part of LogicLib, but returns true for directories as well as files
!macro _FileExists2 _a _b _t _f
	!insertmacro _LOGICLIB_TEMP
	StrCpy $_LOGICLIB_TEMP "0"
	StrCmp `${_b}` `` +4 0         ; if path is not blank, continue to next check
	IfFileExists `${_b}` `0` +3    ; if path exists, continue to next check (IfFileExists returns true if this is a directory)
	IfFileExists `${_b}\*.*` +2 0  ; if path is not a directory, continue to confirm exists
	StrCpy $_LOGICLIB_TEMP "1"     ; file exists
	; now we have a definitive value - the file exists or it does not
	StrCmp $_LOGICLIB_TEMP "1" `${_t}` `${_f}`
!macroend
!undef FileExists

!define FileExists `"" FileExists2`
!macro _DirExists _a _b _t _f
	!insertmacro _LOGICLIB_TEMP
	StrCpy $_LOGICLIB_TEMP "0"	
	StrCmp `${_b}` `` +3 0        ; if path is not blank, continue to next check
	IfFileExists `${_b}\*.*` 0 +2 ; if directory exists, continue to confirm exists
	StrCpy $_LOGICLIB_TEMP "1"
	StrCmp $_LOGICLIB_TEMP "1" `${_t}` `${_f}`
!macroend
!define DirExists `"" DirExists`


;--------------------------------
; Function Macros

!macro _TrimQuotes Input Output
  Push `${Input}`
  Call TrimQuotes
  Pop ${Output}
!macroend
!define TrimQuotes `!insertmacro _TrimQuotes`


!macro _TerminateToastify MutexName
  Push `${MutexName}`
  Call TerminateToastify
!macroend
!define TerminateToastify `!insertmacro _TerminateToastify`


;--------------------------------
; Functions

; TrimQuotes
; Usage:
;   StrCpy $0 `"blah"`
;   ${TrimQuotes} $0 $0
Function TrimQuotes
  Exch $R0
  Push $R1
 
  StrCpy $R1 $R0 1
  StrCmp $R1 `"` 0 +2
    StrCpy $R0 $R0 `` 1
  StrCpy $R1 $R0 1 -1
  StrCmp $R1 `"` 0 +2
    StrCpy $R0 $R0 -1
 
  Pop $R1
  Exch $R0
FunctionEnd


;--------------------------------

; TerminateToastify
; Usage:
;   ${TerminateToastify} $MutexName
Function TerminateToastify
  Exch $R0
  Push $R1

  System::Call 'kernel32::OpenMutex(i 0x100000, b 0, t "$R0") i .R1'
  ${If} $R1 != 0
    # Kill Toastify
    System::Call 'kernel32::CloseHandle(i $R1)'
    DetailPrint "Shutting down ${APPNAME}..."
    KillProc::KillProc "Toastify.exe"
    Sleep 2000
  ${EndIf}

  Pop $R1
  Pop $R0
FunctionEnd


Function UninstallPreviousVersions
  Push $R0
  Push $R1

  ReadRegStr $R0 HKLM "${RegUninstallKey}" "UninstallString"
  ${If} $R0 != ""
    ${TrimQuotes} $R0 $R0
    ${GetParent} $R0 $R1

    ClearErrors
    ExecWait '$R0 /S /W _?=$R1'
    RMDir /r "$R1"
  ${EndIf}

  Pop $R1
  Pop $R0
FunctionEnd
