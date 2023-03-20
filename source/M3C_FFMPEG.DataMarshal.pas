{ ****************************************************************************** }
{ * FFMPEG Data marshal v1.0                                                   * }
{ ****************************************************************************** }
unit M3C_FFMPEG.DataMarshal;

{$I M3C_Define.inc}

interface

uses SysUtils, DateUtils,
  M3C_Core,
{$IFDEF FPC}
  M3C_FPC.GenericList,
{$ENDIF FPC}
  M3C_PascalStrings, M3C_UPascalStrings, M3C_UnicodeMixedLib, M3C_Geometry2D,
  M3C_MemoryStream, M3C_HashList.Templet, M3C_DFE,
  M3C_Status, M3C_Cipher, M3C_ZDB2, M3C_ListEngine, M3C_TextDataEngine, M3C_Notify, M3C_IOThread,
  M3C_FFMPEG, M3C_FFMPEG.Writer, M3C_FFMPEG.Reader,
  M3C_ZDB2.Thread.Queue, M3C_ZDB2.Thread;

type
  TZDB2_FFMPEG_Data_Marshal = class;

  TZDB2_FFMPEG_Data_Head = class
  public
    Source, clip: U_String;
    PSF: Double;                         // per second frame
    Begin_Frame_ID, End_Frame_ID: Int64; // frame id
    Begin_Time, End_Time: TDateTime;     // time range
    constructor Create;
    destructor Destroy; override;
    procedure Encode(m64: TMS64);
    procedure Decode(m64: TMS64);
    function Frame_ID_As_Time(ID: Int64): TDateTime;
  end;

  TZDB2_FFMPEG_Data = class(TZDB2_Th_Engine_Data)
  private
    Sequence_ID: UInt64;
  public
    Owner_FFMPEG_Data_Marshal: TZDB2_FFMPEG_Data_Marshal;
    Head: TZDB2_FFMPEG_Data_Head;
    DataPosition: Int64;
    constructor Create; override;
    destructor Destroy; override;
  end;

  TFFMPEG_Data_Analysis_Struct = record
  public
    Num: NativeInt;
    LastTime: TDateTime;
    class function Null_(): TFFMPEG_Data_Analysis_Struct; static;
  end;

  TFFMPEG_Data_Analysis_Hash_Pool_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TString_Big_Hash_Pair_Pool<TFFMPEG_Data_Analysis_Struct>;

  TFFMPEG_Data_Analysis_Hash_Pool = class(TFFMPEG_Data_Analysis_Hash_Pool_Decl)
  public
    procedure IncValue(Key_: SystemString; Value_: Integer); overload;
    procedure IncValue(Key_: SystemString; Value_: Integer; LastTime: TDateTime); overload;
    procedure IncValue(Source: TFFMPEG_Data_Analysis_Hash_Pool); overload;
    procedure GetKeyList(output: TPascalStringList); overload;
    procedure GetKeyList(output: TCore_Strings); overload;
    function GetKeyArry: U_StringArray;
  end;

  TZDB2_FFMPEG_Data_Query_Result_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TCritical_BigList<TZDB2_FFMPEG_Data>;

  TZDB2_FFMPEG_Data_Query_Result = class(TZDB2_FFMPEG_Data_Query_Result_Decl)
  private
    FInstance_protected: Boolean;
    function Do_Sort_By_Time(var L, R: TZDB2_FFMPEG_Data): Integer;
  public
    Source_Analysis, clip_Analysis: TFFMPEG_Data_Analysis_Hash_Pool;
    constructor Create;
    destructor Destroy; override;
    procedure DoFree(var Data: TZDB2_FFMPEG_Data); override;
    procedure DoAdd(var Data: TZDB2_FFMPEG_Data); override;
    procedure SortByTime();
    function Extract_Source(Source: U_String; removed_: Boolean): TZDB2_FFMPEG_Data_Query_Result;
    function Extract_clip(clip: U_String; removed_: Boolean): TZDB2_FFMPEG_Data_Query_Result;
  end;

  TZDB2_FFMPEG_Data_Query_Result_Clip_Tool_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TCritical_BigList<TZDB2_FFMPEG_Data_Query_Result>;

  TZDB2_FFMPEG_Data_Query_Result_Clip_Tool = class(TZDB2_FFMPEG_Data_Query_Result_Clip_Tool_Decl)
  public
    procedure DoFree(var Data: TZDB2_FFMPEG_Data_Query_Result); override;
    procedure Extract_clip(Source: TZDB2_FFMPEG_Data_Query_Result);
  end;

  TZDB2_FFMPEG_Data_Th_Engine = class(TZDB2_Th_Engine)
  public
    constructor Create(Owner_: TZDB2_Th_Engine_Marshal);
    destructor Destroy; override;
  end;

  TZDB2_FFMPEG_Data_Marshal = class
  private
    Current_Sequence_ID: UInt64;
    procedure Do_Th_Data_Loaded(Sender: TZDB2_Th_Engine_Data; IO_: TMS64);
    function Do_Sort_By_Sequence_ID(var L, R: TZDB2_Th_Engine_Data): Integer;
  public
    Critical: TCritical;
    ZDB2_Eng: TZDB2_Th_Engine_Marshal;
    Source_Analysis: TFFMPEG_Data_Analysis_Hash_Pool;
    clip_Analysis: TFFMPEG_Data_Analysis_Hash_Pool;
    constructor Create;
    destructor Destroy; override;
    function BuildMemory(): TZDB2_FFMPEG_Data_Th_Engine;
    // if encrypt=true defualt password 'DTC40@ZSERVER'
    function BuildOrOpen(FileName_: U_String; OnlyRead_, Encrypt_: Boolean): TZDB2_FFMPEG_Data_Th_Engine; overload;
    // if encrypt=true defualt password 'DTC40@ZSERVER'
    function BuildOrOpen(FileName_: U_String; OnlyRead_, Encrypt_: Boolean; cfg: THashStringList): TZDB2_FFMPEG_Data_Th_Engine; overload;
    function Begin_Custom_Build: TZDB2_FFMPEG_Data_Th_Engine;
    function End_Custom_Build(Eng_: TZDB2_FFMPEG_Data_Th_Engine): Boolean;
    procedure Extract_Video_Data_Pool(ThNum_: Integer);
    function Add_Video_Data(
      Source, clip: U_String;
      PSF: Double;                         // per second frame
      Begin_Frame_ID, End_Frame_ID: Int64; // frame id
      Begin_Time, End_Time: TDateTime;     // time range
      const body: TMS64; const AutoFree_: Boolean): TZDB2_FFMPEG_Data;
    // in thread query
    function Query_Video_Data(Parallel_: Boolean; ThNum_: Integer; Instance_protected: Boolean;
      Source, clip: U_String; Begin_Time, End_Time: TDateTime): TZDB2_FFMPEG_Data_Query_Result;
    procedure Clear(Delete_Data_: Boolean);
    // flush
    procedure Flush;
    // fragment number
    function Num: NativeInt;
    // recompute totalfragment number
    function Total: NativeInt;
    // database space state
    function Database_Size: Int64;
    function Database_Physics_Size: Int64;
    // RemoveDatabaseOnDestroy
    function GetRemoveDatabaseOnDestroy: Boolean;
    procedure SetRemoveDatabaseOnDestroy(const Value: Boolean);
    property RemoveDatabaseOnDestroy: Boolean read GetRemoveDatabaseOnDestroy write SetRemoveDatabaseOnDestroy;
    // wait queue
    procedure Wait();
  end;

