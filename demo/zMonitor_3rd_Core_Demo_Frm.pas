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

  // 基础库
  M3C_Core, M3C_PascalStrings, M3C_UPascalStrings,
  // 在基础库基础上衍生的功能型支持库
  M3C_HashList.Templet, M3C_ListEngine, M3C_UnicodeMixedLib, M3C_MemoryStream, M3C_DFE, M3C_Status, M3C_Geometry2D, M3C_Cipher,
  M3C_Expression, M3C_OpCode, // 表达式引擎，在本demo中主要用来转换字符串成浮点，整数之类
  M3C_MemoryRaster, M3C_DrawEngine, // 光栅和渲染引擎支持库
  M3C_DrawEngine.SlowFMX, // 图形输出库，该库提供了FMX框架在hpc平台快速调试支持，该库的早期版本不提供hpc快速调试支持
  M3C_FFMPEG, // ffmpeg api支持库
  M3C_FFMPEG.Reader, // ffmpeg视频解码支持库，该库支持gpu加速
  M3C_FFMPEG.Writer, // ffmpeg光栅编码支持库
  M3C_FFMPEG.ExtractTool, // ffmpeg的跨平台解码支持库,多码流支持性比Reader更优,缺点是该库不支持gpu
  M3C_ZDB2, M3C_ZDB2.Thread.Queue, M3C_ZDB2.Thread, // zdb2数据库支持体系
  M3C_FFMPEG.DataMarshal; // 使用zdb2技术体系的ffmpeg数据仓库支持库

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
    // TZDB2_FFMPEG_Data_Marshal是在ZDB2引擎的基础上,针对性设计的视频数据引擎
    // zdb2的使用方法都是针对目标场景,目标需求,量身定做设计它的数据引擎
    // zdb2的数据引擎可以支持全并行化数据访问,增删查改都可以并行化工作,适合部署于hpc服务器或高配工作站
    // zdb2数据引擎多用于解决数据分类,数据过滤,数据统计,结构化支持体系非常易于应用三方统计学,例如ZAI和zAnalysis这类项目
    // 大数据类处理流程框架,zdb2是整个pas圈最优化的技术体系,并被众多大项目使用
    // 大家平时看到mysql,sqlserver这类数据库是侧重于数据管理的,zdb2侧重于数据引擎设计,尤其解决复杂数据问题,包括,存储设计,数据结构设计,算法设计
    Video_DB: TZDB2_FFMPEG_Data_Marshal;

    // TAtomBool这种状态控制器是线程安全的
    Aborted_Video_Input: TAtomBool; // 终止仿真录入

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // 初始化ZDB2数据引擎
    procedure Build_ZDB2_Video_DB();
    // 用仿真方式从一个视频文件或则url捕获并生成监控存储用的视频碎片数据
    procedure Build_Video_Input_Data(thSender: TCompute);
    // 查询视频
    procedure Query_Video(thSender: TCompute);
    // Build_Video_Output是将单个剪切的视频源做物理层面的合并和clip处理,实现方法直接涉及到hpc和超线程运用
    // 输出数据将会是存放于内存中的h264单码流数据,使用TFFMPEG_VideoStreamReader来播放
    // 因为TFFMPEG_VideoStreamReader播放采用渲染器来干,所以不需要做视频的等比宽高计算,直接把视频画出来即可
    procedure Build_Video_Output(btime, etime: TDateTime; source: TZDB2_FFMPEG_Data_Query_Result; Bitrate: Int64; output: TMS64);
  end;

  // 写成一个流程以后,程序会非常复杂,且难以阅读和修改
  // TVideo_Data_Load_And_Decode_Bridge被设计成个读取数据库并且解码的结构,以此来简化视频合并流程
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
  // Async_Load_Data是zdb2的异步方式获取数据,它只受限于硬盘的物理io,通常Async_Load_Data的工作效率在2万-20万/s间
  // 通常Async_Load_Data可以把nvme/m2/ssd这类高速设备跑满
  source.Async_Load_Data_M(OriData, DoResult); // zdb2数据引擎命令队列读取机制,用异步方式获取视频片段数据
  DoStatus('正在从zdb2数据引擎载入监控视频碎片:%s', [source.Head.source.Text]);
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
  DoStatus('开始解码:%s 起始帧:%d 结束帧:%d 大约时长:%d秒',
    [source.Head.source.Text, source.Head.begin_frame_id, source.Head.End_Frame_ID,
      round((source.Head.End_Frame_ID - source.Head.begin_frame_id) / source.Head.psf)]);
  // 开始解码
  tmp := thSender.UserObject as TMS64;
  DecodeTool := TFFMPEG_VideoStreamReader.Create;
  try
    DecodeTool.OpenH264Decodec;
    DecodeTool.WriteBuffer(tmp); // 监控片段也许是个超长单码流,一个码流也许>1000帧,这一步会比较消耗计算资源,但是它运行于线程,外部程序可以无感
    // 投影过来的数据已经无用,干掉它们
    DisposeObject(tmp);
  except
  end;
  DoStatus('完成解码:%s', [source.Head.source.Text]);
  // 更新运行状态
  done := True;
