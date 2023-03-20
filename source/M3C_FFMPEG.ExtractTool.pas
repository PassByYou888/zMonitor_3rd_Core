{ ****************************************************************************** }
{ * FFMPEG Extract tool V2.0                                                   * }
{ ****************************************************************************** }
unit M3C_FFMPEG.ExtractTool;

{$I M3C_Define.inc}

interface

uses Math,
{$IFDEF FPC}
  M3C_FPC.GenericList,
{$ENDIF FPC}
  M3C_Core, M3C_PascalStrings, M3C_UPascalStrings, M3C_UnicodeMixedLib,
  M3C_MemoryStream, M3C_MemoryRaster,
  M3C_Geometry2D,
  M3C_Status,
  M3C_FFMPEG;

type
  TFFMPEG_Extract_Tool = class;

  TFFMPEG_Extract_Tool_Codec_Stream_ = record
    CodecContext: PAVCodecContext;
    Codec: PAVCodec;
    StreamIndex: integer;
    Stream: PAVStream;
    SWS_CTX: PSwsContext;
    FrameRGB: PAVFrame;
    FrameRGB_buffer: PByte;
    SWR_CTX: PSwrContext;
    Frame: PAVFrame;
    TB: Double;
    procedure Init;
    procedure Free;
    function IsVideo: Boolean;
    function IsAudio: Boolean;
  end;

  PFFMPEG_Extract_Tool_Codec_Stream_ = ^TFFMPEG_Extract_Tool_Codec_Stream_;
  TFFMPEG_Extract_Tool_Codec_Stream_Pool_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TGenericsList<PFFMPEG_Extract_Tool_Codec_Stream_>;

  TFFMPEG_Extract_Tool_Codec_Stream_Pool = class(TFFMPEG_Extract_Tool_Codec_Stream_Pool_Decl)
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clean;
    procedure BuildCodec(FFormatCtx: PAVFormatContext);
  end;

  TFFMPEG_Extract_Tool_Video_Transform = class
  public
    Trigger: TFFMPEG_Extract_Tool;
    Width, Height: integer;
    Ready: Boolean;
    constructor Create(Trigger_: TFFMPEG_Extract_Tool; Width_, Height_: TGeoFloat);
    destructor Destroy; override;
    procedure Transform(Input: PFFMPEG_Extract_Tool_Codec_Stream_; Output_: TRaster; CopyFrame_: Boolean);
  end;

  TDecode_State = (dsVideo, dsAudio, dsIgnore, dsError);
  TOn_Frame = procedure(Sender: TFFMPEG_Extract_Tool; Codec_Stream_: PFFMPEG_Extract_Tool_Codec_Stream_) of object;
  TVideoStream_Size_Pool = {$IFDEF FPC}specialize {$ENDIF FPC} TBigList<TRectV2>;

  TFFMPEG_Extract_Tool = class(TCore_Object)
  private
    FURL: TPascalString;
    FFormatCtx: PAVFormatContext;
    FPacket: PAVPacket;
    FCodec_Stream_Pool: TFFMPEG_Extract_Tool_Codec_Stream_Pool;
  public
    Current_Video, Current_Audio: PFFMPEG_Extract_Tool_Codec_Stream_;
    // state
    Current_VideoStream_Time: Double;
    Current_AudioStream_Time: Double;
    Current_Video_Frame: Int64;
    Current_Audio_Frame: Int64;
    Current_Video_Packet_Num: Int64;
    Current_Audio_Packet_Num: Int64;
    Width, Height: integer;
    Ready: Boolean;
    Enabled_Video: Boolean; // video default is enabled
    Enabled_Audio: Boolean; // audio default is disable
    OnVideo, OnAudio: TOn_Frame;
    property URL: TPascalString read FURL;

    constructor Create(const URL_: TPascalString);
    destructor Destroy; override;
    function OpenURL(const URL_: TPascalString): Boolean;
    function ReadAndDecodeFrame(): TDecode_State;
    procedure Close;
    procedure Seek(second: Double);
    function Get_VideoStream_Fit(Width_, Height_: TGeoFloat): TVideoStream_Size_Pool;

    // video info
    function VideoTotal: Double;
    function CurrentVideoStream_Total_Frame: Int64;
    function CurrentVideoStream_PerSecond_Frame(): Double;
    function CurrentVideoStream_PerSecond_FrameRound(): integer;
    property VideoPSF: Double read CurrentVideoStream_PerSecond_Frame;

    // Audio info
    function AudioTotal: Double;
    function CurrentAudioStream_Total_Frame: Int64;
    function CurrentAudioStream_PerSecond_Frame(): Double;
    function CurrentAudioStream_PerSecond_FrameRound(): integer;
    property AudioPSF: Double read CurrentAudioStream_PerSecond_Frame;
  end;