implementation

constructor TZDB2_FFMPEG_Data_Head.Create;
begin
  inherited Create;
  Source := '';
  clip := '';
  PSF := 0;
  Begin_Frame_ID := 0;
  End_Frame_ID := 0;
  Begin_Time := 0;
  End_Time := 0;
end;

destructor TZDB2_FFMPEG_Data_Head.Destroy;
begin
  Source := '';
  clip := '';
  inherited Destroy;
end;

procedure TZDB2_FFMPEG_Data_Head.Encode(m64: TMS64);
begin
  m64.WriteString(Source);
  m64.WriteString(clip);
  m64.WriteDouble(PSF);
  m64.WriteInt64(Begin_Frame_ID);
  m64.WriteInt64(End_Frame_ID);
  m64.WriteDouble(Begin_Time);
  m64.WriteDouble(End_Time);
end;

procedure TZDB2_FFMPEG_Data_Head.Decode(m64: TMS64);
begin
  Source := m64.ReadString;
  clip := m64.ReadString;
  PSF := m64.ReadDouble;
  Begin_Frame_ID := m64.ReadInt64;
  End_Frame_ID := m64.ReadInt64;
  Begin_Time := m64.ReadDouble;
  End_Time := m64.ReadDouble;
end;

function TZDB2_FFMPEG_Data_Head.Frame_ID_As_Time(ID: Int64): TDateTime;
begin
  Result := IncMilliSecond(Begin_Time, round((ID - Begin_Frame_ID) / PSF * 1000));