end;

procedure TVideo_Data_Load_And_Decode_Bridge.DoResult(var Sender: TZDB2_Th_CMD_Stream_And_State);
var
  tmp: TMS64;
begin
  if Sender.state = csDone then // zdb2数据引擎读取完成
    begin
      DoStatus('载入监控视频碎片完成:%s', [source.Head.source.Text]);
      tmp := TMS64.Create;
      tmp.Mapping(OriData.PosAsPtr(source.DataPosition), OriData.Size - source.DataPosition); // 用内存映射技术直接把数据截断投影到tmp,无copy,高速机制
      // 启动解码线程
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
      TDialogService.MessageDialog('ffmpeg未准备就绪', TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
      exit;
    end;
  if video_input_Edit.Text = '' then
    begin
      TDialogService.MessageDialog('必须指定视频源', TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
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
      // 每执行一次备份,会对当前数据做一次副本copy,参数3表示最多允许3个副本
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
  Wait_SystemFont_Init(); // 预加载内置光栅字体，内置光栅字体默认为后置式加载，既，首次使用时加载
  Build_ZDB2_Video_DB(); // 初始化视频记录数据库
  Aborted_Video_Input := TAtomBool.Create(False); // 终止仿真录入
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
  // 创建两个视频数据存储文件
  // 存储视频时会轮番存,片段1存到db1,片段2存到db2
  // zdb2引擎可支持多线程并发工作,非常适合在服务求部署存储服务
  // 可以将视频存储数据库放置于不同hdd磁盘路径来提高IO吞吐效率
  // 提示:zdb2初始化数据库如果工作于调试模式,会打印初始化数据库的参数
  // zdb2的数据引擎发展路线是自由+开放,适用场景也各不相同,核心思路是,用什么,就写一个针对的zdb2数据引擎
  Video_DB.BuildOrOpen(TPath.GetLibraryPath + 'VideoDB1.OX', False, False);
  Video_DB.BuildOrOpen(TPath.GetLibraryPath + 'VideoDB2.OX', False, False);
  // 如果zdb2为打开模式,载入数据库索引,如果是创建的新数据库,该步骤会无效
  // Extract_Video_Data_Pool为hpc工作模式,可以通过调度超多的cpu内核来提升数据载入效率
  // Extract_Video_Data_Pool为保证数据条目一致性会在载入完成后,统一做一次序列化排列,具体细节可跟进去看
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
  // 监控的录入的核心思路就是用TFFMPEG_Reader来读,然后,对光栅做处理,加水印,减少数据规模(视频源是4k+60fps,重构过程可以做成720+10fps,以此来达到节省空间的目的)
  // 然后再用TFFMPEG_Writer来编码生成片段,最后提交到数据库去
  // 这时候,监控的录入流程就完成了
  // 理论:监控录入不用帧拷贝,而是重编码
  // 对监控源重编码,可以让数据库得到全规范化的帧数据,并且可以对过程自主编程,在hpc服务器中,线程模型可以让服务器承载几百甚至上千路的实时监控编码
  // 在过去2006年期间,这里如果要做重编码,需要多台服务器进行视频处理,放到今天是单台hpc干完一切
  // 如果使用iot这类录存设备来存监控数据,重编码就不需要了,那种设备带不动大规模监控码流,直接做帧转存,绕过光栅解码编码环节
  try
      r := TFFMPEG_Reader.Create(video_input_Edit.Text, reader_use_gpu_CheckBox.IsChecked); // 从地址或文件构建解码器
  except
      exit;
  end;

  frag_source := video_input_Edit.Text; // frag_source在监控中,一般给摄像头名称,例如a2楼电梯口,车间门口,用于辨识视频的片段标记

  // 用表达式引擎把字符串换算成整数
  // 表达式引擎对于整数换算可以是1920*0.5，这种写法，计算下来以后就是480p
  // 多用表达式引擎，有助于接口用户界面，表达式引擎函数优于strtoint
  r.ResetFit(EStrToInt(resize_width_Edit.Text), EStrToInt(resize_height_Edit.Text)); // 这里是定义解码后的无走样尺度
  frame_split := EStrToInt(split_frame_Edit.Text);

  psf := r.psf; // 帧率系数，这里复制成本地变量用与提速
  begin_Time := Now(); // 初始化启动时间搓
  begin_frame_id := r.Current_Frame; // 初始化帧id
  raster := NewRaster(); // 初始化光栅
  // frag_clip:视频剪切,这个是数据设计中的一个值,表示流畅性,例如,网络断线,服务器重启,这时候,frag_clip都会出现变化
  frag_clip := frag_source + '|' + DateTimeToStr(Now());

  w := nil; // 复位编码器实例，如果不复位，debug下会默认是nil，release会是随机地址

  // 复位状态控制器
  Aborted_Video_Input.V := False;

  while (not Aborted_Video_Input.V) and r.ReadFrame(raster, False) do // 该条ReadFrame会直接把ffmpeg的内容光栅映射成TMemoryRaster光栅，中间没有内存copy
    begin
      // 这里需要计算实时解码后每一帧仿真播放时间
      // 得到该时间后，再写一段水印文本到光栅中作为回放时的视觉验证
      // 最后,再把光栅存入片段数据库,待片段满,仍给zdb2
      // 至此，仿真输入函数的工作就完成了

      second_ := (r.Current_Frame - begin_frame_id) / psf; // 当前片段帧(r.Current_Frame - begin_frame_id)/每秒帧率=当前播放的时间搓

      // 当前播放的时间搓+begin_time=仿真采集时间搓
      sim_time := IncMilliSecond(
      begin_Time,
        round(second_ * 1000) // 把当前播放时间搓换算成毫秒单位
        );

      // drawEngine对于文字和绘图支持,会优于raster内置的文字渲染和绘图支持
      // raster和DrawEngine是两个大模块,raster是光栅,drawengine是个渲染器中间件,在指定输出时,drawengine渲染内容会指向内存
      with raster.DrawEngine do // raster.DrawEngine是在光栅引擎实例基础上,构建一个渲染引擎实例,该实例无需释放和初始化
        begin
          DrawOptions := []; // 屏蔽所有的附加渲染内容，比如fps信息
          // 开始画水印
          // Draw_BK_Text: 画一条带有背景的水印文字，位置处于左上角
          Draw_BK_Text(PFormat('当前帧 %d 仿真时间 %s', [r.Current_Frame, DateTimeToStr(sim_time)]), 32, ScreenRectV2, DEColor(1, 1, 1), DEColor(0.1, 0.1, 0.1, 0.5), False);
          Flush; // flush命令会把绘图内容嵌入到光栅
        end;

      if w = nil then // 检查编码器实例,如果为空,构建一个编码器实例
        begin
          encoder_output := TMS64.CustomCreate(1024 * 1024); // customCreate参数给大一点可以有效避免MM单元的realloc频率
          w := TFFMPEG_Writer.Create(encoder_output); // 创建编码器实例
          w.OpenH264Codec(raster.Width, raster.Height, round(psf), 1024 * 1024); // 指定使用h264进行编码,码率固定为1M,这样可以便于在Demo中看清楚水印文字
        end;
      w.EncodeRaster(raster); // 编码单帧光栅

      if w.EncodeNum >= frame_split then // 达到帧间隔长度
        begin
          // flush完结编码
          w.Flush;
          DisposeObjectAndNil(w); // 释放并重置编码器
          // 将编码完成的数据,encoder_output+参数,提交至zdb2数据库,至此,对于监控的单片段仿真入库的就完成了
          Video_DB.Add_Video_Data(frag_source, frag_clip, psf, begin_frame_id, r.Current_Frame, begin_Time, sim_time, encoder_output, True);
          DoStatus('已经完成编码片段并存储,%s 帧数:%d 仿真时间:%s .. %s',
            [frag_source.Text, r.Current_Frame - begin_frame_id, DateTimeToStr(begin_Time), DateTimeToStr(sim_time)]);
          begin_Time := sim_time;
          begin_frame_id := r.Current_Frame;
        end;
    end;

  // 当网络断线或视频文件已经全部解码完成
  if w <> nil then
    begin
      // flush完结编码
      w.Flush;
      DisposeObjectAndNil(w); // 释放并重置编码器
      // 检查是不是有剩余帧,如果有,做结尾处理
      if r.Current_Frame - begin_frame_id > 1 then
        begin
          // 将编码完成的数据,encoder_output+参数,提交至zdb2数据库,至此,对于监控的单片段仿真入库的就完成了
          Video_DB.Add_Video_Data(frag_source, frag_clip, psf, begin_frame_id, r.Current_Frame, begin_Time, sim_time, encoder_output, True);
          DoStatus('已经完成编码片段并存储,%s 帧数:%d 仿真时间:%s .. %s',
            [frag_source.Text, r.Current_Frame - begin_frame_id, DateTimeToStr(begin_Time), DateTimeToStr(sim_time)]);
        end
      else
          DisposeObject(encoder_output);
      begin_Time := sim_time;
      begin_frame_id := r.Current_Frame;
    end;

  DoStatus('"%s" 已断线或则视频文件已完全解码', [r.VideoSource.Text]);
  DisposeObject(r);
end;

procedure TzMonitor_3rd_Core_Demo_Form.Query_Video(thSender: TCompute);
var
  // Clip_Tool是监控的视频碎片数据的剪切算法,它会将不同的监控源和不同的连续碎片做序列化归档处理,作用于数据预处理步骤
  // Clip_Tool并不会做物理层面的视频合并剪切,而是给物理视频合并剪切提供逻辑运行依据
  Clip_Tool: TZDB2_FFMPEG_Data_Query_Result_Clip_Tool;
  query_btime, query_etime: TDateTime;
  qresult: TZDB2_FFMPEG_Data_Query_Result;
  activted_video_output_th: TAtomInt;
  output_video_buff: array of TMS64;
  i: Integer;
begin
  Clip_Tool := TZDB2_FFMPEG_Data_Query_Result_Clip_Tool.Create;

  // 带有日期和时间的combo只相加就是datetime
  query_btime := begin_date_Edit.Date + begin_time_Edit.Time;
  query_etime := end_date_Edit.Date + end_time_Edit.Time;

  // 凡是在zdb2基础构建的大数据引擎在查询时都是并行化的,并且支持在子线程中启动查询系统
  // 查询系统内部的数据条件匹配需要自己编程来解决,具体做法可以跟进去自己阅读: 都是数据结构,不可走sql方向简单暴力,需要熟悉一下编程
  qresult := Video_DB.Query_Video_Data(
  True, 4, // 并行化和线程,监控的数据量非常小,几乎不占用cpu计算资源,这里可以无视
  True, // 保护查询返回实例,qresult未释放前,表示正在处理数据,zdb2数据引擎会保护实例和数据,并不会真正删除
  replay_name_ComboEdit.Text, replay_clip_Edit.Text, query_btime, query_etime);

  // 视频存储引擎查询出的数据会是以排序后的结构返回
  // 这些结构都是符合条件的视频片段,这里,需要对片段做出许多合并,裁剪,过滤等等二次处理
  // 合并:它的功能就是把对多个片段进行重构,打包成单个片段,便于用户直接回放观看
  // 裁剪:从视频片段中裁剪提取一部分,然后合并,打包,便于用户直接回放观看
  // 过滤:由于查询结果包含了视频任务,视频任务数据表示监控视频在暂停,断线后的变化,过滤条件需要根据不同的视频任务做独立化视频处理
  // 独立化视频处理:假如单路有2个视频录存任务,那么查询后,需要根据结果生成两个独立片段,这些生成程序包含了合并,裁剪等等视频处理方式
  DoStatus('查询到%d个片段,其中包含%d个视频源,和%d个播放剪切', [qresult.Num, qresult.Source_Analysis.Num, qresult.clip_Analysis.Num]);

  // 使用工具把查询结果全部分类成片段序列: 这一步工作是简化合并流程, 把需要处理的独立片段数据全部归类,做好剪切合并的状态机,以结构方式输出
  // Clip_Tool是监控的视频碎片数据的剪切算法,它会将不同的监控源和不同的连续碎片做序列化归档处理,作用于数据预处理步骤
  // Clip_Tool并不会做物理层面的视频合并剪切,而是给物理视频合并剪切提供逻辑运行依据
  // Clip_Tool.Extract_clip是高速算法,查询结果即使数以百万也会它瞬间完成,但是,如果真有数以百万,那么物理层面的视频合并所需要的cpu算力将会很变态
  Clip_Tool.Extract_clip(qresult);

  // 下一步,在归类结构上,直接使用ffmpeg做合并
  activted_video_output_th := TAtomInt.Create(0); // 初始化活动线程计数器,状态机编程范式,用于检测所有线程是否结束
  if Clip_Tool.Num > 0 then
    begin
      SetLength(output_video_buff, Clip_Tool.Num); // 初始化视频重构的h264数据输出池
      with Clip_Tool.Repeat_ do
        repeat
          activted_video_output_th.UnLock(activted_video_output_th.Lock + 1); // 用原子操作给线程计数器+1
          // 构建h264数据输出池中的TMS64实例,既,TMemoryStream64实例, TMemoryStream64优于TMemoryStream
          output_video_buff[I__] := TMS64.CustomCreate(1024 * 1024);

          if used_query_th_CheckBox.IsChecked then // 是否使用多线程构建视频片段数据输出
            begin
              // 启动线程
              TCompute.RunP( // TCompute.Run线程一次只能传1个指针+1个对象,如果要传递更多,需要自己建record or class往里面传
              Queue, // 传递给线程的queue,对应到thSender.UserData
              output_video_buff[I__], // 传递给线程的对象实例,对应到thSender.UserObject
                procedure(thSender: TCompute)
                begin
                  // 新开一个线程做视频输出重构
                  Build_Video_Output(query_btime, query_etime,
                    TZDB2_FFMPEG_Data_Query_Result_Clip_Tool.PQueueStruct(thSender.UserData)^.Data, // queue
                    1024 * 1024, // 视频重构码率
                    thSender.UserObject as TMS64 // 对象实例
                    );
                  activted_video_output_th.UnLock(activted_video_output_th.Lock - 1); // 用原子操作给线程计数器-1
                end);
            end
          else
            begin
              // 非线程方式做视频输出重构
              Build_Video_Output(query_btime, query_etime, Queue^.Data, 1024 * 1024, output_video_buff[I__]);
              activted_video_output_th.UnLock(activted_video_output_th.Lock - 1); // 用原子操作给线程计数器-1
            end;
        until not Next;
    end;

  // 等待hpc线程处理结束
  while activted_video_output_th.V > 0 do
      TCompute.Sleep(10);
  DisposeObject(activted_video_output_th);

  // 释放剪切计算工具
  DisposeObject(Clip_Tool);
  // 释放查询结果
  DisposeObject(qresult);

  // 当所有视频片段重构线程结束后, 所有的h264重构数据结果都放在数据池: output_video_buff
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
  // Build_Video_Output是实现视频的剪切与合并
  // 例如source中片段是00:00:15到00:00:60, 剪切时间是从00:00:30到00:00:50, 那么将会对视频碎片开刀, 从中间截取并生成h264, 保存到Output
  // 例如source中片段有1000个, 那么程序会重构这1000个片段并且以h264格式合并,最后保存到output
  // 该函数并不是播放功能,而是在后台用前沿的硬件加速技术,重构视频,并且生成一套单码流的查询结果
  // 解释一下为什么要重构整个剪切片段: 查询结果会精确到毫秒, 也会精确到毫秒所对应的帧位置, 这时候, 精确数据定位可以让我们对视频做许多数据匹配
  // 例1: 利用n个摄像头监控同一时间的场景, 这时候可以精确的时间序列中, 给视频打上记号, 做出一些对应程序化处理,然后,再输出生成结果
  // 例2: 在AI视觉应用体系中, 视频识别的数据总是需要和精确的视频帧相匹配, 这样才能在视频输出内容上画上各种线框和文字内容,然后,再输出生成结果

  // 实现
  SetLength(data_arry, source.Num);
  w := nil;
  if source.Num > 0 then
    with source.Repeat_ do // 泛型模板的循环范式
      repeat
        if data_arry[I__] = nil then
            data_arry[I__] := TVideo_Data_Load_And_Decode_Bridge.Create(Queue^.Data);
        while not data_arry[I__].done do
            TCompute.Sleep(1);

        // 在后台线程预下载并解码下一个监控数据片段
        if (I__ + 1 < source.Num) and (data_arry[I__ + 1] = nil) then
            data_arry[I__ + 1] := TVideo_Data_Load_And_Decode_Bridge.Create(Queue^.Next^.Data);

        if data_arry[I__].DecodeTool <> nil then // 如果解码错,或则数据库出搓,这里会是nil
          begin
            L := data_arry[I__].DecodeTool.LockVideoPool; // 从解码器取出光栅池
            for i := 0 to L.Count - 1 do
              // 计算出该帧对应的录入时间,然后判断剪切时间
              if DateTimeInRange(data_arry[I__].source.Head.Frame_ID_As_Time(i + data_arry[I__].source.Head.begin_frame_id), btime, etime) then
                begin
                  if w = nil then
                    begin
                      w := TFFMPEG_Writer.Create(output);
                      // 如果支持cuda使用gpu编码
                      DoStatus('正在构建硬件编码器');
                      if not w.OpenH264Codec('nvenc_h264', L[i].Width, L[i].Height, round(data_arry[I__].source.Head.psf), Bitrate) then
                          w.OpenH264Codec(L[i].Width, L[i].Height, round(data_arry[I__].source.Head.psf), Bitrate); // 使用cpu编码
                    end;
                  // 如果要对光栅做程序处理,代码在这里给
                  // 提示:gpu编码输入量非常大,这里如果发生了计算延迟,会大幅降低编码效率
                  // L[i].DrawText('演示', 0, 100, 30, RColorF(1, 1, 1));

                  w.EncodeRaster(L[i], updated); // ffmpeg编码器会在内部自动化开辟多线程或则启用gpu进行编码
                end;
            data_arry[I__].DecodeTool.UnLockVideoPool(True);
            DisposeObjectAndNil(data_arry[I__]);
          end;
      until not Next; // 泛型模板的循环范式

  for i := 0 to length(data_arry) - 1 do
      DisposeObjectAndNil(data_arry[i]);
  SetLength(data_arry, 0);

  if w <> nil then
    begin
      w.Flush;
      // 调试用
      // output.SaveToFile('c:\temp\test.h264');
      DisposeObjectAndNil(w);
      DoStatus('完成 %s', [source.First^.Data.Head.source.Text]);
    end;
end;

end.