implementation

procedure TFFMPEG_Extract_Tool_Codec_Stream_.Init;
begin
  CodecContext := nil;
  Codec := nil;
  StreamIndex := -1;
  Stream := nil;
  FrameRGB := nil;
  FrameRGB_buffer := nil;
  SWS_CTX := nil;
  SWR_CTX := nil;
  Frame := nil;
  TB := 0;
end;

procedure TFFMPEG_Extract_Tool_Codec_Stream_.Free;
begin
  if CodecContext <> nil then
      avcodec_close(CodecContext);
  if FrameRGB_buffer <> nil then
      av_free(FrameRGB_buffer);
  if FrameRGB <> nil then
      av_free(FrameRGB);
  if SWS_CTX <> nil then
      sws_freeContext(SWS_CTX);
  if SWR_CTX <> nil then
      swr_free(@SWR_CTX);
  if Frame <> nil then
      av_free(Frame);

  CodecContext := nil;
  Codec := nil;
  StreamIndex := -1;
  Stream := nil;
  FrameRGB := nil;
  FrameRGB_buffer := nil;
  SWS_CTX := nil;
  SWR_CTX := nil;
  Frame := nil;
end;

function TFFMPEG_Extract_Tool_Codec_Stream_.IsVideo: Boolean;
begin
  Result := CodecContext^.codec_type = TAVMediaType.AVMEDIA_TYPE_VIDEO;
end;

function TFFMPEG_Extract_Tool_Codec_Stream_.IsAudio: Boolean;
begin
  Result := CodecContext^.codec_type = TAVMediaType.AVMEDIA_TYPE_AUDIO;
end;

constructor TFFMPEG_Extract_Tool_Codec_Stream_Pool.Create;
begin
  inherited Create;
end;

destructor TFFMPEG_Extract_Tool_Codec_Stream_Pool.Destroy;
begin
  Clean;
  inherited Destroy;
end;

procedure TFFMPEG_Extract_Tool_Codec_Stream_Pool.Clean;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
      Items[i]^.Free;
  inherited Clear;
end;

procedure TFFMPEG_Extract_Tool_Codec_Stream_Pool.BuildCodec(FFormatCtx: PAVFormatContext);
var
  i: integer;
  av_st: PPAVStream;
  p: PFFMPEG_Extract_Tool_Codec_Stream_;
  error_: Boolean;
begin
  av_st := FFormatCtx^.streams;
  for i := 0 to FFormatCtx^.nb_streams - 1 do
    begin
      if av_st^^.Codec^.codec_type in [AVMEDIA_TYPE_VIDEO, AVMEDIA_TYPE_AUDIO] then
        begin
          new(p);
          p^.Init;
          p^.StreamIndex := av_st^^.index;
          p^.CodecContext := av_st^^.Codec;
          p^.Stream := av_st^;
          p^.Codec := avcodec_find_decoder(p^.CodecContext^.codec_id);
          error_ := False;
          if p^.Codec <> nil then
            begin
              if avcodec_open2(p^.CodecContext, p^.Codec, nil) < 0 then
                begin
                  DoStatus('Could not open Codec.');
                  error_ := True;
                end;
            end
          else
            begin
              DoStatus('no found Codec.');
              error_ := True;
            end;

          if not error_ then
            begin
              p^.Frame := av_frame_alloc();
              with p^.Stream^.time_base do
                  p^.TB := Num / den;
              Add(p);
            end;
        end;
      inc(av_st);
    end;
end;

constructor TFFMPEG_Extract_Tool_Video_Transform.Create(Trigger_: TFFMPEG_Extract_Tool; Width_, Height_: TGeoFloat);
var
  i: integer;
  p: PFFMPEG_Extract_Tool_Codec_Stream_;
  R: TRectV2;