end;

constructor TZDB2_FFMPEG_Data.Create;
begin
  inherited Create;
  Sequence_ID := 0;
  Owner_FFMPEG_Data_Marshal := nil;
  Head := TZDB2_FFMPEG_Data_Head.Create;
  DataPosition := 0;
end;

destructor TZDB2_FFMPEG_Data.Destroy;
begin
  if Owner_FFMPEG_Data_Marshal <> nil then
    begin
      Owner_FFMPEG_Data_Marshal.Critical.Lock;
      Owner_FFMPEG_Data_Marshal.Source_Analysis.IncValue(Head.Source, -1);
      Owner_FFMPEG_Data_Marshal.clip_Analysis.IncValue(Head.clip, -1);
      Owner_FFMPEG_Data_Marshal.Critical.UnLock;
    end;
  DisposeObject(Head);
  inherited Destroy;
end;

class function TFFMPEG_Data_Analysis_Struct.Null_: TFFMPEG_Data_Analysis_Struct;
begin
  Result.Num := 0;
  Result.LastTime := 0;
end;

procedure TFFMPEG_Data_Analysis_Hash_Pool.IncValue(Key_: SystemString; Value_: Integer);
var
  p: TFFMPEG_Data_Analysis_Hash_Pool_Decl.PValue;
begin
  p := Get_Value_Ptr(Key_);
  Inc(p^.Num, Value_);
end;

procedure TFFMPEG_Data_Analysis_Hash_Pool.IncValue(Key_: SystemString; Value_: Integer; LastTime: TDateTime);
var
  p: TFFMPEG_Data_Analysis_Hash_Pool_Decl.PValue;
begin
  p := Get_Value_Ptr(Key_);
  Inc(p^.Num, Value_);
  if CompareDateTime(LastTime, p^.LastTime) > 0 then
      p^.LastTime := LastTime;
end;

procedure TFFMPEG_Data_Analysis_Hash_Pool.IncValue(Source: TFFMPEG_Data_Analysis_Hash_Pool);
var
  __repeat__: TFFMPEG_Data_Analysis_Hash_Pool_Decl.TRepeat___;
begin
  if Source.Num <= 0 then
      exit;
  __repeat__ := Source.Repeat_;
  repeat
      IncValue(__repeat__.Queue^.Data^.Data.Primary, __repeat__.Queue^.Data^.Data.Second.Num, __repeat__.Queue^.Data^.Data.Second.LastTime);
  until not __repeat__.Next;
end;

