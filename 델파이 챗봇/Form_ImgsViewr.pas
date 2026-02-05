unit Form_ImgsViewr;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, AdvSmoothPanel, math, Menus, AdvMenus,
  AdvGlowButton, JPEG, GDIPAPI, GDIPOBJ;

const
  WM_POST_RENDER = WM_USER + 100;

type
  TFormImgsViewr = class(TForm)
    AdvSmoothPanel8: TAdvSmoothPanel;
    Img3_Views: TImage;
    Apm3_ISAVE: TAdvPopupMenu;
    NImage01: TMenuItem;
    ODig_Open1: TOpenDialog;
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure NImage01Click(Sender: TObject);
    procedure Img3_ViewsDblClick(Sender: TObject);
  private
    Rl_ImgLs : TList;
    Ri_CrIdx : Integer;

    procedure WMPostRender(var Msg: TMessage); message WM_POST_RENDER;
    { Private declarations }
  public
    { Public declarations }
    procedure Pcb_ShowCurImg;
    procedure Pcb_ImgListIdx(Il_ImgLs : TList; Ii_IgIdx : Integer);
  end;

var
  FormImgsViewr: TFormImgsViewr;

implementation

{$R *.dfm}

procedure TFormImgsViewr.FormShow(Sender: TObject);
begin
  ODig_Open1.Filter := 'JPEG Image (*.jpg;*.jpeg)|*.jpg;*.jpeg|';
  FormImgsViewr.Caption := '이미지 뷰어';

  PostMessage(Handle, WM_POST_RENDER, 0, 0);
end;

procedure TFormImgsViewr.WMPostRender(var Msg: TMessage);
begin
  Pcb_ShowCurImg;
end;

procedure TFormImgsViewr.Pcb_ImgListIdx(Il_ImgLs : TList; Ii_IgIdx : Integer);
Begin
  Rl_ImgLs := Il_ImgLs;
  Ri_CrIdx := Ii_IgIdx;
End;

procedure TFormImgsViewr.Pcb_ShowCurImg;
Var
  Mm_CrImg : TImage;
  Mj_ImJPG : TJPEGImage;
  Mb_Btmap : TBitmap;
  Mr_TRect : TRect;
  Md_Ratio : Double;
  Mi_Width, Mi_Heigt : Integer;
  Mg_Grpic : TGPGraphics;
  MG_GPBIT : TGPBitmap;
  Mr_OFGPS : TRect;

  Mw_WInSt : TWindowState;
Begin
  If (Rl_ImgLs <> Nil) And (Ri_CrIdx >= 0) And (Ri_CrIdx < Rl_ImgLs.Count) Then
  Begin
    // 현재 폼 위치 저장
    GetWindowRect(Handle, Mr_OFGPS);
    // 폼을 화면 바깥으로 이동시키고 최대 크기로 확장
    SetBounds(-10000, -10000, Screen.Width, Screen.Height);
    //Mw_WInSt := WindowState;
    //WindowState := wsMaximized;

    Mm_CrImg := TImage(Rl_ImgLs[Ri_CrIdx]);
    Mj_ImJPG := TJPEGImage.Create;
    Mb_Btmap := TBitmap.Create;

    Try
      // JPEG → Bitmap 변환
      Mj_ImJPG.Assign(Mm_CrImg.Picture.Graphic);   // JPEG → JpegImage
      Mb_Btmap.PixelFormat := pf24bit;
      Mb_Btmap.Width := Mj_ImJPG.Width;
      Mb_Btmap.Height := Mj_ImJPG.Height;
      Mb_Btmap.Canvas.Draw(0, 0, Mj_ImJPG);        // Jpeg → Bitmap 변환

      // 배경 초기화
      Img3_Views.Picture := Nil;
      Img3_Views.Canvas.Brush.Color := clWhite;
      Img3_Views.Canvas.FillRect(Img3_Views.ClientRect);

      // 이미지 사이즈 계산
      If (Mb_Btmap.Width <= Img3_Views.Width) And (Mb_Btmap.Height <= Img3_Views.Height) Then
      Begin
        Mi_Width := Mb_Btmap.Width;
        Mi_Heigt := Mb_Btmap.Height;
      End Else
      Begin
        Md_Ratio := Min(Img3_Views.Width / Mb_Btmap.Width, Img3_Views.Height / Mb_Btmap.Height);
        Mi_Width := Round(Mb_Btmap.Width * Md_Ratio);
        Mi_Heigt := Round(Mb_Btmap.Height * Md_Ratio);
      End;

      Mr_TRect.Left := (Img3_Views.Width - Mi_Width) div 2;
      Mr_TRect.Top := (Img3_Views.Height - Mi_Heigt) div 2;
      Mr_TRect.Right := Mr_TRect.Left + Mi_Width;
      Mr_TRect.Bottom := Mr_TRect.Top + Mi_Heigt;

      // GDI+ 를 이용한 고품질 렌더링
      Mg_Grpic := TGPGraphics.Create(Img3_Views.Canvas.Handle);
      Try
        Mg_Grpic.SetInterpolationMode(InterpolationModeHighQualityBicubic);
        MG_GPBIT := TGPBitmap.Create(Mb_Btmap.Handle, 0);
        Try
          Mg_Grpic.DrawImage(MG_GPBIT, MakeRect(Mr_TRect.Left, Mr_TRect.Top, Mi_Width, Mi_Heigt));
        Finally
          MG_GPBIT.Free;
        End;
      Finally
        Mg_Grpic.Free;
      End;
    Finally
      Mj_ImJPG.Free;
      Mb_Btmap.Free;
    End;

    //WindowState := Mw_WInSt;
    // 렌더링 끝난 후 폼 위치/크기 원래대로 복구
    SetBounds(Mr_OFGPS.Left, Mr_OFGPS.Top,
              Mr_OFGPS.Right - Mr_OFGPS.Left,
              Mr_OFGPS.Bottom - Mr_OFGPS.Top);
  End;
End;

procedure TFormImgsViewr.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  Case Key Of
    //완쪽 방향키
    VK_LEFT :
      If Ri_CrIdx > 0 Then
      begin
        Dec(Ri_CrIdx);
        Pcb_ShowCurImg;
      End;
    //오른쪽 방향키
    VK_RIGHT :
      If Ri_CrIdx < Rl_ImgLs.Count - 1 Then
      Begin
        Inc(Ri_CrIdx);
        Pcb_ShowCurImg;
      End;
    //ESC 버튼
    VK_ESCAPE :
      Close;
  End;
end;


procedure TFormImgsViewr.NImage01Click(Sender: TObject);
var
  Mm_CrImg: TImage;
begin
  If ODig_Open1.Execute Then
  Begin
    Mm_CrImg := TImage(Rl_ImgLs[Ri_CrIdx]);  // 원본 이미지 참조

    If Pos('.JPG', UpperCase(ODig_Open1.FileName)) > 0 Then
      Mm_CrImg.Picture.SaveToFile(ODig_Open1.FileName)
    Else
      Mm_CrImg.Picture.SaveToFile(ODig_Open1.FileName + '.JPG');
  End;
end;

procedure TFormImgsViewr.Img3_ViewsDblClick(Sender: TObject);
begin
  If WindowState = wsNormal Then
  Begin
    WindowState := wsMaximized;
    Pcb_ShowCurImg;
  End Else
  If WindowState = wsMaximized Then
    WindowState := wsNormal;
end;

end.
