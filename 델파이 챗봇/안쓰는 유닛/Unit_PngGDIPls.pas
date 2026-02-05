unit Unit_PngGDIPls;

interface

uses Windows, Graphics, SysUtils, Classes, ActiveX, EncdDecd;

procedure LoadPNGIntoPicture(const FileName: string; APicture: TPicture);
procedure LoadBase64PNGIntoPicture(const Base64: string; APicture: TPicture);

implementation

const
  GDIP_DLL = 'gdiplus.dll';

type
  ULONG_PTR = ^NativeUInt;
  TGDIPlusStartupInput = packed record
    GdiplusVersion          : Cardinal;
    DebugEventCallback      : Pointer;
    SuppressBackgroundThread: BOOL;
    SuppressExternalCodecs  : BOOL;
  end;
  PGDIPlusStartupInput = ^TGDIPlusStartupInput;
  GpImage   = Pointer;
  GpBitmap  = Pointer;
  GpStatus  = Integer;

var
  GdiplusToken : ULONG_PTR = nil;
  GdipStartup  : function(out token: ULONG_PTR; input: PGDIPlusStartupInput; reserved: Pointer): Integer; stdcall;
  GdipShutdown : procedure(token: ULONG_PTR); stdcall;
  GdipCreateBitmapFromFile : function(filename: PWideChar; out bitmap: GpBitmap): Integer; stdcall;
  GdipCreateHBITMAPFromBitmap : function(bitmap: GpBitmap; out hbmReturn: HBITMAP; background: DWORD): Integer; stdcall;
  GdipDisposeImage : function(image: GpImage): Integer; stdcall;
  GdipCreateBitmapFromStream : function(Stream: IStream; out Bitmap: GpBitmap): Integer; stdcall;

procedure InitGDIPlus;
var
  LibHandle: HMODULE;
  SI       : TGDIPlusStartupInput;
begin
  if GdiplusToken = nil then
  begin
    LibHandle := LoadLibrary(GDIP_DLL);
    if LibHandle = 0 then
      raise Exception.Create('gdiplus.dll not found');

    @GdipStartup                   := GetProcAddress(LibHandle, 'GdiplusStartup');
    @GdipShutdown                  := GetProcAddress(LibHandle, 'GdiplusShutdown');
    @GdipCreateBitmapFromFile      := GetProcAddress(LibHandle, 'GdipCreateBitmapFromFile');
    @GdipCreateHBITMAPFromBitmap   := GetProcAddress(LibHandle, 'GdipCreateHBITMAPFromBitmap');
    @GdipDisposeImage              := GetProcAddress(LibHandle, 'GdipDisposeImage');
    @GdipCreateBitmapFromStream := GetProcAddress(LibHandle, 'GdipCreateBitmapFromStream');

    FillChar(SI, SizeOf(SI), 0);
    SI.GdiplusVersion := 1;
    if GdipStartup(GdiplusToken, @SI, nil) <> 0 then
      raise Exception.Create('GDI+ initialization failed');
  end;
end;

procedure LoadPNGIntoPicture(const FileName: string; APicture: TPicture);
var
  GPBmp : GpBitmap;
  HBmp  : HBITMAP;
  TmpBmp: TBitmap;
begin
  InitGDIPlus;

  if GdipCreateBitmapFromFile(PWideChar(WideString(FileName)), GPBmp) <> 0 then
    raise Exception.Create('PNG load error: ' + FileName);

  if GdipCreateHBITMAPFromBitmap(GPBmp, HBmp, $00FFFFFF) <> 0 then
  begin
    GdipDisposeImage(GPBmp);
    raise Exception.Create('HBITMAP conversion error');
  end;

  TmpBmp := TBitmap.Create;
  try
    TmpBmp.Handle := HBmp;           // pf32bit 그대로
    APicture.Assign(TmpBmp);         // Picture에 복사
  finally
    TmpBmp.Free;
    GdipDisposeImage(GPBmp);         // GDI+ 이미지 해제
  end;
end;

procedure LoadBase64PNGIntoPicture(const Base64: string; APicture: TPicture);
var
  BinStream   : TMemoryStream;
  StreamAdapter: IStream;
  GPBmp       : GpBitmap;
  HBmp        : HBITMAP;
  TmpBmp      : TBitmap;
  Raw         : string;
begin
  InitGDIPlus;

  { 1) Base64 → 바이너리 스트림 }
  Raw := DecodeString(Base64);           // EncdDecd.DecodeString = Base64 decode
  BinStream := TMemoryStream.Create;
  try
    BinStream.WriteBuffer(Pointer(Raw)^, Length(Raw));
    BinStream.Position := 0;

    { 2) TStream → IStream }
    StreamAdapter := TStreamAdapter.Create(BinStream, soReference);

    { 3) IStream → GDI+ Bitmap }
    if GdipCreateBitmapFromStream(StreamAdapter, GPBmp) <> 0 then
      raise Exception.Create('PNG load error (stream)');

    if GdipCreateHBITMAPFromBitmap(GPBmp, HBmp, $00FFFFFF) <> 0 then
    begin
      GdipDisposeImage(GPBmp);
      raise Exception.Create('HBITMAP conversion error');
    end;

    { 4) Picture 로 전달 }
    TmpBmp := TBitmap.Create;
    try
      TmpBmp.Handle := HBmp;
      APicture.Assign(TmpBmp);
    finally
      TmpBmp.Free;
      GdipDisposeImage(GPBmp);
    end;

  finally
    BinStream.Free;
  end;
end;

initialization
finalization
  if GdiplusToken <> nil then
    GdipShutdown(GdiplusToken);
end.