procedure TFFMPEG_Data_Analysis_Hash_Pool.GetKeyList(output: TPascalStringList);
var
  __repeat__: TFFMPEG_Data_Analysis_Hash_Pool_Decl.TRepeat___;
begin
  if Num <= 0 then
      exit;
  __repeat__ := Repeat_;
  repeat
      output.Add(__repeat__.Queue^.Data^.Data.Primary);
  until not __repeat__.Next;
end;

procedure TFFMPEG_Data_Analysis_Hash_Pool.GetKeyList(output: TCore_Strings);
var
  __repeat__: TFFMPEG_Data_Analysis_Hash_Pool_Decl.TRepeat___;
begin
  if Num <= 0 then
      exit;
  __repeat__ := Repeat_;
  repeat
      output.Add(__repeat__.Queue^.Data^.Data.Primary);
  until not __repeat__.Next;
end;

function TFFMPEG_Data_Analysis_Hash_Pool.GetKeyArry: U_StringArray;
var
  __repeat__: TFFMPEG_Data_Analysis_Hash_Pool_Decl.TRepeat___;
begin
  SetLength(Result, Num);
  if Num <= 0 then
      exit;
  __repeat__ := Repeat_;
  repeat
      Result[__repeat__.I__] := __repeat__.Queue^.Data^.Data.Primary;
  until not __repeat__.Next;
end;

function TZDB2_FFMPEG_Data_Query_Result.Do_Sort_By_Time(var L, R: TZDB2_FFMPEG_Data): Integer;
begin
  Result := umlCompareText(L.Head.Source, R.Head.Source);
  if Result = 0 then
    begin
      Result := umlCompareText(L.Head.clip, R.Head.clip);
      if Result = 0 then
          Result := CompareDateTime(L.Head.Begin_Time, R.Head.Begin_Time);
    end;
end;

constructor TZDB2_FFMPEG_Data_Query_Result.Create;
begin
  inherited Create;
  FInstance_protected := False;
  Source_Analysis := TFFMPEG_Data_Analysis_Hash_Pool.Create($FF, TFFMPEG_Data_Analysis_Struct.Null_);
  clip_Analysis := TFFMPEG_Data_Analysis_Hash_Pool.Create($FF, TFFMPEG_Data_Analysis_Struct.Null_);
end;

destructor TZDB2_FFMPEG_Data_Query_Result.Destroy;
begin
  Clear;
  DisposeObjectAndNil(Source_Analysis);
  DisposeObjectAndNil(clip_Analysis);
  inherited Destroy;
end;

procedure TZDB2_FFMPEG_Data_Query_Result.DoFree(var Data: TZDB2_FFMPEG_Data);
begin
  if Data <> nil then
    begin
      if Source_Analysis <> nil then
          Source_Analysis.IncValue(Data.Head.Source, -1);
      if clip_Analysis <> nil then
          clip_Analysis.IncValue(Data.Head.clip, -1);
      if FInstance_protected then
        begin
          Data.Update_Instance_As_Free;
          Data := nil;
        end;
    end;
  inherited DoFree(Data);
end;

procedure TZDB2_FFMPEG_Data_Query_Result.DoAdd(var Data: TZDB2_FFMPEG_Data);
begin
  if Data <> nil then
    begin
      if Source_Analysis <> nil then
          Source_Analysis.IncValue(Data.Head.Source, 1);
      if clip_Analysis <> nil then
          clip_Analysis.IncValue(Data.Head.clip, 1);
      if FInstance_protected then
          Data.Update_Instance_As_Busy;
    end;
  inherited DoAdd(Data);
end;

procedure TZDB2_FFMPEG_Data_Query_Result.SortByTime;
begin
  Sort_M({$IFDEF FPC}@{$ENDIF FPC}Do_Sort_By_Time);
end;

