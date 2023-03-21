unit zMonitor_3rd_Core_Demo_Frm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.TabControl, FMX.Layouts, FMX.StdCtrls, FMX.Edit,
  FMX.ListBox, FMX.ComboEdit, FMX.DateTimeCtrls,

  FMX.DialogService,
  System.DateUtils,
  System.IOUtils,

  {  Basic library  }
  M3C_Core, M3C_PascalStrings, M3C_UPascalStrings,
  {  Functional support library derived from basic library  }
  M3C_HashList.Templet, M3C_ListEngine, M3C_UnicodeMixedLib, M3C_MemoryStream, M3C_DFE, M3C_Status, M3C_Geometry2D, M3C_Cipher,
  M3C_Expression, M3C_OpCode, {  Expression engine, mainly used in this demo to convert strings to floating-point, integer, and the like  }
  M3C_MemoryRaster, M3C_DrawEngine, {  Raster and rendering engine support library  }
  M3C_DrawEngine.SlowFMX, {  Graphics output library, which provides fast debugging support for the FMX framework on the hpc platform. Earlier versions of this library do not provide hpc fast debugging support  }
  M3C_FFMPEG, {  Ffmpeg api support library  }
  M3C_FFMPEG.Reader, {  Ffmpeg video decoding support library, which supports gpu acceleration  }
  M3C_FFMPEG.Writer, {  Ffmpeg raster coding support library  }
  M3C_FFMPEG.ExtractTool, {  The cross platform decoding support library for ffmpeg has better multi stream support than Reader, but the disadvantage is that the library does not support gpu  }
  M3C_ZDB2, M3C_ZDB2.Thread.Queue, M3C_ZDB2.Thread, {  Zdb2 database support system  }
  M3C_FFMPEG.DataMarshal; {  Ffmpeg data warehouse support library using zdb2 technology architecture  }