begin
  inherited Create;
  Trigger := Trigger_;
  Ready := False;

  if Trigger.Enabled_Video then
    for i := 0 to Trigger.FCodec_Stream_Pool.Count - 1 do
      begin
        p := Trigger.FCodec_Stream_Pool[i];
        if p^.IsVideo then
          begin
            Ready := True;
            if (p^.FrameRGB = nil) and (p^.FrameRGB_buffer = nil) and (p^.SWS_CTX = nil) then
              begin
                if Width_ <= 0 then
                    Width_ := p^.CodecContext^.Width;
                if Height_ <= 0 then
                    Height_ := p^.CodecContext^.Height;

                R := FitRect(p^.CodecContext^.Width, p^.CodecContext^.Height, RectV2(0, 0, Width_, Height_));
                Width := Round(RectWidth(R));
                Height := Round(RectHeight(R));

                p^.FrameRGB := av_frame_alloc();
                p^.FrameRGB_buffer := av_malloc(avpicture_get_size(AV_PIX_FMT_RGB32, Width, Height) * sizeof(Cardinal));
                p^.SWS_CTX := sws_getContext(
                  p^.CodecContext^.Width,
                  p^.CodecContext^.Height,
                  p^.CodecContext^.pix_fmt,
                  Width,
                  Height,
                  AV_PIX_FMT_RGB32,
                  SWS_FAST_BILINEAR,
                  nil,
                  nil,
                  nil);
                avpicture_fill(PAVPicture(p^.FrameRGB), p^.FrameRGB_buffer, AV_PIX_FMT_RGB32, Width, Height);
              end;
          end;
      end;
end;

destructor TFFMPEG_Extract_Tool_Video_Transform.Destroy;
begin
  inherited Destroy;
end;

procedure TFFMPEG_Extract_Tool_Video_Transform.Transform(Input: PFFMPEG_Extract_Tool_Codec_Stream_; Output_: TRaster; CopyFrame_: Boolean);
begin
  if not Ready then
      exit;
  sws_scale(
    Input^.SWS_CTX,
    @Input^.Frame^.Data,
    @Input^.Frame^.linesize,
    0,
    Input^.CodecContext^.Height,
    @Input^.FrameRGB^.Data,
    @Input^.FrameRGB^.linesize);
  if CopyFrame_ then
    begin
      Output_.SetSize(Width, Height);
      CopyPtr(Input^.FrameRGB^.Data[0], Output_.DirectBits, Width * Height * 4);
    end
  else
      Output_.SetWorkMemory(Input^.FrameRGB^.Data[0], Width, Height);
end;

constructor TFFMPEG_Extract_Tool.Create(const URL_: TPascalString);
begin
  inherited Create;
  OnVideo := nil;
  OnAudio := nil;
  Enabled_Video := True;
  Enabled_Audio := False;
  FCodec_Stream_Pool := TFFMPEG_Extract_Tool_Codec_Stream_Pool.Create;
  Ready := OpenURL(URL_);
end;

destructor TFFMPEG_Extract_Tool.Destroy;
begin
  Close;
  DisposeObject(FCodec_Stream_Pool);
  inherited Destroy;
end;

function TFFMPEG_Extract_Tool.OpenURL(const URL_: TPascalString): Boolean;
var
  gpu_decodec: PAVCodec;
  AV_Options: PPAVDictionary;
  tmp: Pointer;
  i: integer;
  p: Pointer;
begin
  Result := False;
  FURL := URL_;

  Current_Video := nil;
  Current_Audio := nil;
  AV_Options := nil;
  FFormatCtx := nil;
  FPacket := nil;
  Width := 0;
  Height := 0;
  FCodec_Stream_Pool.Clean;

  p := URL_.BuildPlatformPChar;

  // Open video file
  try
    tmp := TPascalString(umlIntToStr(128 * 1024 * 1024)).BuildPlatformPChar;
    av_dict_set(@AV_Options, 'buffer_size', tmp, 0);
    av_dict_set(@AV_Options, 'stimeout', '6000000', 0);
    av_dict_set(@AV_Options, 'rtsp_flags', '+prefer_tcp', 0);
    av_dict_set(@AV_Options, 'rtsp_transport', '+tcp', 0);
    TPascalString.FreePlatformPChar(tmp);

    if (avformat_open_input(@FFormatCtx, PAnsiChar(p), nil, @AV_Options) <> 0) then
      begin
        DoStatus('Could not open source file %s', [URL_.Text]);
        exit;
      end;

    // Retrieve stream information
    if avformat_find_stream_info(FFormatCtx, nil) < 0 then
      begin
        if FFormatCtx <> nil then
            avformat_close_input(@FFormatCtx);

        DoStatus('Could not find stream information %s', [URL_.Text]);
        exit;
      end;

    if IsConsole then
        av_dump_format(FFormatCtx, 0, PAnsiChar(p), 0);

    FCodec_Stream_Pool.BuildCodec(FFormatCtx);

    for i := 0 to FCodec_Stream_Pool.Count - 1 do
      begin
        if (Current_Video = nil) and (FCodec_Stream_Pool[i]^.IsVideo) then
            Current_Video := FCodec_Stream_Pool[i]
        else if (Current_Audio = nil) and (FCodec_Stream_Pool[i]^.IsAudio) then
            Current_Audio := FCodec_Stream_Pool[i];
        if (Current_Video <> nil) and (Current_Audio <> nil) then
            break;
      end;

    FPacket := av_packet_alloc();
    Current_VideoStream_Time := 0;
    Current_AudioStream_Time := 0;
    Current_Video_Frame := 0;
    Current_Audio_Frame := 0;
    Current_Video_Packet_Num := 0;
    Current_Audio_Packet_Num := 0;
    Result := True;
  finally
      TPascalString.FreePlatformPChar(p);
  end;