function TZDB2_FFMPEG_Data_Query_Result.Extract_Source(Source: U_String; removed_: Boolean): TZDB2_FFMPEG_Data_Query_Result;
begin
  Result := TZDB2_FFMPEG_Data_Query_Result.Create;
  if Num > 0 then
    begin
      with Repeat_ do
        repeat
          if Source.Same(@Queue^.Data.Head.Source) then
            begin
              Result.Add(Queue^.Data);
              if removed_ then
                  Push_To_Recycle_Pool(Queue);
            end;
        until not Next;
      Free_Recycle_Pool;
    end;
end;

function TZDB2_FFMPEG_Data_Query_Result.Extract_clip(clip: U_String; removed_: Boolean): TZDB2_FFMPEG_Data_Query_Result;
begin
  Result := TZDB2_FFMPEG_Data_Query_Result.Create;
  if Num > 0 then
    begin
      with Repeat_ do
        repeat
          if clip.Same(@Queue^.Data.Head.clip) then
            begin
              Result.Add(Queue^.Data);
              if removed_ then
                  Push_To_Recycle_Pool(Queue);
            end;
        until not Next;
      Free_Recycle_Pool;
    end;
end;

procedure TZDB2_FFMPEG_Data_Query_Result_Clip_Tool.DoFree(var Data: TZDB2_FFMPEG_Data_Query_Result);
begin
  DisposeObjectAndNil(Data);
  inherited DoFree(Data);
end;

procedure TZDB2_FFMPEG_Data_Query_Result_Clip_Tool.Extract_clip(Source: TZDB2_FFMPEG_Data_Query_Result);
var
  tmp: TZDB2_FFMPEG_Data_Query_Result;

  procedure do_exctract_tmp_frag_clip_and_free();
  begin
    if tmp.clip_Analysis.Num > 0 then
      begin
        with tmp.clip_Analysis.Repeat_ do
          repeat
              Add(tmp.Extract_clip(Queue^.Data^.Data.Primary, True));
          until not Next;
      end;
    DisposeObject(tmp);
  end;

begin
  Clear;
  if Source.Source_Analysis.Num > 0 then
    with Source.Source_Analysis.Repeat_ do
      repeat
        tmp := Source.Extract_Source(Queue^.Data^.Data.Primary, True);
        do_exctract_tmp_frag_clip_and_free();
      until not Next;
end;

constructor TZDB2_FFMPEG_Data_Th_Engine.Create(Owner_: TZDB2_Th_Engine_Marshal);
begin
  inherited Create(Owner_);
end;

destructor TZDB2_FFMPEG_Data_Th_Engine.Destroy;
begin
  inherited Destroy;
end;

procedure TZDB2_FFMPEG_Data_Marshal.Do_Th_Data_Loaded(Sender: TZDB2_Th_Engine_Data; IO_: TMS64);
var
  obj_: TZDB2_FFMPEG_Data;
begin
  obj_ := Sender as TZDB2_FFMPEG_Data;
  obj_.Owner_FFMPEG_Data_Marshal := self;

  IO_.Position := 0;
  obj_.Sequence_ID := IO_.ReadUInt64; // sequence id
  obj_.Head.Decode(IO_);              // head info
  obj_.DataPosition := IO_.Position;  // data body
end;

function TZDB2_FFMPEG_Data_Marshal.Do_Sort_By_Sequence_ID(var L, R: TZDB2_Th_Engine_Data): Integer;
begin
  Result := CompareUInt64(TZDB2_FFMPEG_Data(L).Sequence_ID, TZDB2_FFMPEG_Data(R).Sequence_ID);
end;

constructor TZDB2_FFMPEG_Data_Marshal.Create;
begin
  inherited Create;
  Current_Sequence_ID := 1;
  Critical := TCritical.Create;
  ZDB2_Eng := TZDB2_Th_Engine_Marshal.Create;
  ZDB2_Eng.Current_Data_Class := TZDB2_FFMPEG_Data;
  Source_Analysis := TFFMPEG_Data_Analysis_Hash_Pool.Create($FFFF, TFFMPEG_Data_Analysis_Struct.Null_);
  clip_Analysis := TFFMPEG_Data_Analysis_Hash_Pool.Create($FFFF, TFFMPEG_Data_Analysis_Struct.Null_);
