unit Form_MesageBox;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, AdvObj, AdvGlowButton, ExtCtrls, AdvSmoothPanel;

type
  TFormMesageBox = class(TForm)
    Mem0_Body1: TMemo;
    Edt0_Subjt: TEdit;
    Btn0_Rlt01: TAdvGlowButton;
    Btn0_Rlt02: TAdvGlowButton;
    Btn0_Rlt03: TAdvGlowButton;
    Tmr0_Count: TTimer;
    Pnl0_ExCau: TAdvSmoothPanel;
    Lbl0_ExCau: TLabel;
    Cbx0_ExCau: TComboBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Btn0_Rlt01Click(Sender: TObject);
    procedure Btn0_Rlt02Click(Sender: TObject);
    procedure Btn0_Rlt03Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Tmr0_CountTimer(Sender: TObject);
  private
    { Private declarations }
    Ri_Count : Integer;
  public
    { Public declarations }
  end;

var
  FormMesageBox: TFormMesageBox;

implementation

{$R *.dfm}

procedure TFormMesageBox.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFormMesageBox.Btn0_Rlt01Click(Sender: TObject);
begin
  If (Pnl0_ExCau.Visible) And (Trim(Cbx0_ExCau.Text) = '') Then  //엑셀사유 입력해야함.
  Begin
    Mem0_Body1.Color := $00FEC9EF;
    Mem0_Body1.Text := '엑셀 저장하는 사유를 선택하세요' + #13#10 + '------------------------------' + #13#10 + Mem0_Body1.Text;
    Exit;
  End;
  ModalResult := 1;
end;

procedure TFormMesageBox.Btn0_Rlt02Click(Sender: TObject);
begin
  If (Pnl0_ExCau.Visible) And (Trim(Cbx0_ExCau.Text) = '') Then  //엑셀사유 입력해야함.
  Begin
    Mem0_Body1.Color := $00FEC9EF;
    Mem0_Body1.Text := '엑셀 저장하는 사유를 선택하세요' + #13#10 + '------------------------------' + #13#10 + Mem0_Body1.Text;
    Exit;
  End;
  ModalResult := 2;
end;

procedure TFormMesageBox.Btn0_Rlt03Click(Sender: TObject);
begin
  ModalResult := 3;
end;

procedure TFormMesageBox.FormShow(Sender: TObject);
begin
  Ri_Count := 0;
  If FormMesageBox.Btn0_Rlt01.Visible Then
    FormMesageBox.Btn0_Rlt01.SetFocus
  Else
  If FormMesageBox.Btn0_Rlt02.Visible Then
    FormMesageBox.Btn0_Rlt02.SetFocus
  Else
  If FormMesageBox.Btn0_Rlt03.Visible Then
    FormMesageBox.Btn0_Rlt03.SetFocus;
end;

procedure TFormMesageBox.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  If Key = Vk_Escape Then
    Btn0_Rlt03.Click;
end;

procedure TFormMesageBox.Tmr0_CountTimer(Sender: TObject);
begin
  Inc(Ri_Count);
  If FormMesageBox.Pnl0_ExCau.Hint = '06' Then
  Begin
    If Ri_Count > 5 Then
      Close;
  End Else
  If Ri_Count < 3 Then
  Begin
    SetWindowPos(FormMesageBox.handle, HWND_TOPMOST, FormMesageBox.Left, FormMesageBox.Top, FormMesageBox.Width, FormMesageBox.Height,0);
    Tmr0_Count.Enabled := False;
  End;

  //Inc(Ri_Count);
  //If Ri_Count > 10 Then
  //  Close;
end;

end.



