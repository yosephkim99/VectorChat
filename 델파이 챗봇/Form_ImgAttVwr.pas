unit Form_ImgAttVwr;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, AdvSmoothPanel;

type
  TFormImgAttVwr = class(TForm)
    AdvSmoothPanel8: TAdvSmoothPanel;
    Img3_Views: TImage;
    Lbl0_Views: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    Rl_ImgLs : TList;
    Ri_CrIdx : Integer;

    { Private declarations }
  public
    { Public declarations }
    procedure Pcb_ShowCurImg;
    procedure Pcb_ImgListIdx(Il_ImgLs : TList; Ii_IgIdx : Integer);
  end;

var
  FormImgAttVwr: TFormImgAttVwr;

implementation

{$R *.dfm}

procedure TFormImgAttVwr.FormShow(Sender: TObject);
begin
  FormImgAttVwr.Caption := '이미지 뷰어';
end;

procedure TFormImgAttVwr.Pcb_ImgListIdx(Il_ImgLs : TList; Ii_IgIdx : Integer);
Begin
  Rl_ImgLs := Il_ImgLs;
  Ri_CrIdx := Ii_IgIdx;

  Pcb_ShowCurImg;
End;

procedure TFormImgAttVwr.Pcb_ShowCurImg;
Var
  Mm_CrImg : TImage;
Begin
  If (Rl_ImgLs <> Nil) And (Ri_CrIdx >= 0) And (Ri_CrIdx < Rl_ImgLs.Count) then
  Begin
    Mm_CrImg := TImage(Rl_ImgLs[Ri_CrIdx]);
    Img3_Views.Picture.Assign(Mm_CrImg.Picture); // 그림 복사
  End;
End;

procedure TFormImgAttVwr.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  Case Key Of
    VK_LEFT:
      If Ri_CrIdx > 0 Then
      begin
        Dec(Ri_CrIdx);
        Pcb_ShowCurImg;
      End;

    VK_RIGHT:
      If Ri_CrIdx < Rl_ImgLs.Count - 1 Then
      Begin
        Inc(Ri_CrIdx);
        Pcb_ShowCurImg;
      End;
  End;
end;

end.