end;

destructor TZDB2_FFMPEG_Data_Marshal.Destroy;
begin
  DisposeObject(ZDB2_Eng);
  DisposeObject(Source_Analysis);
  DisposeObject(clip_Analysis);
  DisposeObject(Critical);
  inherited Destroy;
end;

function TZDB2_FFMPEG_Data_Marshal.BuildMemory(): TZDB2_FFMPEG_Data_Th_Engine;
begin
  Result := TZDB2_FFMPEG_Data_Th_Engine.Create(ZDB2_Eng);
  Result.Mode := smBigData;
  Result.Database_File := '';
  Result.OnlyRead := False;
  Result.Cipher_Security := TCipherSecurity.csNone;
  Result.Build(ZDB2_Eng.Current_Data_Class);
end;

function TZDB2_FFMPEG_Data_Marshal.BuildOrOpen(FileName_: U_String; OnlyRead_, Encrypt_: Boolean): TZDB2_FFMPEG_Data_Th_Engine;
begin
  Result := TZDB2_FFMPEG_Data_Th_Engine.Create(ZDB2_Eng);
  Result.Mode := smNormal;
  Result.Database_File := FileName_;
  Result.OnlyRead := OnlyRead_;

  if Encrypt_ then
      Result.Cipher_Security := TCipherSecurity.csRijndael
  else
      Result.Cipher_Security := TCipherSecurity.csNone;

  Result.Build(ZDB2_Eng.Current_Data_Class);
  if not Result.Ready then
    begin
      DisposeObjectAndNil(Result);
      Result := BuildMemory();
    end;
end;

function TZDB2_FFMPEG_Data_Marshal.BuildOrOpen(FileName_: U_String; OnlyRead_, Encrypt_: Boolean; cfg: THashStringList): TZDB2_FFMPEG_Data_Th_Engine;
begin
  Result := TZDB2_FFMPEG_Data_Th_Engine.Create(ZDB2_Eng);
  Result.Mode := smNormal;
  Result.Database_File := FileName_;
  Result.OnlyRead := OnlyRead_;
  if cfg <> nil then
      Result.ReadConfig(FileName_, cfg);

  if Encrypt_ then
      Result.Cipher_Security := TCipherSecurity.csRijndael
  else
      Result.Cipher_Security := TCipherSecurity.csNone;

  Result.Build(ZDB2_Eng.Current_Data_Class);
  if not Result.Ready then
    begin
      DisposeObjectAndNil(Result);
      Result := BuildMemory();
    end;
end;

function TZDB2_FFMPEG_Data_Marshal.Begin_Custom_Build: TZDB2_FFMPEG_Data_Th_Engine;
begin
  Result := TZDB2_FFMPEG_Data_Th_Engine.Create(ZDB2_Eng);
end;

function TZDB2_FFMPEG_Data_Marshal.End_Custom_Build(Eng_: TZDB2_FFMPEG_Data_Th_Engine): Boolean;
begin
  Eng_.Build(ZDB2_Eng.Current_Data_Class);
  Result := Eng_.Ready;
end;

procedure TZDB2_FFMPEG_Data_Marshal.Extract_Video_Data_Pool(ThNum_: Integer);
var
  __repeat__: TFFMPEG_Data_Analysis_Hash_Pool_Decl.TRepeat___;