end;

function TFFMPEG_Extract_Tool.ReadAndDecodeFrame(): TDecode_State;
var
  p: PFFMPEG_Extract_Tool_Codec_Stream_;
  i: integer;
  error_: Boolean;
  R: integer;
begin
  Result := dsError;
  error_ := False;
  try
    while True do
      begin
        R := av_read_frame(FFormatCtx, FPacket);
        if R < 0 then
          begin
            DoStatus('av_read_frame: %s', [av_err2str(R)]);
            break;
          end;

        p := nil;
        for i := 0 to FCodec_Stream_Pool.Count - 1 do
          if FCodec_Stream_Pool[i]^.StreamIndex = FPacket^.stream_index then
            begin
              p := FCodec_Stream_Pool[i];
              break;
            end;

        if p = nil then
            continue;

        if p^.IsVideo then
          begin
            if Enabled_Video then
                R := avcodec_send_packet(p^.CodecContext, FPacket)
            else
                R := 0;
            inc(Current_Video_Packet_Num);
          end
        else if p^.IsAudio then
          begin
            if Enabled_Audio then
                R := avcodec_send_packet(p^.CodecContext, FPacket)
            else
                R := 0;
            inc(Current_Audio_Packet_Num);
          end
        else
            continue;

        if R < 0 then
          begin
            DoStatus('Error sending a packet for decoding: %s', [av_err2str(R)]);
            continue;
          end;

        error_ := False;
        while True do
          begin
            if p^.IsVideo then
              begin
                if Enabled_Video then
                    R := avcodec_receive_frame(p^.CodecContext, p^.Frame)
                else
                    R := 0;
              end
            else if p^.IsAudio then
              begin
                if Enabled_Audio then
                    R := avcodec_receive_frame(p^.CodecContext, p^.Frame)
                else
                    R := 0;
              end
            else
              begin
                DoStatus('Error straming error: %s', [av_err2str(R)]);
                exit;
              end;

            // success
            if R = 0 then
              begin
                if p^.IsVideo then
                  begin
                    if Enabled_Video then
                      begin
                        inc(Current_Video_Frame);
                        if (FPacket^.PTS > 0) and (av_q2d(p^.Stream^.time_base) > 0) then
                            Current_VideoStream_Time := FPacket^.PTS * av_q2d(p^.Stream^.time_base);
                        try
                          if Assigned(OnVideo) then
                              OnVideo(self, p);
                        except
                        end;
                        Current_Video := p;
                        Width := p^.CodecContext^.Width;
                        Height := p^.CodecContext^.Height;
                        Result := dsVideo;
                      end
                    else
                        Result := dsIgnore;
                  end
                else if p^.IsAudio then
                  begin
                    if Enabled_Audio then
                      begin
                        inc(Current_Audio_Frame);
                        if (FPacket^.PTS > 0) and (av_q2d(p^.Stream^.time_base) > 0) then
                            Current_AudioStream_Time := FPacket^.PTS * av_q2d(p^.Stream^.time_base);

                        try
                          if Assigned(OnAudio) then
                              OnAudio(self, p);
                        except
                        end;
                        Current_Audio := p;
                        Result := dsAudio;
                      end
                    else
                        Result := dsIgnore;
                  end;
                break;
              end;

            // AVERROR(EAGAIN): Output is not available in this state - user must try to send new input
            if R = AVERROR_EAGAIN then
              begin
                av_packet_unref(FPacket);
                Result := ReadAndDecodeFrame();
                exit;
              end;

            // AVERROR_EOF: the decoder has been fully flushed, and there will be no more Output frames
            if R = AVERROR_EOF then
              begin
                if p^.IsVideo then
                    avcodec_flush_buffers(p^.CodecContext)
                else if p^.IsAudio then
                    avcodec_flush_buffers(p^.CodecContext)
                else
                  begin
                    DoStatus('Error straming error.');
                    exit;
                  end;
                continue;
              end;

            // error
            if R < 0 then
              begin
                error_ := True;
                break;
              end;
          end;

        if (not error_) then
          begin
            // done
          end;

        error_ := True;
        av_packet_unref(FPacket);
        break;
      end;
  except
  end;