type
  TzMonitor_3rd_Core_Demo_Form = class(TForm)
    TabControl_: TTabControl;
    TabItem_Doc: TTabItem;
    DocMemo: TMemo;
    TabItem_VideoRec: TTabItem;
    TabItem_Replay: TTabItem;
    logMemo: TMemo;
    video_input_Layout: TLayout;
    video_input_lab: TLabel;
    video_input_Edit: TEdit;
    video_input_browse: TEditButton;
    Splitter1: TSplitter;
    resize_width_Layout: TLayout;
    resize_width_lab: TLabel;
    resize_width_Edit: TEdit;
    resize_height_Layout: TLayout;
    resize_height_lab: TLabel;
    resize_height_Edit: TEdit;
    split_frame_Layout: TLayout;
    split_frame_lab: TLabel;
    split_frame_Edit: TEdit;
    reader_use_gpu_CheckBox: TCheckBox;
    build_video_input_Button: TButton;
    Label1: TLabel;
    video_OpenDialog: TOpenDialog;
    fps_Timer: TTimer;
    Label2: TLabel;
    begin_time_Layout: TLayout;
    begin_time_Label: TLabel;
    begin_date_Edit: TDateEdit;
    begin_time_Edit: TTimeEdit;
    end_time_Layout: TLayout;
    end_time_Label: TLabel;
    end_date_Edit: TDateEdit;
    end_time_Edit: TTimeEdit;
    replay_name_Layout: TLayout;
    replay_name_lab: TLabel;
    replay_name_ComboEdit: TComboEdit;
    replay_name_refresh_Button: TButton;
    query_Button: TButton;
    replay_clip_Layout: TLayout;
    replay_clip_lab: TLabel;
    replay_clip_Edit: TEdit;
    used_query_th_CheckBox: TCheckBox;
    TabItem_ZDB2: TTabItem;
    abort_video_input_Button: TButton;
    zdb2_bak_Button: TButton;
    Label3: TLabel;
    remove_first_frag_Button: TButton;
    Label4: TLabel;
    procedure fps_TimerTimer(Sender: TObject);
    procedure video_input_browseClick(Sender: TObject);
    procedure abort_video_input_ButtonClick(Sender: TObject);
    procedure build_video_input_ButtonClick(Sender: TObject);
    procedure replay_name_refresh_ButtonClick(Sender: TObject);
    procedure query_ButtonClick(Sender: TObject);
    procedure zdb2_bak_ButtonClick(Sender: TObject);
    procedure remove_first_frag_ButtonClick(Sender: TObject);
  private
    procedure backcall_DoStatus(Text_: SystemString; const ID: Integer);
  public
    {  TZDB2_ FFMPEG_ Data_ Marshal is a video data engine specifically designed based on the ZDB2 engine  }
    {  The usage methods of zdb2 are tailored to target scenarios and requirements, and its data engine is designed  }
    {  Zdb2's data engine can support fully parallel data access, and can work in parallel with additions, deletions, queries, and modifications. It is suitable for deployment on HPC servers or highly configured workstations  }
    {  The zdb2 data engine is mostly used to solve data classification, data filtering, and data statistics. The structured support system is very easy to apply third-party statistics, such as projects such as ZAI and zAnalysis  }
    {  Big data processing process framework, zdb2 is the optimal technical system for the entire pas circle, and is used by many large projects  }
    {  As we usually see, databases such as MySQL and SQL Server focus on data management, while Zdb2 focuses on data engine design, especially solving complex data problems, including storage design, data structure design, and algorithm design  }
    Video_DB: TZDB2_FFMPEG_Data_Marshal;

    {  The state controller TAtomBool is thread safe  }
    Aborted_Video_Input: TAtomBool; {  Terminate simulation entry  }

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    {  Initialize ZDB2 data engine  }
    procedure Build_ZDB2_Video_DB();
    {  Capture and generate video fragment data for monitoring storage from a video file or URL using simulation  }
    procedure Build_Video_Input_Data(thSender: TCompute);
    {  Query Video  }
    procedure Query_Video(thSender: TCompute);
    {  Build_ Video_ Output is the physical level merging and clip processing of a single cut video source. The implementation method directly involves the use of hpc and hyper threading  }
    {  The output data will be h264 single stream data stored in memory, using TFFMPEG_ VideoStreamReader to play  }
    {  Because TFFMPEG_ VideoStreamReader uses a renderer to play the video, so there is no need to calculate the specific width and height of the video, just draw the video directly  }
    procedure Build_Video_Output(btime, etime: TDateTime; source: TZDB2_FFMPEG_Data_Query_Result; Bitrate: Int64; output: TMS64);
  end;

  {  After writing a process, the program can be very complex and difficult to read and modify  }
  {  TVideo_ Data_ Load_ And_ Decode_ Bridge is designed as a structure that reads a database and decodes it to simplify the video merge process  }
  TVideo_Data_Load_And_Decode_Bridge = class
  public
    source: TZDB2_FFMPEG_Data;
    OriData: TMS64;
    DecodeTool: TFFMPEG_VideoStreamReader;
    done: Boolean;
    constructor Create(source_: TZDB2_FFMPEG_Data);
    destructor Destroy; override;
    procedure DoResult(var Sender: TZDB2_Th_CMD_Stream_And_State);
    procedure DoDecodeTh(thSender: TCompute);
  end;

var
  zMonitor_3rd_Core_Demo_Form: TzMonitor_3rd_Core_Demo_Form;

implementation

{$R *.fmx}


uses StyleModuleUnit;

constructor TVideo_Data_Load_And_Decode_Bridge.Create(source_: TZDB2_FFMPEG_Data);
begin
  inherited Create;
  source := source_;
  OriData := TMS64.Create;
  DecodeTool := nil;
  done := False;
  {  Async_ Load_ Data is an asynchronous way for zdb2 to obtain data, which is only limited to the physical IO of the hard disk, usually Async_ Load_ The working efficiency of Data is between 20000 and 200000/s  }
  {  Usually Async_ Load_ Data can fill high-speed devices such as nvme/m2/ssd  }
  source.Async_Load_Data_M(OriData, DoResult); {  Zdb2 data engine command queue reading mechanism to obtain video clip data asynchronously  }
  DoStatus('Loading surveillance video fragments from the zdb2 data engine: %s', [source.Head.source.Text]);
end;

destructor TVideo_Data_Load_And_Decode_Bridge.Destroy;
begin
  DisposeObjectAndNil(OriData);
  DisposeObjectAndNil(DecodeTool);
  DisposeObject(OriData);
  inherited Destroy;
end;

procedure TVideo_Data_Load_And_Decode_Bridge.DoDecodeTh(thSender: TCompute);
var
  tmp: TMS64;
begin
  DoStatus('Start decoding: %s Start frame: %d End frame: %d Approximate length: %d seconds',
    [source.Head.source.Text, source.Head.begin_frame_id, source.Head.End_Frame_ID,
      round((source.Head.End_Frame_ID - source.Head.begin_frame_id) / source.Head.psf)]);
  {  Start decoding  }
  tmp := thSender.UserObject as TMS64;
  DecodeTool := TFFMPEG_VideoStreamReader.Create;
  try
    DecodeTool.OpenH264Decodec;
    DecodeTool.WriteBuffer(tmp); {  The monitoring fragment may be an ultra long single code stream, and a code stream may be>1000 frames. This step may consume computing resources, but it runs on threads, and external programs can be insensitive  }
    {  The projected data is useless. Kill them  }
    DisposeObject(tmp);
  except
  end;
  DoStatus('Decoding completed: %s', [source.Head.source.Text]);
  {  Update operation status  }
  done := True;
end;

procedure TVideo_Data_Load_And_Decode_Bridge.DoResult(var Sender: TZDB2_Th_CMD_Stream_And_State);
var
  tmp: TMS64;
begin
  if Sender.state = csDone then {  Zdb2 data engine reading completed  }
    begin
      DoStatus('Loading monitoring video fragments completed: %s', [source.Head.source.Text]);
      tmp := TMS64.Create;
      tmp.Mapping(OriData.PosAsPtr(source.DataPosition), OriData.Size - source.DataPosition); {  Using memory mapping technology to directly truncate and project data to tmp, no copy, high-speed mechanism  }
      {  Start decoding thread  }
      TCompute.RunM(nil, tmp, DoDecodeTh);
    end
  else
      done := True;
end;

procedure TzMonitor_3rd_Core_Demo_Form.fps_TimerTimer(Sender: TObject);
begin
  CheckThread;
  DrawPool.Progress;
  Video_DB.ZDB2_Eng.Progress;
end;

procedure TzMonitor_3rd_Core_Demo_Form.video_input_browseClick(Sender: TObject);
begin
  if not video_OpenDialog.Execute then
      exit;
  video_input_Edit.Text := video_OpenDialog.FileName;
end;

procedure TzMonitor_3rd_Core_Demo_Form.abort_video_input_ButtonClick(Sender: TObject);
begin
  Aborted_Video_Input.V := True;
end;

procedure TzMonitor_3rd_Core_Demo_Form.build_video_input_ButtonClick(Sender: TObject);
begin
  if not FFMPEGOK then
    begin
      TDialogService.MessageDialog('Ffmpeg not ready', TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
      exit;
    end;
  if video_input_Edit.Text = '' then
    begin
      TDialogService.MessageDialog('You must specify a video source', TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
      exit;
    end;
  TCompute.RunM(nil, nil, Build_Video_Input_Data, nil);
end;

procedure TzMonitor_3rd_Core_Demo_Form.replay_name_refresh_ButtonClick(Sender: TObject);
begin
  Video_DB.Source_Analysis.GetKeyList(replay_name_ComboEdit.Items);
end;

procedure TzMonitor_3rd_Core_Demo_Form.query_ButtonClick(Sender: TObject);
begin
  TCompute.RunM(nil, nil, Query_Video, nil);
end;

procedure TzMonitor_3rd_Core_Demo_Form.zdb2_bak_ButtonClick(Sender: TObject);
begin
  TCompute.RunP_NP(procedure
    begin
      {  Each time a backup is performed, a copy of the current data is made. Parameter 3 indicates that a maximum of 3 copies are allowed  }
      Video_DB.ZDB2_Eng.Backup(3);
    end);
end;

procedure TzMonitor_3rd_Core_Demo_Form.remove_first_frag_ButtonClick(Sender: TObject);
begin
  Video_DB.ZDB2_Eng.Data_Marshal.First^.Data.Remove(True);
end;

procedure TzMonitor_3rd_Core_Demo_Form.backcall_DoStatus(Text_: SystemString; const ID: Integer);
begin
  logMemo.Lines.Add(Text_);
  logMemo.GoToTextEnd;
end;

constructor TzMonitor_3rd_Core_Demo_Form.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AddDoStatusHook(self, backcall_DoStatus);
  Load_ffmpeg();
  if FFMPEGOK then
      DoStatus('load ffmpeg ok.')
  else
      DoStatus('load ffmpeg failed!');
  Wait_SystemFont_Init(); {  Preload built-in raster fonts. The default setting for built-in raster fonts is post loading, that is, loading on first use  }
  Build_ZDB2_Video_DB(); {  Initialize video recording database  }
  Aborted_Video_Input := TAtomBool.Create(False); {  Terminate simulation entry  }
end;

destructor TzMonitor_3rd_Core_Demo_Form.Destroy;
begin
  Video_DB.Flush;
  RemoveDoStatusHook(self);
  DisposeObject(Video_DB);
  DisposeObject(Aborted_Video_Input);
  inherited Destroy;
end;

procedure TzMonitor_3rd_Core_Demo_Form.Build_ZDB2_Video_DB;
begin
  Video_DB := TZDB2_FFMPEG_Data_Marshal.Create;
  {  Create two video data storage files  }
  {  When storing video, it will be staged, with segment 1 saved to db1 and segment 2 saved to db2  }
  {  The zdb2 engine can support multithreaded concurrent work, making it ideal for deploying storage services on demand  }
  {  Video storage databases can be placed on different hdd disk paths to improve IO throughput efficiency  }
  {  Prompt: If zdb2 initializes the database while working in debug mode, the parameters for initializing the database will be printed  }
  {  The development path of zdb2's data engine is free+open, with different application scenarios. The core idea is to write a specific zdb2 data engine for whatever it is used  }
  Video_DB.BuildOrOpen(TPath.GetLibraryPath + 'VideoDB1.OX', False, False);
  Video_DB.BuildOrOpen(TPath.GetLibraryPath + 'VideoDB2.OX', False, False);
  {  If zdb2 is in open mode and the database index is loaded, this step will have no effect if a new database is created  }
  {  Extract_ Video_ Data_ Pool operates in hpc mode, which can improve data loading efficiency by scheduling excessive CPU cores  }
  {  Extract_ Video_ Data_ In order to ensure the consistency of data entries, the Pool will perform a unified serialization arrangement after loading. Please follow for details  }
  Video_DB.Extract_Video_Data_Pool(M3C_Core.Get_Parallel_Granularity);
end;

procedure TzMonitor_3rd_Core_Demo_Form.Build_Video_Input_Data(thSender: TCompute);
var
  r: TFFMPEG_Reader;
  raster: TRaster;
  psf: Double;
  begin_Time: TDateTime;
  begin_frame_id: Int64;
  second_: Double;
  sim_time: TDateTime;
  w: TFFMPEG_Writer;
  frame_split: Integer;
  encoder_output: TMS64;
  frag_source, frag_clip: U_String;
begin
  {  The core idea of monitoring input is to use TFFMPEG_ Reader reads it, then processes the raster, adds watermark, and reduces the data size (the video source is 4k+60fps, and the reconstruction process can be made into 720+10fps to achieve the goal of saving space)  }
  {  Then use TFFMPEG_ Writer to encode and generate fragments, and finally submit them to the database  }
  {  At this point, the monitoring entry process is complete  }
  {  Theory: Monitoring input does not require frame copying, but rather recoding  }
  {  Recoding the monitoring source allows the database to obtain fully normalized frame data, and allows for autonomous programming of the process. In an HPC server, the threading model allows the server to carry hundreds or even thousands of real-time monitoring codes  }
  {  During the past 2006, if there were to be re coding here, multiple servers would be required for video processing. Today, a single HPC would do everything  }
  {  If you use recording and storage devices such as iot to store monitoring data, there is no need for re coding. Such devices cannot carry large-scale monitoring code streams and directly perform frame transfer, bypassing the raster decoding and encoding process  }
  try
      r := TFFMPEG_Reader.Create(video_input_Edit.Text, reader_use_gpu_CheckBox.IsChecked); {  Building a decoder from an address or file  }
  except
      exit;
  end;

  frag_source := video_input_Edit.Text; {  frag_ "In monitoring, source usually gives camera names, such as elevator entrances and workshop entrances on the second floor, to identify video clips."  }

  {  Convert a string to an integer using an expression engine  }
  {  The expression engine can convert integers to 1920 * 0.5, which is 480p after calculation  }
  {  Multi-purpose expression engine, which helps interface user interface, and expression engine functions are superior to strtoint  }
  r.ResetFit(EStrToInt(resize_width_Edit.Text), EStrToInt(resize_height_Edit.Text)); {  Here is the definition of the non aliasing scale after decoding  }
  frame_split := EStrToInt(split_frame_Edit.Text);

  psf := r.psf; {  The frame rate coefficient is copied here as a local variable to increase the speed  }
  begin_Time := Now(); {  Initialize startup time  }
  begin_frame_id := r.Current_Frame; {  Initialize frame id  }
  raster := NewRaster(); {  Initialize Raster  }
  {  frag_ Clip: Video clipping. This is a value in data design that indicates smoothness. For example, when the network is disconnected or the server is restarted_ Clips will change  }
  frag_clip := frag_source + '|' + DateTimeToStr(Now());

  w := nil; {  Reset the encoder instance. If it is not reset, the default value under debug will be nil, and the release will be a random address  }

  {  Reset Status Controller  }
  Aborted_Video_Input.V := False;

  while (not Aborted_Video_Input.V) and r.ReadFrame(raster, False) do {  This ReadFrame will directly map the content raster of ffmpeg to a TMemoryRaster raster, with no memory copy in the middle  }
    begin
      {  Here, it is necessary to calculate the simulated playback time of each frame after real-time decoding  }
      {  After obtaining this time, write a segment of watermark text into the raster for visual verification during playback  }
      {  Finally, store the raster into the fragment database, and when the fragment is full, continue to send it to zdb2  }
      {  At this point, the simulation of the input function is complete  }

      second_ := (r.Current_Frame - begin_frame_id) / psf; {  Current clip frame (r.Current_Frame - begin_frame_id)/frame rate per second=current playback time  }

      {  Current playback time_ Time=simulation acquisition time  }
      sim_time := IncMilliSecond(
      begin_Time,
        round(second_ * 1000) {  Convert the current playback time into milliseconds  }
        );

      {  DrawEngine provides better text and drawing support than raster's built-in text rendering and drawing support  }
      {  Raster and DrawEngine are two large modules. Raster is a raster, and drawengine is a renderer middleware. When specifying output, drawengine renders content that points to memory  }
      with raster.DrawEngine do {  Raster.DrawEngine builds a rendering engine instance based on a raster engine instance, which does not need to be released and initialized  }
        begin
          DrawOptions := []; {  Block all additional rendering content, such as fps information  }
          {  Start Watermarking  }
          {  Draw_ BK_ Text: Draw a watermark text with a background in the upper left corner  }
          Draw_BK_Text(PFormat('Current frame %d Simulation time %s', [r.Current_Frame, DateTimeToStr(sim_time)]), 32, ScreenRectV2, DEColor(1, 1, 1), DEColor(0.1, 0.1, 0.1, 0.5), False);
          Flush; {  The flush command embeds the drawing content into the raster  }
        end;

      if w = nil then {  Check the encoder instance, and if it is empty, build an encoder instance  }
        begin
          encoder_output := TMS64.CustomCreate(1024 * 1024); {  A larger customCreate parameter can effectively avoid the realloc frequency of MM units  }
          w := TFFMPEG_Writer.Create(encoder_output); {  Create an encoder instance  }
          w.OpenH264Codec(raster.Width, raster.Height, round(psf), 1024 * 1024); {  Specifies to use h264 for encoding, with a fixed bit rate of 1M, which makes it easier to see the watermark text clearly in the Demo  }
        end;
      w.EncodeRaster(raster); {  Encoded single frame raster  }

      if w.EncodeNum >= frame_split then {  Frame interval length reached  }
        begin
          {  Flush completion encoding  }
          w.Flush;
          DisposeObjectAndNil(w); {  Release and reset encoder  }
          {  Encoder will encode the completed data_ The output+parameter is submitted to the zdb2 database. At this point, the monitoring of the single fragment simulation warehousing is complete  }
          Video_DB.Add_Video_Data(frag_source, frag_clip, psf, begin_frame_id, r.Current_Frame, begin_Time, sim_time, encoder_output, True);
          DoStatus('"The encoding fragment has been completed and stored, %s frames: %d simulation time: %s.. %" s',
            [frag_source.Text, r.Current_Frame - begin_frame_id, DateTimeToStr(begin_Time), DateTimeToStr(sim_time)]);
          begin_Time := sim_time;
          begin_frame_id := r.Current_Frame;
        end;
    end;

  {  When the network is disconnected or all video files have been decoded  }
  if w <> nil then
    begin
      {  Flush completion encoding  }
      w.Flush;
      DisposeObjectAndNil(w); {  Release and reset encoder  }
      {  Check if there are any remaining frames, and if so, perform end processing  }
      if r.Current_Frame - begin_frame_id > 1 then
        begin
          {  Encoder will encode the completed data_ The output+parameter is submitted to the zdb2 database. At this point, the monitoring of the single fragment simulation warehousing is complete  }
          Video_DB.Add_Video_Data(frag_source, frag_clip, psf, begin_frame_id, r.Current_Frame, begin_Time, sim_time, encoder_output, True);
          DoStatus('"The encoding fragment has been completed and stored, %s frames: %d simulation time: %s.. %" s',
            [frag_source.Text, r.Current_Frame - begin_frame_id, DateTimeToStr(begin_Time), DateTimeToStr(sim_time)]);
        end
      else
          DisposeObject(encoder_output);
      begin_Time := sim_time;
      begin_frame_id := r.Current_Frame;
    end;

  DoStatus('" %s" has been disconnected or the video file has been completely decoded "', [r.VideoSource.Text]);
  DisposeObject(r);
end;

procedure TzMonitor_3rd_Core_Demo_Form.Query_Video(thSender: TCompute);
var
  {  Clip_ Tool is a cutting algorithm for monitored video fragment data, which serializes and archives different monitoring sources and different continuous fragments, serving as a data preprocessing step  }
  {  Clip_ The tool does not do physical level video merging and cutting, but rather provides a logical basis for physical video merging and cutting  }
  Clip_Tool: TZDB2_FFMPEG_Data_Query_Result_Clip_Tool;
  query_btime, query_etime: TDateTime;
  qresult: TZDB2_FFMPEG_Data_Query_Result;
  activted_video_output_th: TAtomInt;
  output_video_buff: array of TMS64;
  i: Integer;
begin
  Clip_Tool := TZDB2_FFMPEG_Data_Query_Result_Clip_Tool.Create;

  {  A combo with a date and time only adds up to a datetime  }
  query_btime := begin_date_Edit.Date + begin_time_Edit.Time;
  query_etime := end_date_Edit.Date + end_time_Edit.Time;

  {  All big data engines built on the basis of zdb2 are parallelized when querying, and support starting the query system in sub threads  }
  {  Query the internal data condition matching of the system, and you need to program yourself to solve it. The specific methods can be followed and read by yourself: They are all data structures, and you cannot follow the direction of SQL. You need to be familiar with programming  }
  qresult := Video_DB.Query_Video_Data(
  True, 4, {  Parallelism and threading, the amount of data monitored is very small, and hardly consumes CPU computing resources, which can be ignored here  }
  True, {  The protection query returns an instance. Before the qresult is released, it indicates that data is being processed. The zdb2 data engine will protect the instance and data and will not actually delete them  }
  replay_name_ComboEdit.Text, replay_clip_Edit.Text, query_btime, query_etime);

  {  The data queried by the video storage engine will be returned in a sorted structure  }
  {  These structures are all eligible video clips. Here, many secondary processes such as merging, cropping, filtering, and so on need to be performed on the clips  }
  {  Merge: Its function is to reconstruct multiple fragments and package them into a single fragment for direct playback and viewing by users  }
  {  Cropping: Cropping and extracting a portion from a video clip, then merging and packaging it to facilitate direct playback and viewing by users  }
  {  Filtering: Because the query results include video tasks, the video task data indicates changes in the monitored video after it is paused or disconnected. The filtering conditions require independent video processing based on different video tasks  }
  {  Independent video processing: If there are two video recording and storage tasks in a single path, then after querying, it is necessary to generate two independent clips based on the results. These generation procedures include video processing methods such as merging, cropping, and so on  }
  DoStatus('Found %d clips containing %d video sources and %d playback clips', [qresult.Num, qresult.Source_Analysis.Num, qresult.clip_Analysis.Num]);

  {  Using tools to classify all query results into fragment sequences: This step is to simplify the merge process, classify all independent fragment data that needs to be processed, prepare a state machine for cutting and merging, and output it in a structured manner  }
  {  Clip_ Tool is a cutting algorithm for monitored video fragment data, which serializes and archives different monitoring sources and different continuous fragments, serving as a data preprocessing step  }
  {  Clip_ The tool does not do physical level video merging and cutting, but rather provides a logical basis for physical video merging and cutting  }
  {  Clip_ Tool.Extract_ Clip is a high-speed algorithm that can instantly complete query results even if there are millions of them. However, if there are millions of them, the CPU power required for video merging at the physical level will be very abnormal  }
  Clip_Tool.Extract_clip(qresult);

  {  Next, in the classification structure, use ffmpeg directly for merging  }
  activted_video_output_th := TAtomInt.Create(0); {  Initialize the active thread counter, state machine programming paradigm, used to detect whether all threads have ended  }
  if Clip_Tool.Num > 0 then
    begin
      SetLength(output_video_buff, Clip_Tool.Num); {  Initialize the H264 data output pool for video reconstruction  }
      with Clip_Tool.Repeat_ do
        repeat
          activted_video_output_th.UnLock(activted_video_output_th.Lock + 1); {  Using atomic operations to add 1 to the thread counter  }
          {  Build a TMS64 instance in the h264 data output pool, that is, a TMemoryStream64 instance. TMemoryStream64 is superior to TMemoryStream  }
          output_video_buff[I__] := TMS64.CustomCreate(1024 * 1024);

          if used_query_th_CheckBox.IsChecked then {  Whether to use multithreading to build video clip data output  }
            begin
              {  Start Thread  }
              TCompute.RunP( {  The TComputer.Run thread can only pass 1 pointer+1 object at a time. If you want to pass more, you need to create a record or class to pass it inside  }
              Queue, {  The queue passed to the thread corresponds to thSender.UserData  }
              output_video_buff[I__], {  The object instance passed to the thread corresponds to thSender.UserObject  }
                procedure(thSender: TCompute)
                begin
                  {  Create a new thread for video output reconstruction  }
                  Build_Video_Output(query_btime, query_etime,
                    TZDB2_FFMPEG_Data_Query_Result_Clip_Tool.PQueueStruct(thSender.UserData)^.Data, // queue
                    1024 * 1024, {  Video reconstruction code rate  }
                    thSender.UserObject as TMS64 {  Object Instance  }
                    );
                  activted_video_output_th.UnLock(activted_video_output_th.Lock - 1); {  Using atomic operations for the thread counter - 1  }
                end);
            end
          else
            begin
              {  Non-threaded video output reconstruction  }
              Build_Video_Output(query_btime, query_etime, Queue^.Data, 1024 * 1024, output_video_buff[I__]);
              activted_video_output_th.UnLock(activted_video_output_th.Lock - 1); {  Using atomic operations for the thread counter - 1  }
            end;
        until not Next;
    end;

  {  Wait for the hpc thread to finish processing  }
  while activted_video_output_th.V > 0 do
      TCompute.Sleep(10);
  DisposeObject(activted_video_output_th);

  {  Release Cut Calculation Tool  }
  DisposeObject(Clip_Tool);
  {  Release Query Results  }
  DisposeObject(qresult);

  {  After the completion of all video clip reconstruction threads, all H264 reconstruction data results are placed in the data pool: output_ video_ buff  }
  for i := 0 to length(output_video_buff) - 1 do
      DisposeObjectAndNil(output_video_buff[i]);
  SetLength(output_video_buff, 0);
end;

procedure TzMonitor_3rd_Core_Demo_Form.Build_Video_Output(btime, etime: TDateTime; source: TZDB2_FFMPEG_Data_Query_Result; Bitrate: Int64; output: TMS64);
var
  w: TFFMPEG_Writer;
  data_arry: array of TVideo_Data_Load_And_Decode_Bridge;
  L: TMemoryRasterList;
  i, updated: Integer;
begin
  {  Build_ Video_ Output is used to implement video cutting and merging  }
  {  For example, if the clip in the source is 00:00:15 to 00:00:60, and the cutting time is from 00:00:30 to 00:00:50, then the video fragment will be cut, intercepted from the middle, and generated into h264, which will be saved to Output  }
  {  For example, if there are 1000 fragments in the source, the program will reconstruct these 1000 fragments and merge them in the H264 format, and finally save them to output  }
  {  This function is not a playback function, but rather uses cutting-edge hardware acceleration technology in the background to reconstruct the video and generate a single stream of query results  }
  {  Explain why we need to reconstruct the entire clip: The query results will be accurate to milliseconds, as well as the frame position corresponding to milliseconds. At this time, accurate data positioning can allow us to do many data matching on the video  }
  {  Example 1: Using n cameras to monitor a scene at the same time, you can mark the video in an accurate time series, perform some corresponding procedural processing, and then output the generated results  }
  {  Example 2: In the AI vision application system, video recognition data always needs to match accurate video frames, so that various wireframes and text content can be drawn on the video output content, and then the generated results can be output  }

  {  realization  }
  SetLength(data_arry, source.Num);
  w := nil;
  if source.Num > 0 then
    with source.Repeat_ do {  Circular Normal Form of Generic Templates  }
      repeat
        if data_arry[I__] = nil then
            data_arry[I__] := TVideo_Data_Load_And_Decode_Bridge.Create(Queue^.Data);
        while not data_arry[I__].done do
            TCompute.Sleep(1);

        {  Predownload and decode the next monitoring data fragment in the background thread  }
        if (I__ + 1 < source.Num) and (data_arry[I__ + 1] = nil) then
            data_arry[I__ + 1] := TVideo_Data_Load_And_Decode_Bridge.Create(Queue^.Next^.Data);

        if data_arry[I__].DecodeTool <> nil then {  If the decoding error or database error occurs, this will be nil  }
          begin
            L := data_arry[I__].DecodeTool.LockVideoPool; {  Removing the raster pool from the decoder  }
            for i := 0 to L.Count - 1 do
              {  Calculate the input time corresponding to the frame, and then judge the cutting time  }
              if DateTimeInRange(data_arry[I__].source.Head.Frame_ID_As_Time(i + data_arry[I__].source.Head.begin_frame_id), btime, etime) then
                begin
                  if w = nil then
                    begin
                      w := TFFMPEG_Writer.Create(output);
                      {  If cuda is supported, use gpu encoding  }
                      DoStatus('Building hardware encoder');
                      if not w.OpenH264Codec('nvenc_h264', L[i].Width, L[i].Height, round(data_arry[I__].source.Head.psf), Bitrate) then
                          w.OpenH264Codec(L[i].Width, L[i].Height, round(data_arry[I__].source.Head.psf), Bitrate); {  Use CPU encoding  }
                    end;
                  {  If you want to program the raster, the code here is  }
                  {  Note: The input amount of gpu coding is very large. If a calculation delay occurs here, it will greatly reduce coding efficiency  }
                  {  L[i].DrawText('display', 0, 100, 30, RColorF (1, 1, 1));  }

                  w.EncodeRaster(L[i], updated); {  The ffmpeg encoder will automatically open up multiple threads or enable gpu encoding internally  }
                end;
            data_arry[I__].DecodeTool.UnLockVideoPool(True);
            DisposeObjectAndNil(data_arry[I__]);
          end;
      until not Next; {  Circular Normal Form of Generic Templates  }

  for i := 0 to length(data_arry) - 1 do
      DisposeObjectAndNil(data_arry[i]);
  SetLength(data_arry, 0);

  if w <> nil then
    begin
      w.Flush;
      {  Commissioning  }
      // output.SaveToFile('c:\temp\test.h264');
      DisposeObjectAndNil(w);
      DoStatus('Complete %s', [source.First^.Data.Head.source.Text]);
    end;
end;

end.