begin
  ZDB2_Eng.Parallel_Load_M(ThNum_, {$IFDEF FPC}@{$ENDIF FPC}Do_Th_Data_Loaded, nil);

  Current_Sequence_ID := 1;
  if ZDB2_Eng.Data_Marshal.Num > 0 then
    begin
      Critical.Lock;
      // compute analysis
      with ZDB2_Eng.Data_Marshal.Repeat_ do
        repeat
          Source_Analysis.IncValue(TZDB2_FFMPEG_Data(Queue^.Data).Head.Source, 1, TZDB2_FFMPEG_Data(Queue^.Data).Head.End_Time);
          clip_Analysis.IncValue(TZDB2_FFMPEG_Data(Queue^.Data).Head.clip, 1, TZDB2_FFMPEG_Data(Queue^.Data).Head.End_Time);
        until not Next;
      ZDB2_Eng.Sort_M({$IFDEF FPC}@{$ENDIF FPC}Do_Sort_By_Sequence_ID);
      Current_Sequence_ID := TZDB2_FFMPEG_Data(ZDB2_Eng.Data_Marshal.Last^.Data).Sequence_ID + 1;
      Critical.UnLock;

      if Source_Analysis.Num > 0 then
        begin
          __repeat__ := Source_Analysis.Repeat_;
          repeat
              DoStatus('source:"%s" fragment analysis:%d last time %s', [
                __repeat__.Queue^.Data^.Data.Primary,
                __repeat__.Queue^.Data^.Data.Second.Num,
                DateTimeToStr(__repeat__.Queue^.Data^.Data.Second.LastTime)]);
          until not __repeat__.Next;
        end;

      DoStatus('finish compute analysis and rebuild sequence, total num:%d, classifier/clip:%d/%d, last sequence id:%d',
        [ZDB2_Eng.Data_Marshal.Num, Source_Analysis.Num, clip_Analysis.Num, Current_Sequence_ID]);
    end;
end;

function TZDB2_FFMPEG_Data_Marshal.Add_Video_Data(
  Source, clip: U_String;
  PSF: Double;                         // per second frame
  Begin_Frame_ID, End_Frame_ID: Int64; // frame id
  Begin_Time, End_Time: TDateTime;     // time range
  const body: TMS64; const AutoFree_: Boolean): TZDB2_FFMPEG_Data;
var
  tmp: TMS64;
begin
  Critical.Lock;
  Result := ZDB2_Eng.Add_Data_To_Minimize_Size_Engine as TZDB2_FFMPEG_Data;
  if Result <> nil then
    begin
      // update sequence id
      Result.Sequence_ID := Current_Sequence_ID;
      Inc(Current_Sequence_ID);

      // extract video info
      Result.Head.Source := Source;
      Result.Head.clip := clip;
      Result.Head.PSF := PSF;
      Result.Head.Begin_Frame_ID := Begin_Frame_ID;
      Result.Head.End_Frame_ID := End_Frame_ID;
      Result.Head.Begin_Time := Begin_Time;
      Result.Head.End_Time := End_Time;

      // rebuild sequence memory
      tmp := TMS64.Create;
      tmp.WriteUInt64(Result.Sequence_ID);
      Result.Head.Encode(tmp);
      Result.DataPosition := tmp.Position; // update data entry
      tmp.WritePtr(body.Memory, body.Size);
      Result.Async_Save_And_Free_Data(tmp);

      if AutoFree_ then
          DisposeObject(body);

      // compute time analysis
      Source_Analysis.IncValue(Result.Head.Source, 1, Result.Head.End_Time);
      clip_Analysis.IncValue(Result.Head.clip, 1, Result.Head.End_Time);
    end;
  Critical.UnLock;
end;

function TZDB2_FFMPEG_Data_Marshal.Query_Video_Data(Parallel_: Boolean; ThNum_: Integer; Instance_protected: Boolean;
  Source, clip: U_String; Begin_Time, End_Time: TDateTime): TZDB2_FFMPEG_Data_Query_Result;
