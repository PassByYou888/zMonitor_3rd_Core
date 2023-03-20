{ ****************************************************************************** }
{ * Low MemoryHook                                                             * }
{ ****************************************************************************** }

unit M3C_MH2;

{$I M3C_Define.inc}

interface

uses M3C_ListEngine, M3C_Core;

procedure BeginMemoryHook; overload;
procedure BeginMemoryHook(cacheLen: Integer); overload;
procedure EndMemoryHook;
function GetHookMemorySize: nativeUInt; overload;
function GetHookMemorySize(p: Pointer): nativeUInt; overload;
function GetHookMemoryMinimizePtr: Pointer;
function GetHookMemoryMaximumPtr: Pointer;
function GetHookPtrList: TPointerHashNativeUIntList;
function GetMemoryHooked: TAtomBool;

implementation

var
  HookPtrList: TPointerHashNativeUIntList;
  MemoryHooked: TAtomBool;

{$IFDEF FPC}
{$I M3C_MH_fpc.inc}
{$ELSE}
{$I M3C_MH_delphi.inc}
{$ENDIF}

initialization

InstallMemoryHook;

finalization

UnInstallMemoryHook;

end.
