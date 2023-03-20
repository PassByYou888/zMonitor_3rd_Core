{ ****************************************************************************** }
{ * Low MemoryHook                                                             * }
{ ****************************************************************************** }
unit M3C_MH;

{$I M3C_Define.inc}

interface

uses M3C_Core, SyncObjs, M3C_ListEngine;

procedure BeginMemoryHook_1;
procedure EndMemoryHook_1;
function GetHookMemorySize_1: nativeUInt;
function GetHookPtrList_1: TPointerHashNativeUIntList;

procedure BeginMemoryHook_2;
procedure EndMemoryHook_2;
function GetHookMemorySize_2: nativeUInt;
function GetHookPtrList_2: TPointerHashNativeUIntList;

procedure BeginMemoryHook_3;
procedure EndMemoryHook_3;
function GetHookMemorySize_3: nativeUInt;
function GetHookPtrList_3: TPointerHashNativeUIntList;

implementation

uses M3C_MH_ZDB, M3C_MH1, M3C_MH2, M3C_MH3, M3C_Status, M3C_PascalStrings, M3C_UPascalStrings;

procedure BeginMemoryHook_1;
begin
  M3C_MH1.BeginMemoryHook($FFFF);
end;

procedure EndMemoryHook_1;
begin
  M3C_MH1.EndMemoryHook;
end;

function GetHookMemorySize_1: nativeUInt;
begin
  Result := M3C_MH1.GetHookMemorySize;
end;

function GetHookPtrList_1: TPointerHashNativeUIntList;
begin
  Result := M3C_MH1.GetHookPtrList;
end;

procedure BeginMemoryHook_2;
begin
  M3C_MH2.BeginMemoryHook($FFFF);
end;

procedure EndMemoryHook_2;
begin
  M3C_MH2.EndMemoryHook;
end;

function GetHookMemorySize_2: nativeUInt;
begin
  Result := M3C_MH2.GetHookMemorySize;
end;

function GetHookPtrList_2: TPointerHashNativeUIntList;
begin
  Result := M3C_MH2.GetHookPtrList;
end;

procedure BeginMemoryHook_3;
begin
  M3C_MH3.BeginMemoryHook($FFFF);
end;

procedure EndMemoryHook_3;
begin
  M3C_MH3.EndMemoryHook;
end;

function GetHookMemorySize_3: nativeUInt;
begin
  Result := M3C_MH3.GetHookMemorySize;
end;

function GetHookPtrList_3: TPointerHashNativeUIntList;
begin
  Result := M3C_MH3.GetHookPtrList;
end;

var
  MHStatusCritical: TCriticalSection;
  OriginDoStatusHook: TDoStatus_C;

procedure InternalDoStatus(Text: SystemString; const ID: Integer);
var
  hook_state_bak: Boolean;
begin
  hook_state_bak := GlobalMemoryHook.V;
  GlobalMemoryHook.V := False;
  MHStatusCritical.Acquire;
  try
      OriginDoStatusHook(Text, ID);
  finally
    MHStatusCritical.Release;
    GlobalMemoryHook.V := hook_state_bak;
  end;
end;

initialization

MHStatusCritical := TCriticalSection.Create;
OriginDoStatusHook := OnDoStatusHook;
OnDoStatusHook := {$IFDEF FPC}@{$ENDIF FPC}InternalDoStatus;

finalization

DisposeObject(MHStatusCritical);
OnDoStatusHook := OriginDoStatusHook;

end.