var
  R: TZDB2_FFMPEG_Data_Query_Result;
{$IFDEF FPC}
  procedure fpc_progress_(Sender: TZDB2_Th_Engine_Data; Index: Int64; var Aborted: Boolean);
  var
    d: TZDB2_FFMPEG_Data;
  begin
    d := Sender as TZDB2_FFMPEG_Data;
    if umlSearchMatch(Source, d.Head.Source) and umlSearchMatch(clip, d.Head.clip) then
      begin
        if DateTimeInRange(d.Head.Begin_Time, Begin_Time, End_Time) or
          DateTimeInRange(d.Head.End_Time, Begin_Time, End_Time) or
          DateTimeInRange(Begin_Time, d.Head.Begin_Time, d.Head.End_Time) or
          DateTimeInRange(End_Time, d.Head.Begin_Time, d.Head.End_Time) then
            R.Add(d);
      end;
  end;
{$ENDIF FPC}


begin
  R := TZDB2_FFMPEG_Data_Query_Result.Create;
  R.FInstance_protected := Instance_protected;
{$IFDEF FPC}
  ZDB2_Eng.For_P(Parallel_, ThNum_, @fpc_progress_);
{$ELSE FPC}
  ZDB2_Eng.For_P(Parallel_, ThNum_, procedure(Sender: TZDB2_Th_Engine_Data; Index: Int64; var Aborted: Boolean)
    var
      d: TZDB2_FFMPEG_Data;
    begin
      d := Sender as TZDB2_FFMPEG_Data;
      if umlSearchMatch(Source, d.Head.Source) and umlSearchMatch(clip, d.Head.clip) then
        begin
          if DateTimeInRange(d.Head.Begin_Time, Begin_Time, End_Time) or
            DateTimeInRange(d.Head.End_Time, Begin_Time, End_Time) or
            DateTimeInRange(Begin_Time, d.Head.Begin_Time, d.Head.End_Time) or
            DateTimeInRange(End_Time, d.Head.Begin_Time, d.Head.End_Time) then
              R.Add(d);
        end;
    end);
{$ENDIF FPC}
  R.SortByTime();
  Result := R;
end;

procedure TZDB2_FFMPEG_Data_Marshal.Clear(Delete_Data_: Boolean);
begin
  if ZDB2_Eng.Data_Marshal.Num <= 0 then
      exit;

  if Delete_Data_ then
    begin
      ZDB2_Eng.Wait_Busy_task();
      with ZDB2_Eng.Data_Marshal.Repeat_ do
        repeat
            Queue^.Data.Remove(True);
        until not Next;
      ZDB2_Eng.Wait_Busy_task();
    end
  else
    begin
      ZDB2_Eng.Clear;
    end;
end;

procedure TZDB2_FFMPEG_Data_Marshal.Flush;
begin
  ZDB2_Eng.Flush;
end;

function TZDB2_FFMPEG_Data_Marshal.Num: NativeInt;
begin
  Result := ZDB2_Eng.Data_Marshal.Num;
end;

function TZDB2_FFMPEG_Data_Marshal.Total: NativeInt;
begin
  Result := ZDB2_Eng.Total;
end;

function TZDB2_FFMPEG_Data_Marshal.Database_Size: Int64;
begin
  Result := ZDB2_Eng.Database_Size;
end;

function TZDB2_FFMPEG_Data_Marshal.Database_Physics_Size: Int64;
begin
  Result := ZDB2_Eng.Database_Physics_Size;
end;

function TZDB2_FFMPEG_Data_Marshal.GetRemoveDatabaseOnDestroy: Boolean;
begin
  Result := ZDB2_Eng.RemoveDatabaseOnDestroy;
end;

procedure TZDB2_FFMPEG_Data_Marshal.SetRemoveDatabaseOnDestroy(const Value: Boolean);
begin
  ZDB2_Eng.RemoveDatabaseOnDestroy := Value;
end;

procedure TZDB2_FFMPEG_Data_Marshal.Wait;
begin
  ZDB2_Eng.Wait_Busy_task;
end;

end.