end;

procedure TFFMPEG_Extract_Tool.Close;
begin
  FCodec_Stream_Pool.Clean;
  if FPacket <> nil then
      av_free_packet(FPacket);

  if FFormatCtx <> nil then
      avformat_close_input(@FFormatCtx);

  FFormatCtx := nil;
  FPacket := nil;
  Width := 0;
  Height := 0;
  Current_VideoStream_Time := 0;
  Current_AudioStream_Time := 0;
  Current_Video_Frame := 0;
  Current_Audio_Frame := 0;
end;

procedure TFFMPEG_Extract_Tool.Seek(second: Double);
begin
  if second = 0 then
    begin
      Close;
      Ready := OpenURL(FURL);
    end
  else
    begin
      av_seek_frame(FFormatCtx, -1, Round(second * AV_TIME_BASE), AVSEEK_FLAG_ANY);
    end;
end;

function TFFMPEG_Extract_Tool.Get_VideoStream_Fit(Width_, Height_: TGeoFloat): TVideoStream_Size_Pool;
var
  i: integer;
  p: PFFMPEG_Extract_Tool_Codec_Stream_;
begin
  Result := TVideoStream_Size_Pool.Create;
  for i := 0 to FCodec_Stream_Pool.Count - 1 do
    begin
      p := FCodec_Stream_Pool[i];
      if p^.IsVideo then
        begin
          if Width_ <= 0 then
              Width_ := p^.CodecContext^.Width;
          if Height_ <= 0 then
              Height_ := p^.CodecContext^.Height;

          Result.Add(FitRect(p^.CodecContext^.Width, p^.CodecContext^.Height, RectV2(0, 0, Width_, Height_)));
        end;
    end;
end;

function TFFMPEG_Extract_Tool.VideoTotal: Double;
begin
  Result := umlMax(FFormatCtx^.duration / AV_TIME_BASE, 0);
  if IsNan(Result) then
      Result := 0;
end;

function TFFMPEG_Extract_Tool.CurrentVideoStream_Total_Frame: Int64;
begin
  if Current_Video <> nil then
      Result := umlMax(Current_Video^.Stream^.nb_frames, 0)
  else
      Result := 0;
end;

function TFFMPEG_Extract_Tool.CurrentVideoStream_PerSecond_Frame(): Double;
begin
  if Current_Video <> nil then
    begin
      with Current_Video^.Stream^.r_frame_rate do
          Result := umlMax(Num / den, 0);
      if IsNan(Result) then
          Result := 0;
    end
  else
      Result := 0;
end;

function TFFMPEG_Extract_Tool.CurrentVideoStream_PerSecond_FrameRound(): integer;
begin
  Result := Round(CurrentVideoStream_PerSecond_Frame());
end;

function TFFMPEG_Extract_Tool.AudioTotal: Double;
begin
  Result := umlMax(FFormatCtx^.duration / AV_TIME_BASE, 0);
  if IsNan(Result) then
      Result := 0;
end;

function TFFMPEG_Extract_Tool.CurrentAudioStream_Total_Frame: Int64;
begin
  if Current_Audio <> nil then
      Result := umlMax(Current_Audio^.Stream^.nb_frames, 0)
  else
      Result := 0;
end;

function TFFMPEG_Extract_Tool.CurrentAudioStream_PerSecond_Frame(): Double;
begin
  if Current_Audio <> nil then
    begin
      with Current_Audio^.Stream^.r_frame_rate do
          Result := umlMax(Num / den, 0);
      if IsNan(Result) then
          Result := 0;
    end
  else
      Result := 0;
end;

function TFFMPEG_Extract_Tool.CurrentAudioStream_PerSecond_FrameRound(): integer;
begin
  Result := Round(CurrentAudioStream_PerSecond_Frame());
end;

end.
