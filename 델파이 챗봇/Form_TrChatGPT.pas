unit Form_TrChatGPT;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, AdvGlowButton, StdCtrls, AdvSmoothPanel, DB, ADODB, IniFiles,
  StrUtils, DCPcrypt2, DCPblockciphers, DCPrijndael, uLkJSON,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  Grids, AdvObj, BaseGrid, AdvGrid, Clipbrd, ComCtrls, ExtCtrls, IdCoderMIME,
  EncdDecd, JPEG, Menus, AdvMenus;

type
  TFormTrChatGPT = class(TForm)
    Pnl0_Samp1: TAdvSmoothPanel;
    Btn3_INSRT: TAdvGlowButton;
    Cipher: TDCP_rijndael;
    IdHttp1: TIdHTTP;
    Grd0_DLIST: TAdvStringGrid;
    Edt3_DBIDS: TEdit;
    Label51: TLabel;
    Lavel01: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Edt3_HSPCD: TEdit;
    AdvSmoothPanel3: TAdvSmoothPanel;
    Btn0_Srch1: TAdvGlowButton;
    Label4: TLabel;
    Edt0_DBIDS: TEdit;
    Label5: TLabel;
    Edt0_DOCMT: TEdit;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Edt0_HSPCD: TEdit;
    Cbx3_ACCLV: TComboBox;
    Label10: TLabel;
    Edt0_CTGRY: TEdit;
    Label11: TLabel;
    Edt0_ANSWR: TEdit;
    Label12: TLabel;
    Edt0_VENDR: TEdit;
    Label13: TLabel;
    Edt3_CTGRY: TEdit;
    Cbx3_SUBJT: TComboBox;
    Cbx0_SUBJT: TComboBox;
    Ckx0_ACCLV: TComboBox;
    Btn3_Delet: TAdvGlowButton;
    Btn3_Clear: TAdvGlowButton;
    Btn3_UPDAT: TAdvGlowButton;
    Mmo3_ANSWR: TMemo;
    Mmo3_QUEST: TMemo;
    QUEST: TLabel;
    Label14: TLabel;
    Edt3_VENDR: TEdit;
    Prs0_Stat1: TProgressBar;
    Label15: TLabel;
    Cbx3_GPTPS: TComboBox;
    Img3_IMG01: TImage;
    Btn3_IMG01: TAdvGlowButton;
    Btn3_IMG02: TAdvGlowButton;
    Img3_IMG02: TImage;
    Btn3_IMG03: TAdvGlowButton;
    Img3_IMG03: TImage;
    Btn3_IMG04: TAdvGlowButton;
    Img3_IMG04: TImage;
    Btn3_IMG05: TAdvGlowButton;
    Img3_IMG05: TImage;
    ODig_FILES: TOpenDialog;
    Label16: TLabel;
    Cbx0_GPTPS: TComboBox;
    Label17: TLabel;
    Cbx0_IMGYN: TComboBox;
    Apm3_IMGPM: TAdvPopupMenu;
    NImgDelete: TMenuItem;
    NImgDelAll: TMenuItem;
    NImgSave: TMenuItem;
    Label9: TLabel;
    Cbx0_USEYN: TComboBox;
    Label18: TLabel;
    Cbx3_USEYN: TComboBox;
    Label19: TLabel;
    Cbx0_VECKD: TComboBox;
    procedure FormShow(Sender: TObject);
    procedure Btn3_INSRTClick(Sender: TObject);
    procedure Grd0_DLISTClickCell(Sender: TObject; ARow, ACol: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Btn0_Srch1Click(Sender: TObject);
    procedure Btn3_DeletClick(Sender: TObject);
    procedure Grd0_DLISTKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Btn3_ClearClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Btn3_UPDATClick(Sender: TObject);
    procedure Edt0_DOCMTKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Btn3_IMG01Click(Sender: TObject);
    procedure Img3_IMG01Click(Sender: TObject);
    procedure NImgDeleteClick(Sender: TObject);
    procedure NImgDelAllClick(Sender: TObject);
    procedure NImgSaveClick(Sender: TObject);
    procedure Mmo3_ANSWRKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Mmo3_QUESTKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Grd0_DLISTClick(Sender: TObject);
  private
    Rs_KEYST, Rs_IVSTR : AnsiString;
    Rs_RolBk : AnsiString;
    Rl_ImgLs : TList;
    Rl_ImgAr : array[0..4] of TImage;  // TImage 5개 고정 슬롯
    Ri_ImgId : Integer; // 현재 채운 이미지 수

    function Fcv_HttpComm01(Is_Gubun, Is_EhUrl, Is_Param : AnsiString) : AnsiString;
    function Fcv_JsonEscap(Is_Value: AnsiString) : AnsiString;
    function Fcv_GAes256Dec(Is_Value: AnsiString): AnsiString;
    function Fcv_GAes256Enc(Is_Value: AnsiString): AnsiString;
    function Fcv_GetPdPKCS7(Is_value: AnsiString): AnsiString;
    function Fcv_GetPadZero(const Is_Value: AnsiString; Ii_Sizes: integer): AnsiString;
    function Fcv_RemovePadd(Is_Value: AnsiString): AnsiString;  //패딩 제거 함수
    function Base64Encode(const Input: AnsiString): AnsiString;
    function Base64Decode(const Input: AnsiString): AnsiString;

    function Fcb_MessageBox(Is_Gubun, Is_Subjt, Is_Mesag : AnsiString) : Integer;
    procedure Pcb_LoadImages(Is_EnStr : AnsiString; Ig_TImage : TImage);
    procedure Pcb_APISearchI(Is_DBIDS : AnsiString; Ii_RowNm: Integer);
    procedure Pcb_AllClearEd;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormTrChatGPT: TFormTrChatGPT;

implementation

uses Form_AiChatGPT, Form_MesageBox, IdCoder, Form_ImgsViewr;

const
  Base64Out: array[0..64] of AnsiChar = (
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/', '='
    );
  Base64In: array[0..127] of Byte = (
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255,  62, 255, 255, 255,  63,  52,  53,  54,  55,
     56,  57,  58,  59,  60,  61, 255, 255, 255,  64, 255, 255, 255,
      0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,
     13,  14,  15,  16,  17,  18,  19,  20,  21,  22,  23,  24,  25,
    255, 255, 255, 255, 255, 255,  26,  27,  28,  29,  30,  31,  32,
     33,  34,  35,  36,  37,  38,  39,  40,  41,  42,  43,  44,  45,
     46,  47,  48,  49,  50,  51, 255, 255, 255, 255, 255
    );

{$R *.dfm}

procedure TFormTrChatGPT.FormShow(Sender: TObject);
begin
  Rs_KEYST := 'srmXqcz35qqoSw1zUYbJFuRg9qa==srm';
  Rs_IVSTR := 'SRIV1p2k3p4c5l6c';

  ODig_FILES.Filter := 'JPEG Image (*.jpg;*.jpeg)|*.jpg;*.jpeg|';

  Rl_ImgLs := TList.Create;

  Ri_ImgId := 0;

  // 폼에 배치한 이미지 컴포넌트들을 배열에 연결
  Rl_ImgAr[0] := Img3_IMG01;
  Rl_ImgAr[1] := Img3_IMG02;
  Rl_ImgAr[2] := Img3_IMG03;
  Rl_ImgAr[3] := Img3_IMG04;
  Rl_ImgAr[4] := Img3_IMG05;

  Rl_ImgLs.Clear;

  Mmo3_QUEST.SetFocus;
end;

Function TFormTrChatGPT.Fcv_JsonEscap(Is_Value : AnsiString) : AnsiString;
Var
  Ms_Reslt : AnsiString;
Begin
  Result := '';

  Ms_Reslt := Trim(Is_Value);

  // 사용자 입력에서 \n 또는 \N 을 실제 줄바꿈으로 변환
  Ms_Reslt := StringReplace(Ms_Reslt, '\n', sLineBreak, [rfReplaceAll, rfIgnoreCase]);
  Ms_Reslt := StringReplace(Ms_Reslt, '\', '\\', [rfReplaceAll]);
  Ms_Reslt := StringReplace(Ms_Reslt, '"', '\"', [rfReplaceAll]);
  // 줄바꿈도 JSON 표준 이스케이프로
  Ms_Reslt := StringReplace(Ms_Reslt, sLineBreak, '\n', [rfReplaceAll]);

  Result := Ms_Reslt;
End;

function TFormTrChatGPT.Fcv_GAes256Enc(Is_Value : AnsiString) : AnsiString;
var
  Ms_VData, Ms_Keysr, Ms_IvStr : AnsiString;
begin
  Result := '';
  // Pad Key, IV and Data with zeros as appropriate
  Ms_Keysr := Fcv_GetPadZero(Rs_KEYST,32);  //32바이트
  Ms_IvStr := Fcv_GetPadZero(Rs_IVSTR,16);   //16바이트
  // UTF-8 인코딩된 데이터 준비
  Ms_VData := Fcv_GetPdPKCS7(UTF8Encode(Is_Value));

  //Create the cipher and initialise according o the key length
  If Length(Rs_KEYST) <= 16 Then
    Cipher.Init(Ms_Keysr[1],128,@Ms_IvStr[1])
  Else if Length(Rs_KEYST) <= 24 Then
    Cipher.Init(Ms_Keysr[1],192,@Ms_IvStr[1])
  Else
    Cipher.Init(Ms_Keysr[1],256,@Ms_IvStr[1]);

  // Encrypt the data
  Cipher.EncryptCBC(Ms_VData[1],Ms_VData[1],Length(Ms_VData));

  // Free the cipher and clear sensitive information
  //Cipher.Free;
  FillChar(Ms_Keysr[1],Length(Ms_Keysr),0);

  // Display the Base64 encoded result
  //Result := Unit_FctionGrp.Fcb_ValueToHex(Ms_VData)
  Result := Base64Encode(Ms_VData)   //base64
end;

function TFormTrChatGPT.Fcv_GAes256Dec(Is_Value : AnsiString) : AnsiString;
var
  Ms_VData, Ms_Keysr, Ms_IvStr : AnsiString;
begin
  Result := '';

  // Pad Key and IV with zeros as appropriate
  Ms_Keysr := Fcv_GetPadZero(Rs_KEYST, 32);
  Ms_IvStr := Fcv_GetPadZero(Rs_IVSTR, 16);

  // Decode the Base64 encoded string
  Ms_VData := Base64Decode(Is_Value);

  // Create the cipher and initialise according to the key length
  If Length(Rs_KEYST) <= 16 Then
    Cipher.Init(Ms_Keysr[1],128,@Ms_IvStr[1])
  Else If Length(Rs_KEYST) <= 24 Then
    Cipher.Init(Ms_Keysr[1],192,@Ms_IvStr[1])
  Else
    Cipher.Init(Ms_Keysr[1],256,@Ms_IvStr[1]);

  // Decrypt the data
  Cipher.DecryptCBC(Ms_VData[1],Ms_VData[1],Length(Ms_VData));

  // Free the cipher and clear sensitive information
  //Cipher.Free;
  FillChar(Ms_Keysr[1],Length(Ms_Keysr),0);

  // 패딩 제거 및 UTF-8 디코딩
  Ms_VData := Fcv_RemovePadd(Ms_VData);
  Result := UTF8Decode(Ms_VData);
end;

function TFormTrChatGPT.Fcv_GetPadZero(const Is_Value : AnsiString; Ii_Sizes : Integer) : AnsiString;
var
  Mi_Osize, Mi_Imfor : integer;
begin
  Result := Is_Value;
  Mi_Osize := Length(Result);
  If ((Mi_Osize mod Ii_Sizes) <> 0) or (Mi_Osize = 0) Then
  Begin
    SetLength(Result,((Mi_Osize div Ii_Sizes)+1)*Ii_Sizes);
    For Mi_Imfor := Mi_Osize+1 To Length(Result) Do
      Result[Mi_Imfor] := #0;  //nul
  End;
end;

function TFormTrChatGPT.Fcv_GetPdPKCS7(Is_value : AnsiString) : AnsiString;
var
  Mi_Blksz, Mi_Padlg : Integer;
  Ms_Encsr, Ms_Padsr: AnsiString;
begin
  Mi_Blksz := 16;
  Ms_Encsr := Is_value;
  Mi_Padlg := Mi_Blksz - (Length(Ms_Encsr) mod Mi_Blksz);
  Ms_Padsr := StringOfChar(Chr(Mi_Padlg), Mi_Padlg);
  result := (Ms_Encsr + Ms_Padsr);
end;

function TFormTrChatGPT.Fcv_RemovePadd(Is_Value: AnsiString): AnsiString;
var
  Mi_LenPd : Integer;
Begin
  Mi_LenPd := Ord(Is_Value[Length(Is_Value)]); // 패딩 길이는 마지막 바이트의 값
  If (Mi_LenPd > 0) And (Mi_LenPd <= Length(Is_Value)) Then
    Result := Copy(Is_Value, 1, Length(Is_Value) - Mi_LenPd)
  Else
    Result := Is_Value;
End;

function TFormTrChatGPT.Base64Encode(const Input: AnsiString): AnsiString;
var
  Count: Integer;
  Len: Integer;
begin
  Result := '';
  Count := 1;
  Len := Length(Input);
  while Count <= Len do
  begin
    Result := Result + Base64Out[(Byte(Input[Count]) and $FC) shr 2];
    If (Count + 1) <= Len then
    begin
      Result := Result + Base64Out[((Byte(Input[Count]) and $03) shl 4) + ((Byte(Input[Count + 1]) and $F0) shr 4)];
      If (Count + 2) <= Len then
      begin
        Result := Result + Base64Out[((Byte(Input[Count + 1]) and $0F) shl 2) + ((Byte(Input[Count + 2]) and $C0) shr 6)];
        Result := Result + Base64Out[(Byte(Input[Count + 2]) and $3F)];
      end
      else
      begin
        Result := Result + Base64Out[(Byte(Input[Count + 1]) and $0F) shl 2];
        Result := Result + '=';
      end
    end
    else
    begin
      Result := Result + Base64Out[(Byte(Input[Count]) and $03) shl 4];
      Result := Result + '==';
    end;
    Count := Count + 3;
  end;
end;

function TFormTrChatGPT.Base64Decode(const Input: AnsiString): AnsiString;
var
  Count: Integer;
  Len: Integer;
  DataIn0: Byte;
  DataIn1: Byte;
  DataIn2: Byte;
  DataIn3: Byte;
begin
  Result := '';
  Count := 1;
  Len := Length(Input);
  while Count <= Len do
  begin
    If Byte(Input[Count]) in [13, 10] then
      Inc(Count)
    else
    begin
      DataIn0 := Base64In[Byte(Input[Count])];
      DataIn1 := Base64In[Byte(Input[Count + 1])];
      DataIn2 := Base64In[Byte(Input[Count + 2])];
      DataIn3 := Base64In[Byte(Input[Count + 3])];

      Result := Result + AnsiChar(((DataIn0 and $3F) shl 2) + ((DataIn1 and $30) shr 4));
      If DataIn2 <> $40 then
      begin
        Result := Result + AnsiChar(((DataIn1 and $0F) shl 4) + ((DataIn2 and $3C) shr 2));
        If DataIn3 <> $40 then
          Result := Result + AnsiChar(((DataIn2 and $03) shl 6) + (DataIn3 and $3F));
      end;

      Count := Count + 4;
    end;
  end;
end;

procedure TFormTrChatGPT.Btn3_INSRTClick(Sender: TObject);
Var
  Ms_URLPr : AnsiString;
  Ms_Param : AnsiString;
  Ms_Retrn : AnsiString;
  Ms_EncPr : AnsiString;
  MS_WHORU, Ms_DBIDS, Ms_QUEST, Ms_ANSWR, Ms_GPTPS, Ms_SUBJT, Ms_CTGRY, Ms_VENDR, Ms_ACCLV, Ms_HSPCD : AnsiString;
  Mj_JRslt : TlkJSONbase;
  Ms_VariB : AnsiString;
  Ms_IMGYN, Ms_IMG01, Ms_IMG02, Ms_IMG03, Ms_IMG04, Ms_IMG05, Ms_USEYN : AnsiString;
  Mm_Mestm : TMemoryStream;
  Me_EnCdr : TIdEncoderMIME;
begin
  If Fcb_MessageBox('02', '인서트', '인서트 하시겠습니까?') <> 1 Then
    Exit;

  Ms_URLPr := FormAiChatGPT.Rs_SERVR + '/SRMInsertChr';

  MS_WHORU := 'SRMDB!@#';
  Ms_DBIDS := Trim(Edt3_DBIDS.Text);
  Ms_GPTPS := Trim(Cbx3_GPTPS.Text);
  Ms_QUEST := Fcv_JsonEscap(Trim(Mmo3_QUEST.Lines.Text));
  Ms_ANSWR := Fcv_JsonEscap(Trim(Mmo3_ANSWR.Lines.Text));
  Ms_SUBJT := Trim(Cbx3_SUBJT.Text);
  Ms_CTGRY := Trim(Edt3_CTGRY.Text);
  Ms_VENDR := Trim(Edt3_VENDR.Text);
  Ms_ACCLV := Trim(Cbx3_ACCLV.Text);
  Ms_HSPCD := Trim(Edt3_HSPCD.Text);
  Ms_USEYN := Trim(Cbx3_USEYN.Text);

  Ms_IMGYN := 'N';
  If Img3_IMG01.Picture.Graphic <> Nil Then
  Begin
    Mm_Mestm := TMemoryStream.Create;
    Me_EnCdr := TIdEncoderMIME.Create(Nil);
    Ms_IMGYN := 'Y';
    Img3_IMG01.Picture.Graphic.SaveToStream(Mm_Mestm);
    Mm_Mestm.Position := 0;
    Ms_IMG01 := Me_EnCdr.EncodeStream(Mm_Mestm);
    Mm_Mestm.Free;
  End;
  If Img3_IMG02.Picture.Graphic <> Nil Then
  Begin
    Mm_Mestm := TMemoryStream.Create;
    Me_EnCdr := TIdEncoderMIME.Create(Nil);
    Ms_IMGYN := 'Y';
    Img3_IMG02.Picture.Graphic.SaveToStream(Mm_Mestm);
    Mm_Mestm.Position := 0;
    Ms_IMG02 := Me_EnCdr.EncodeStream(Mm_Mestm);
    Mm_Mestm.Free;
  End;
  If Img3_IMG03.Picture.Graphic <> Nil Then
  Begin
    Mm_Mestm := TMemoryStream.Create;
    Me_EnCdr := TIdEncoderMIME.Create(Nil);
    Ms_IMGYN := 'Y';
    Img3_IMG03.Picture.Graphic.SaveToStream(Mm_Mestm);
    Mm_Mestm.Position := 0;
    Ms_IMG03 := Me_EnCdr.EncodeStream(Mm_Mestm);
    Mm_Mestm.Free;
  End;
  If Img3_IMG04.Picture.Graphic <> Nil Then
  Begin
    Mm_Mestm := TMemoryStream.Create;
    Me_EnCdr := TIdEncoderMIME.Create(Nil);
    Ms_IMGYN := 'Y';
    Img3_IMG04.Picture.Graphic.SaveToStream(Mm_Mestm);
    Mm_Mestm.Position := 0;
    Ms_IMG04 := Me_EnCdr.EncodeStream(Mm_Mestm);
    Mm_Mestm.Free;
  End;
  If Img3_IMG05.Picture.Graphic <> Nil Then
  Begin
    Mm_Mestm := TMemoryStream.Create;
    Me_EnCdr := TIdEncoderMIME.Create(Nil);
    Ms_IMGYN := 'Y';
    Img3_IMG05.Picture.Graphic.SaveToStream(Mm_Mestm);
    Mm_Mestm.Position := 0;
    Ms_IMG05 := Me_EnCdr.EncodeStream(Mm_Mestm);
    Mm_Mestm.Free;
  End;

  Ms_Param := '"CLs_WHORU":' + '"' + MS_WHORU + '"' + ',' +
              '"CLs_DBIDS":' + '"' + Ms_DBIDS + '"' + ',' +
              '"CLs_QUEST":' + '"' + Ms_QUEST + '"' + ',' +
              '"CLs_ANSWR":' + '"' + Ms_ANSWR + '"' + ',' +
              '"CLs_GPTPS":' + '"' + Ms_GPTPS + '"' + ',' +
              '"CLs_SUBJT":' + '"' + Ms_SUBJT + '"' + ',' +
              '"CLs_CTGRY":' + '"' + Ms_CTGRY + '"' + ',' +
              '"CLs_VENDR":' + '"' + Ms_VENDR + '"' + ',' +
              '"CLs_ACCLV":' + '"' + Ms_ACCLV + '"' + ',' +
              '"CLs_HSPCD":' + '"' + Ms_HSPCD + '"' + ',' +
              '"CLs_HSPNM":' + '"' + ''       + '"' + ',' +
              '"CLs_USRID":' + '"' + ''       + '"' + ',' +
              '"CLs_DBSDT":' + '"' + ''       + '"' + ',' +
              '"CLs_RTALL":' + '"' + ''       + '"' + ',' +
              '"CLs_IMGYN":' + '"' + Ms_IMGYN + '"' + ',' +
              '"CLs_IMG01":' + '"' + Ms_IMG01 + '"' + ',' +
              '"CLs_IMG02":' + '"' + Ms_IMG02 + '"' + ',' +
              '"CLs_IMG03":' + '"' + Ms_IMG03 + '"' + ',' +
              '"CLs_IMG04":' + '"' + Ms_IMG04 + '"' + ',' +
              '"CLs_IMG05":' + '"' + Ms_IMG05 + '"' + ',' +
              '"CLs_USEYN":' + '"' + Ms_USEYN + '"' + ',' +
              '"CLs_VECKD":' + '"' + ''       + '"' + ' ' +
              '';
  Ms_Param := '{' + Ms_Param + '}';
  Ms_EncPr := Fcv_GAes256Enc(Ms_Param);

  Ms_Param := '"Is_EncDt"' + ':' + '"' + Ms_EncPr + '"' + '';
  Ms_Param := '{' + Ms_Param + '}';

  Ms_Retrn := Fcv_HttpComm01('', Ms_URLPr, Ms_Param);

  Mj_JRslt := TlkJSON.ParseText(UTF8Encode(Ms_Retrn));
  Ms_VariB := Trim(VarToStr(Mj_JRslt.Field['Result'].Value));
  Ms_VariB := Fcv_GAes256Dec(Ms_VariB); //AES256복호화

  Fcb_MessageBox('01', 'API 통신', Ms_VariB);
end;

Function TFormTrChatGPT.Fcv_HttpComm01(Is_Gubun, Is_EhUrl, Is_Param : AnsiString) : AnsiString;
Var
  Ss_Param : TStringStream;
  Ss_Retrn : TStringStream;
Begin
  Result := '';

  IdHTTP1.Request.Clear;
  IdHTTP1.Request.CustomHeaders.Clear;
  IdHttp1.Request.BasicAuthentication := False;
  IdHTTP1.Request.CustomHeaders.FoldLines := False;

  IdHTTP1.Request.ContentType := 'application/json';

  IdHTTP1.Request.Accept := 'application/json; charset=utf-8';
  IdHTTP1.Request.AcceptCharSet := 'utf-8';

  Ss_Retrn := TStringStream.Create('');
  Ss_Param := TStringStream.Create('');
  Is_Param := UTF8Encode(Is_Param);
  Ss_Param.WriteString(Is_Param);

  Try
    IdHTTP1.Post(Is_EhUrl, Ss_Param, Ss_Retrn);
    Result := UTF8Decode(Ss_Retrn.DataString);
    Rs_RolBk := 'Y';  //성공
  Except  On E : Exception Do
    Begin
      Rs_RolBk := 'N';  //실패
      ShowMessage('실패' +#13#10+#13#10+ E.Message + #13#10 + Is_EhUrl + Is_Param + #13#10 + Result);
    End;
  End;

  //성공은 200 이고 204는 데이터 없음 나머지는 에러라고함. 예외처리 안걸리는 경우가 있을까봐 한줄 추가함.
  If (IdHTTP1.ResponseCode <> 200) And (IdHTTP1.ResponseCode <> 204) And (Rs_RolBk = 'Y') Then
  Begin
    Rs_RolBk := 'N';  //실패
    ShowMessage('실패' +#13#10+#13#10+ Is_EhUrl + Is_Param + #13#10 + Result);
  End;
  Ss_Param.Free;
  Ss_Retrn.Free;
End;

procedure TFormTrChatGPT.Grd0_DLISTClickCell(Sender: TObject; ARow,
  ACol: Integer);
Var
  Mi_ItIdx : Integer;
begin
  If ARow < 1 Then
    Exit;

  If Trim(Grd0_DLIST.Cells[ 0,ARow]) <> '' Then
  Begin
    Pcb_AllClearEd;

    Edt3_DBIDS.Text := Trim(Grd0_DLIST.Cells[ 0,ARow]);
    Mi_ItIdx := Cbx3_GPTPS.Items.IndexOf(Trim(Grd0_DLIST.Cells[ 2,ARow]));
    If Mi_ItIdx >= 0 Then
      Cbx3_GPTPS.ItemIndex := Mi_ItIdx;
    Mi_ItIdx := Cbx3_SUBJT.Items.IndexOf(Trim(Grd0_DLIST.Cells[ 3,ARow]));
    If Mi_ItIdx >= 0 Then
      Cbx3_SUBJT.ItemIndex := Mi_ItIdx;
    Edt3_CTGRY.Text := Trim(Grd0_DLIST.Cells[ 4,ARow]);
    Mmo3_QUEST.Lines.Text := Trim(Grd0_DLIST.Cells[ 5,ARow]);
    Mmo3_ANSWR.Lines.Text := Trim(Grd0_DLIST.Cells[ 6,ARow]);
    Edt3_VENDR.Text := Trim(Grd0_DLIST.Cells[ 7,ARow]);
    Mi_ItIdx := Cbx3_ACCLV.Items.IndexOf(Trim(Grd0_DLIST.Cells[ 8,ARow]));
    If Mi_ItIdx >= 0 Then
      Cbx3_ACCLV.ItemIndex := Mi_ItIdx;
    Edt3_HSPCD.Text := Trim(Grd0_DLIST.Cells[ 9,ARow]);
    Mi_ItIdx := Cbx3_USEYN.Items.IndexOf(Trim(Grd0_DLIST.Cells[18,ARow]));
    If Mi_ItIdx >= 0 Then
      Cbx3_USEYN.ItemIndex := Mi_ItIdx;

    If (Trim(Grd0_DLIST.Cells[10,ARow]) = 'Y') And (Trim(Grd0_DLIST.Cells[12,ARow]) = '') Then
      Pcb_APISearchI(Trim(Grd0_DLIST.Cells[ 0,ARow]), ARow);

    Pcb_LoadImages(Trim(Grd0_DLIST.Cells[12,ARow]), Img3_IMG01);
    Pcb_LoadImages(Trim(Grd0_DLIST.Cells[13,ARow]), Img3_IMG02);
    Pcb_LoadImages(Trim(Grd0_DLIST.Cells[14,ARow]), Img3_IMG03);
    Pcb_LoadImages(Trim(Grd0_DLIST.Cells[15,ARow]), Img3_IMG04);
    Pcb_LoadImages(Trim(Grd0_DLIST.Cells[16,ARow]), Img3_IMG05);
    If Img3_IMG01.Picture.Graphic <> Nil Then
    Begin
      Rl_ImgLs.Add(Img3_IMG01);
      Ri_ImgId := 1;
    End;
    If Img3_IMG02.Picture.Graphic <> Nil Then
    Begin
      Rl_ImgLs.Add(Img3_IMG02);
      Ri_ImgId := 2;
    End;
    If Img3_IMG03.Picture.Graphic <> Nil Then
    Begin
      Rl_ImgLs.Add(Img3_IMG03);
      Ri_ImgId := 3;
    End;
    If Img3_IMG04.Picture.Graphic <> Nil Then
    Begin
      Rl_ImgLs.Add(Img3_IMG04);
      Ri_ImgId := 4;
    End;
    If Img3_IMG05.Picture.Graphic <> Nil Then
    Begin
      Rl_ImgLs.Add(Img3_IMG05);
      Ri_ImgId := 5;
    End;
  End;
end;

procedure TFormTrChatGPT.Pcb_APISearchI(Is_DBIDS : AnsiString; Ii_RowNm: Integer);
Var
  Ms_URLPr, Ms_WHORU, Ms_Param, Ms_EncPr, Ms_Retrn : AnsiString;
  Mj_JRslt : TlkJSONbase;
  Ms_VariB : AnsiString;

  Mu_UTF8J : UTF8String;
  Mj_RData : TlkJSONbase;
  Mj_JList : TlkJSONlist;
  Mj_Objct, Mj_MetaD: TlkJSONObject;
  Mv_ChekV : Variant;
Begin
  Ms_URLPr := FormAiChatGPT.Rs_SERVR + '/SRMSelectChr';
  Ms_WHORU := 'SRMDB!@#';
  Ms_Param := '"CLs_WHORU":' + '"' + Ms_WHORU + '"' + ',' +
              '"CLs_DBIDS":' + '"' + Is_DBIDS + '"' + ',' +
              '"CLs_QUEST":' + '"' + '' + '"' + ',' +
              '"CLs_ANSWR":' + '"' + '' + '"' + ',' +
              '"CLs_GPTPS":' + '"' + '' + '"' + ',' +
              '"CLs_SUBJT":' + '"' + '' + '"' + ',' +
              '"CLs_CTGRY":' + '"' + '' + '"' + ',' +
              '"CLs_VENDR":' + '"' + '' + '"' + ',' +
              '"CLs_ACCLV":' + '"' + '' + '"' + ',' +
              '"CLs_HSPCD":' + '"' + '' + '"' + ',' +
              '"CLs_HSPNM":' + '"' + '' + '"' + ',' +
              '"CLs_USRID":' + '"' + '' + '"' + ',' +
              '"CLs_DBSDT":' + '"' + '' + '"' + ',' +
              '"CLs_RTALL":' + '"' + '' + '"' + ',' +
              '"CLs_IMGYN":' + '"' + '' + '"' + ',' +
              '"CLs_IMG01":' + '"' + '' + '"' + ',' +
              '"CLs_IMG02":' + '"' + '' + '"' + ',' +
              '"CLs_IMG03":' + '"' + '' + '"' + ',' +
              '"CLs_IMG04":' + '"' + '' + '"' + ',' +
              '"CLs_IMG05":' + '"' + '' + '"' + ',' +
              '"CLs_USEYN":' + '"' + '' + '"' + ',' +
              '"CLs_VECKD":' + '"' + '' + '"' + ' ' +
              '';
  Ms_Param := '{' + Ms_Param + '}';
  Ms_EncPr := Fcv_GAes256Enc(Ms_Param);

  Ms_Param := '"Is_EncDt"' + ':' + '"' + Ms_EncPr + '"' + '';
  Ms_Param := '{' + Ms_Param + '}';

  Ms_Retrn := Fcv_HttpComm01('', Ms_URLPr, Ms_Param);

  Mj_JRslt := TlkJSON.ParseText(UTF8Encode(Ms_Retrn));
  Ms_VariB := Trim(VarToStr(Mj_JRslt.Field['Result'].Value));
  Ms_VariB := Fcv_GAes256Dec(Ms_VariB); //AES256복호화

  If Trim(VarToStr(Mj_JRslt.Field['SqlCode'].Value)) = '1' Then
  Begin
    Mu_UTF8J := UTF8Encode(Ms_VariB);
    Mj_RData := TlkJSON.ParseText(string(Mu_UTF8J));
    Mj_JList := TlkJSONlist(Mj_RData);

    Mj_Objct := Mj_JList.Child[0] as TlkJSONObject;
    Grd0_DLIST.Cells[ 1, Ii_RowNm] :=  Mj_Objct.Field['ANSWR'].Value;

    Mv_ChekV := Mj_Objct.Field['SCORE'].Value;
    If Not VarIsNull(Mv_ChekV) Then
      Grd0_DLIST.Cells[11, Ii_RowNm] := Mv_ChekV;

    Mj_MetaD := Mj_Objct.Field['QDATA'] as TlkJSONObject;
    Try
      Grd0_DLIST.Cells[ 2, Ii_RowNm] := Mj_MetaD.Field['GPTPS'].Value;
      Grd0_DLIST.Cells[ 3, Ii_RowNm] := Mj_MetaD.Field['SUBJT'].Value;
      Grd0_DLIST.Cells[ 4, Ii_RowNm] := Mj_MetaD.Field['CTGRY'].Value;
      Grd0_DLIST.Cells[ 5, Ii_RowNm] := Mj_MetaD.Field['QUEST'].Value;
      Grd0_DLIST.Cells[ 6, Ii_RowNm] := Mj_MetaD.Field['ANSWR'].Value;
      Grd0_DLIST.Cells[ 7, Ii_RowNm] := Mj_MetaD.Field['VENDR'].Value;
      Grd0_DLIST.Cells[ 8, Ii_RowNm] := Mj_MetaD.Field['ACCLV'].Value;
      Grd0_DLIST.Cells[ 9, Ii_RowNm] := Mj_MetaD.Field['HSPCD'].Value;
      Grd0_DLIST.Cells[10, Ii_RowNm] := Mj_MetaD.Field['IMGYN'].Value;
      Grd0_DLIST.Cells[12, Ii_RowNm] := Mj_MetaD.Field['IMG01'].Value;
      Grd0_DLIST.Cells[13, Ii_RowNm] := Mj_MetaD.Field['IMG02'].Value;
      Grd0_DLIST.Cells[14, Ii_RowNm] := Mj_MetaD.Field['IMG03'].Value;
      Grd0_DLIST.Cells[15, Ii_RowNm] := Mj_MetaD.Field['IMG04'].Value;
      Grd0_DLIST.Cells[16, Ii_RowNm] := Mj_MetaD.Field['IMG05'].Value;
      Grd0_DLIST.Cells[17, Ii_RowNm] := Mj_MetaD.Field['DBSDT'].Value;
      Grd0_DLIST.Cells[18, Ii_RowNm] := Mj_MetaD.Field['USEYN'].Value;
    Except End;
  End;
End;

procedure TFormTrChatGPT.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  FormAiChatGPT.show;
end;

function TFormTrChatGPT.Fcb_MessageBox(Is_Gubun, Is_Subjt, Is_Mesag : AnsiString) : Integer;
Begin
  FormMesageBox := TFormMesageBox.Create(Application);
  FormMesageBox.Edt0_Subjt.Text := Is_Subjt;
  FormMesageBox.Mem0_Body1.Text := Is_Mesag;
  FormMesageBox.Mem0_Body1.Height := FormMesageBox.Pnl0_ExCau.Height + FormMesageBox.Pnl0_ExCau.Top - FormMesageBox.Mem0_Body1.Top - 4;
  If (Is_Gubun = '01') Or (Is_Gubun = '06') Then
  Begin
    FormMesageBox.Btn0_Rlt02.Visible := True;
    FormMesageBox.Btn0_Rlt02.Caption := '확인';
    //If Is_Gubun = '06' Then
    //  FormMesageBox.Tmr0_Count.Enabled := True;
  End Else
  If Is_Gubun = '02' Then
  Begin
    FormMesageBox.Btn0_Rlt01.Visible := True;
    FormMesageBox.Btn0_Rlt01.Caption := '예';
    FormMesageBox.Btn0_Rlt03.Visible := True;
    FormMesageBox.Btn0_Rlt03.Caption := '아니오';
  End Else
  If Is_Gubun = '03' Then
  Begin
    FormMesageBox.Btn0_Rlt01.Visible := True;
    FormMesageBox.Btn0_Rlt01.Caption := '예';
    FormMesageBox.Btn0_Rlt02.Visible := True;
    FormMesageBox.Btn0_Rlt02.Caption := '아니오';
    FormMesageBox.Btn0_Rlt03.Visible := True;
    FormMesageBox.Btn0_Rlt03.Caption := '취소';
  End Else
  If Is_Gubun = '04' Then
  Begin

    FormMesageBox.Btn0_Rlt01.Visible := True;
    FormMesageBox.Btn0_Rlt01.Caption := '예';
    FormMesageBox.Btn0_Rlt02.Visible := True;
    FormMesageBox.Btn0_Rlt02.Caption := '아니오';
    FormMesageBox.Btn0_Rlt03.Visible := True;
    FormMesageBox.Btn0_Rlt03.Caption := '취소';
    FormMesageBox.Pnl0_ExCau.Visible := True;
    FormMesageBox.Mem0_Body1.Height := FormMesageBox.Pnl0_ExCau.Top - FormMesageBox.Mem0_Body1.Top - 2;
  End;
  FormMesageBox.Pnl0_ExCau.Hint := Is_Gubun;

  FormMesageBox.ShowModal;
  Result := FormMesageBox.ModalResult;
  FreeAndNil(FormMesageBox);
End;

procedure TFormTrChatGPT.Btn0_Srch1Click(Sender: TObject);
Var
  Ms_URLPr : AnsiString;
  Ms_Param : AnsiString;
  Ms_Retrn : AnsiString;
  Ms_EncPr : AnsiString;
  Ms_WHORU, Ms_DBIDS, Ms_QUEST, Ms_ANSWR, Ms_GPTPS, Ms_SUBJT, Ms_CTGRY, Ms_VENDR, Ms_ACCLV, Ms_HSPCD : AnsiString;
  Ms_IMGYN, Ms_USEYN, Ms_VECKD : AnsiString;
  Mj_JRslt : TlkJSONbase;
  Ms_VariB : AnsiString;
  Mu_UTF8J : UTF8String;
  Mj_RData : TlkJSONbase;
  Mj_JList : TlkJSONlist;
  Mj_Objct, Mj_MetaD: TlkJSONObject;
  Mi_GcRow : Integer;
begin
  Edt3_DBIDS.Text := '';

  Ms_URLPr := FormAiChatGPT.Rs_SERVR + '/SRMSelectChr';

  Ms_WHORU := 'SRMDB!@#';
  Ms_DBIDS := Trim(Edt0_DBIDS.Text);
  Ms_QUEST := Fcv_JsonEscap(Trim(Edt0_DOCMT.Text));
  Ms_ANSWR := Fcv_JsonEscap(Trim(Edt0_ANSWR.Text));
  Ms_GPTPS := Trim(Cbx0_GPTPS.Text);
  Ms_SUBJT := Trim(Cbx0_SUBJT.Text);
  Ms_CTGRY := Trim(Edt0_CTGRY.Text);
  Ms_VENDR := Trim(Edt0_VENDR.Text);
  Ms_ACCLV := Trim(Ckx0_ACCLV.Text);
  Ms_HSPCD := Trim(Edt0_HSPCD.Text);
  Ms_IMGYN := Trim(Cbx0_IMGYN.Text);
  Ms_USEYN := Trim(Cbx0_USEYN.Text);
  Ms_VECKD := Trim(Cbx0_VECKD.Text);

  Ms_Param := '"CLs_WHORU":' + '"' + MS_WHORU + '"' + ',' +
              '"CLs_DBIDS":' + '"' + Ms_DBIDS + '"' + ',' +
              '"CLs_QUEST":' + '"' + Ms_QUEST + '"' + ',' +
              '"CLs_ANSWR":' + '"' + Ms_ANSWR + '"' + ',' +
              '"CLs_GPTPS":' + '"' + Ms_GPTPS + '"' + ',' +
              '"CLs_SUBJT":' + '"' + Ms_SUBJT + '"' + ',' +
              '"CLs_CTGRY":' + '"' + Ms_CTGRY + '"' + ',' +
              '"CLs_VENDR":' + '"' + Ms_VENDR + '"' + ',' +
              '"CLs_ACCLV":' + '"' + Ms_ACCLV + '"' + ',' +
              '"CLs_HSPCD":' + '"' + Ms_HSPCD + '"' + ',' +
              '"CLs_HSPNM":' + '"' + ''       + '"' + ',' +
              '"CLs_USRID":' + '"' + ''       + '"' + ',' +
              '"CLs_DBSDT":' + '"' + ''       + '"' + ',' +
              '"CLs_RTALL":' + '"' + 'Y'      + '"' + ',' +
              '"CLs_IMGYN":' + '"' + Ms_IMGYN + '"' + ',' +
              '"CLs_IMG01":' + '"' + ''       + '"' + ',' +
              '"CLs_IMG02":' + '"' + ''       + '"' + ',' +
              '"CLs_IMG03":' + '"' + ''       + '"' + ',' +
              '"CLs_IMG04":' + '"' + ''       + '"' + ',' +
              '"CLs_IMG05":' + '"' + ''       + '"' + ',' +
              '"CLs_USEYN":' + '"' + Ms_USEYN + '"' + ',' +
              '"CLs_VECKD":' + '"' + Ms_VECKD + '"' + ' ' +
              '';
  Ms_Param := '{' + Ms_Param + '}';
  Ms_EncPr := Fcv_GAes256Enc(Ms_Param);

  Ms_Param := '"Is_EncDt"' + ':' + '"' + Ms_EncPr + '"' + '';
  Ms_Param := '{' + Ms_Param + '}';

  Ms_Retrn := Fcv_HttpComm01('', Ms_URLPr, Ms_Param);

  Mj_JRslt := TlkJSON.ParseText(UTF8Encode(Ms_Retrn));
  Ms_VariB := Trim(VarToStr(Mj_JRslt.Field['Result'].Value));
  Ms_VariB := Fcv_GAes256Dec(Ms_VariB); //AES256복호화

  Prs0_Stat1.Min := 0;
  Prs0_Stat1.Max := 1;
  Prs0_Stat1.Position := 0;

  Grd0_DLIST.Clear;
  Grd0_DLIST.RowCount := 2;
  Grd0_DLIST.Rows[0].Text := 'ids'   + #13#10 + 'documents' + #13#10 + 'GPTPS' + #13#10 + 'SUBJT' + #13#10 + 'CTGRY' + #13#10 +
                             'QUEST' + #13#10 + 'ANSWR'     + #13#10 + 'VENDR' + #13#10 + 'ACCLV' + #13#10 + 'HSPCD' + #13#10 +
                             'IMGYN' + #13#10 + '유사도'    + #13#10 + ''      + #13#10 + ''      + #13#10 + ''      + #13#10 +
                             ''      + #13#10 + ''          + #13#10 + 'DBSDT' + #13#10 + 'USEYN' + #13#10 + '';
  If Trim(VarToStr(Mj_JRslt.Field['SqlCode'].Value)) = '1' Then
  Begin
    Mu_UTF8J := UTF8Encode(Ms_VariB);
    Mj_RData := TlkJSON.ParseText(string(Mu_UTF8J));
    Mj_JList := TlkJSONlist(Mj_RData);
    Mi_GcRow := 0;

    Prs0_Stat1.Max := Mj_JList.Count;

    While Mi_GcRow < Mj_JList.Count Do
    Begin
      //ids, document
      Mj_Objct := Mj_JList.Child[Mi_GcRow] as TlkJSONObject;
      Grd0_DLIST.Cells[ 0, Mi_GcRow+1] :=  Mj_Objct.Field['id'].Value;
      Grd0_DLIST.Cells[ 1, Mi_GcRow+1] :=  Mj_Objct.Field['ANSWR'].Value;
      Grd0_DLIST.Cells[11, Mi_GcRow+1] :=  Mj_Objct.Field['SCORE'].Value;

      //metadatas
      Mj_MetaD := Mj_Objct.Field['QDATA'] as TlkJSONObject;
      Try
        Grd0_DLIST.Cells[ 2, Mi_GcRow+1] := Mj_MetaD.Field['GPTPS'].Value;
        Grd0_DLIST.Cells[ 3, Mi_GcRow+1] := Mj_MetaD.Field['SUBJT'].Value;
        Grd0_DLIST.Cells[ 4, Mi_GcRow+1] := Mj_MetaD.Field['CTGRY'].Value;
        Grd0_DLIST.Cells[ 5, Mi_GcRow+1] := Mj_MetaD.Field['QUEST'].Value;
        Grd0_DLIST.Cells[ 6, Mi_GcRow+1] := Mj_MetaD.Field['ANSWR'].Value;
        Grd0_DLIST.Cells[ 7, Mi_GcRow+1] := Mj_MetaD.Field['VENDR'].Value;
        Grd0_DLIST.Cells[ 8, Mi_GcRow+1] := Mj_MetaD.Field['ACCLV'].Value;
        Grd0_DLIST.Cells[ 9, Mi_GcRow+1] := Mj_MetaD.Field['HSPCD'].Value;
        Grd0_DLIST.Cells[10, Mi_GcRow+1] := Mj_MetaD.Field['IMGYN'].Value;
        Grd0_DLIST.Cells[12, Mi_GcRow+1] := Mj_MetaD.Field['IMG01'].Value;
        Grd0_DLIST.Cells[13, Mi_GcRow+1] := Mj_MetaD.Field['IMG02'].Value;
        Grd0_DLIST.Cells[14, Mi_GcRow+1] := Mj_MetaD.Field['IMG03'].Value;
        Grd0_DLIST.Cells[15, Mi_GcRow+1] := Mj_MetaD.Field['IMG04'].Value;
        Grd0_DLIST.Cells[16, Mi_GcRow+1] := Mj_MetaD.Field['IMG05'].Value;
        Grd0_DLIST.Cells[17, Mi_GcRow+1] := Mj_MetaD.Field['DBSDT'].Value;
        Grd0_DLIST.Cells[18, Mi_GcRow+1] := Mj_MetaD.Field['USEYN'].Value;
      Except End;

      Inc(Mi_GcRow);
      Grd0_DLIST.RowCount := Mi_GcRow + 1;
      Prs0_Stat1.Position := Mi_GcRow;
      Application.ProcessMessages;
    End;

    Grd0_DLIST.Cells[ 6, 0] := Trim(Grd0_DLIST.Cells[ 6, 0]) + '  총 문서수: ' + IntToStr(Mi_GcRow);
  End;

  If Trim(Grd0_DLIST.Cells[ 0, 1]) <> '' Then
    Grd0_DLISTClickCell(Grd0_DLIST, 1, 0);
end;

procedure TFormTrChatGPT.Btn3_DeletClick(Sender: TObject);
Var
  Ms_URLPr : AnsiString;
  Ms_Param : AnsiString;

  Ms_Retrn : AnsiString;
  Ms_EncPr : AnsiString;
  MS_WHORU, Ms_DBIDS, Ms_QUEST, Ms_ANSWR, Ms_GPTPS, Ms_SUBJT, Ms_CTGRY, Ms_VENDR, Ms_ACCLV, Ms_HSPCD : AnsiString;
  Mj_JRslt : TlkJSONbase;
  Ms_VariB : AnsiString;
begin
  If Fcb_MessageBox('02', '삭제', '정말로 삭제하시겠습니까?') <> 1 Then
    Exit;

  Ms_URLPr := FormAiChatGPT.Rs_SERVR + '/SRMDeleteChr';

  MS_WHORU := 'SRMDB!@#';
  Ms_DBIDS := Trim(Edt3_DBIDS.Text);
  Ms_QUEST := Fcv_JsonEscap(Trim(Mmo3_QUEST.Lines.Text));
  Ms_ANSWR := Fcv_JsonEscap(Trim(Mmo3_ANSWR.Lines.Text));
  Ms_GPTPS := Trim(Cbx3_GPTPS.Text);
  Ms_SUBJT := Trim(Cbx3_SUBJT.Text);
  Ms_CTGRY := Trim(Edt3_CTGRY.Text);
  Ms_VENDR := Trim(Edt3_VENDR.Text);
  Ms_ACCLV := Trim(Cbx3_ACCLV.Text);
  Ms_HSPCD := Trim(Edt3_HSPCD.Text);

  Ms_Param := '"CLs_WHORU":' + '"' + MS_WHORU + '"' + ',' +
              '"CLs_DBIDS":' + '"' + Ms_DBIDS + '"' + ',' +
              '"CLs_QUEST":' + '"' + Ms_QUEST + '"' + ',' +
              '"CLs_ANSWR":' + '"' + Ms_ANSWR + '"' + ',' +
              '"CLs_GPTPS":' + '"' + Ms_GPTPS + '"' + ',' +
              '"CLs_SUBJT":' + '"' + Ms_SUBJT + '"' + ',' +
              '"CLs_CTGRY":' + '"' + Ms_CTGRY + '"' + ',' +
              '"CLs_VENDR":' + '"' + Ms_VENDR + '"' + ',' +
              '"CLs_ACCLV":' + '"' + Ms_ACCLV + '"' + ',' +
              '"CLs_HSPCD":' + '"' + Ms_HSPCD + '"' + ',' +
              '"CLs_HSPNM":' + '"' + ''       + '"' + ',' +
              '"CLs_USRID":' + '"' + ''       + '"' + ',' +
              '"CLs_DBSDT":' + '"' + ''       + '"' + ',' +
              '"CLs_RTALL":' + '"' + ''       + '"' + ',' +
              '"CLs_IMGYN":' + '"' + ''       + '"' + ',' +
              '"CLs_IMG01":' + '"' + ''       + '"' + ',' +
              '"CLs_IMG02":' + '"' + ''       + '"' + ',' +
              '"CLs_IMG03":' + '"' + ''       + '"' + ',' +
              '"CLs_IMG04":' + '"' + ''       + '"' + ',' +
              '"CLs_IMG05":' + '"' + ''       + '"' + ',' +
              '"CLs_USEYN":' + '"' + ''       + '"' + ',' +
              '"CLs_VECKD":' + '"' + ''       + '"' + ' ' +
              '';
  Ms_Param := '{' + Ms_Param + '}';
  Ms_EncPr := Fcv_GAes256Enc(Ms_Param);

  Ms_Param := '"Is_EncDt"' + ':' + '"' + Ms_EncPr + '"' + '';
  Ms_Param := '{' + Ms_Param + '}';

  Ms_Retrn := Fcv_HttpComm01('', Ms_URLPr, Ms_Param);

  Mj_JRslt := TlkJSON.ParseText(UTF8Encode(Ms_Retrn));
  Ms_VariB := Trim(VarToStr(Mj_JRslt.Field['Result'].Value));
  Ms_VariB := Fcv_GAes256Dec(Ms_VariB); //AES256복호화

  Fcb_MessageBox('01', 'API 통신', Ms_VariB);
end;

procedure TFormTrChatGPT.Grd0_DLISTKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
Var
  Mt_StrLs : TStringList;
  Mi_Heigt, Mi_Weigt : Integer;
  Ms_CellD : AnsiString;
begin
  If (Key = Ord('C')) and (ssCtrl in Shift) then
  Begin
    Mt_StrLs := TStringList.Create;
  try
    For Mi_Heigt := Grd0_DLIST.Selection.Top to Grd0_DLIST.Selection.Bottom do
    Begin
      Ms_CellD:= '';
      For Mi_Weigt := Grd0_DLIST.Selection.Left to Grd0_DLIST.Selection.Right do
      Begin
        Ms_CellD := Ms_CellD + Grd0_DLIST.Cells[Mi_Weigt, Mi_Heigt];
        If Mi_Weigt < Grd0_DLIST.Selection.Right then
          Ms_CellD := Ms_CellD + #9; // 탭으로 구분
      End;
      Mt_StrLs.Add(Ms_CellD);
    End;
    Clipboard.AsText := Mt_StrLs.Text;
  Finally
    Mt_StrLs.Free;
  End;
    Key := 0; // 기본 동작 방지
  End;
end;

procedure TFormTrChatGPT.Btn3_ClearClick(Sender: TObject);
begin
  Pcb_AllClearEd;

  Mmo3_QUEST.SetFocus;
end;

procedure TFormTrChatGPT.Pcb_AllClearEd;
Begin
  Edt3_DBIDS.Text := '';
  Mmo3_QUEST.Lines.Text := '';
  Mmo3_ANSWR.Lines.Text := '';
  //Cbx3_GPTPS.ItemIndex := 1;
  Cbx3_SUBJT.ItemIndex := 1;
  //Edt3_CTGRY.Text := '';
  Edt3_VENDR.Text := '';
  Cbx3_ACCLV.ItemIndex := 0;
  Edt3_HSPCD.Text := '';

  Ri_ImgId := 0;
  Img3_IMG01.Picture.Graphic := Nil;
  Img3_IMG02.Picture.Graphic := Nil;
  Img3_IMG03.Picture.Graphic := Nil;
  Img3_IMG04.Picture.Graphic := Nil;
  Img3_IMG05.Picture.Graphic := Nil;

  Rl_ImgLs.Clear;
End;

procedure TFormTrChatGPT.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  If Key = Vk_F2 Then
  Begin
    If FindComponent('Btn0_Srch1') <> Nil Then
    Begin
      TAdvGlowButton(FindComponent('Btn0_Srch1')).Click;
    End;
  End Else
  If Key = Vk_F3 Then
  Begin
    Btn3_Clear.Click;
  End Else
  If Key = VK_INSERT Then
  Begin
    If Trim(Edt3_DBIDS.Text) = '' Then
    Begin
      Btn3_INSRT.Click;
    End;
  End;
end;

procedure TFormTrChatGPT.Btn3_UPDATClick(Sender: TObject);
Var
  Ms_URLPr : AnsiString;
  Ms_Param : AnsiString;

  Ms_Retrn : AnsiString;
  Ms_EncPr : AnsiString;
  MS_WHORU, Ms_DBIDS, Ms_QUEST, Ms_ANSWR, Ms_GPTPS, Ms_SUBJT, Ms_CTGRY, Ms_VENDR, Ms_ACCLV, Ms_HSPCD : AnsiString;
  Mj_JRslt : TlkJSONbase;
  Ms_VariB : AnsiString;
  Ms_IMGYN, Ms_IMG01, Ms_IMG02, Ms_IMG03, Ms_IMG04, Ms_IMG05, Ms_USEYN : AnsiString;
  Mm_Mestm : TMemoryStream;
  Me_EnCdr : TIdEncoderMIME;
begin
  If Fcb_MessageBox('02', '업데이트', '업데이트 하시겠습니까?') <> 1 Then
    Exit;

  Ms_URLPr := FormAiChatGPT.Rs_SERVR + '/SRMUpdateChr';

  MS_WHORU := 'SRMDB!@#';
  Ms_DBIDS := Trim(Edt3_DBIDS.Text);
  Ms_GPTPS := Trim(Cbx3_GPTPS.Text);
  Ms_QUEST := Fcv_JsonEscap(Trim(Mmo3_QUEST.Lines.Text));
  Ms_ANSWR := Fcv_JsonEscap(Trim(Mmo3_ANSWR.Lines.Text));
  Ms_SUBJT := Trim(Cbx3_SUBJT.Text);
  Ms_CTGRY := Trim(Edt3_CTGRY.Text);
  Ms_VENDR := Trim(Edt3_VENDR.Text);
  Ms_ACCLV := Trim(Cbx3_ACCLV.Text);
  Ms_HSPCD := Trim(Edt3_HSPCD.Text);
  Ms_USEYN := Trim(Cbx3_USEYN.Text);

  Ms_IMGYN := 'N';
  If Img3_IMG01.Picture.Graphic <> Nil Then
  Begin
    Mm_Mestm := TMemoryStream.Create;
    Me_EnCdr := TIdEncoderMIME.Create(Nil);
    Ms_IMGYN := 'Y';
    Img3_IMG01.Picture.Graphic.SaveToStream(Mm_Mestm);
    Mm_Mestm.Position := 0;
    Ms_IMG01 := Me_EnCdr.EncodeStream(Mm_Mestm);
    Mm_Mestm.Free;
  End;
  If Img3_IMG02.Picture.Graphic <> Nil Then
  Begin
    Mm_Mestm := TMemoryStream.Create;
    Me_EnCdr := TIdEncoderMIME.Create(Nil);
    Ms_IMGYN := 'Y';
    Img3_IMG02.Picture.Graphic.SaveToStream(Mm_Mestm);
    Mm_Mestm.Position := 0;
    Ms_IMG02 := Me_EnCdr.EncodeStream(Mm_Mestm);
    Mm_Mestm.Free;
  End;
  If Img3_IMG03.Picture.Graphic <> Nil Then
  Begin
    Mm_Mestm := TMemoryStream.Create;
    Me_EnCdr := TIdEncoderMIME.Create(Nil);
    Ms_IMGYN := 'Y';
    Img3_IMG03.Picture.Graphic.SaveToStream(Mm_Mestm);
    Mm_Mestm.Position := 0;
    Ms_IMG03 := Me_EnCdr.EncodeStream(Mm_Mestm);
    Mm_Mestm.Free;
  End;
  If Img3_IMG04.Picture.Graphic <> Nil Then
  Begin
    Mm_Mestm := TMemoryStream.Create;
    Me_EnCdr := TIdEncoderMIME.Create(Nil);
    Ms_IMGYN := 'Y';
    Img3_IMG04.Picture.Graphic.SaveToStream(Mm_Mestm);
    Mm_Mestm.Position := 0;
    Ms_IMG04 := Me_EnCdr.EncodeStream(Mm_Mestm);
    Mm_Mestm.Free;
  End;
  If Img3_IMG05.Picture.Graphic <> Nil Then
  Begin
    Mm_Mestm := TMemoryStream.Create;
    Me_EnCdr := TIdEncoderMIME.Create(Nil);
    Ms_IMGYN := 'Y';
    Img3_IMG05.Picture.Graphic.SaveToStream(Mm_Mestm);
    Mm_Mestm.Position := 0;
    Ms_IMG05 := Me_EnCdr.EncodeStream(Mm_Mestm);
    Mm_Mestm.Free;
  End;

  Ms_Param := '"CLs_WHORU":' + '"' + MS_WHORU + '"' + ',' +
              '"CLs_DBIDS":' + '"' + Ms_DBIDS + '"' + ',' +
              '"CLs_QUEST":' + '"' + Ms_QUEST + '"' + ',' +
              '"CLs_ANSWR":' + '"' + Ms_ANSWR + '"' + ',' +
              '"CLs_GPTPS":' + '"' + Ms_GPTPS + '"' + ',' +
              '"CLs_SUBJT":' + '"' + Ms_SUBJT + '"' + ',' +
              '"CLs_CTGRY":' + '"' + Ms_CTGRY + '"' + ',' +
              '"CLs_VENDR":' + '"' + Ms_VENDR + '"' + ',' +
              '"CLs_ACCLV":' + '"' + Ms_ACCLV + '"' + ',' +
              '"CLs_HSPCD":' + '"' + Ms_HSPCD + '"' + ',' +
              '"CLs_HSPNM":' + '"' + ''       + '"' + ',' +
              '"CLs_USRID":' + '"' + ''       + '"' + ',' +
              '"CLs_DBSDT":' + '"' + ''       + '"' + ',' +
              '"CLs_RTALL":' + '"' + ''       + '"' + ',' +
              '"CLs_IMGYN":' + '"' + Ms_IMGYN + '"' + ',' +
              '"CLs_IMG01":' + '"' + Ms_IMG01 + '"' + ',' +
              '"CLs_IMG02":' + '"' + Ms_IMG02 + '"' + ',' +
              '"CLs_IMG03":' + '"' + Ms_IMG03 + '"' + ',' +
              '"CLs_IMG04":' + '"' + Ms_IMG04 + '"' + ',' +
              '"CLs_IMG05":' + '"' + Ms_IMG05 + '"' + ',' +
              '"CLs_USEYN":' + '"' + Ms_USEYN + '"' + ',' +
              '"CLs_VECKD":' + '"' + ''       + '"' + ' ' +
              '';
  Ms_Param := '{' + Ms_Param + '}';
  Ms_EncPr := Fcv_GAes256Enc(Ms_Param);

  Ms_Param := '"Is_EncDt"' + ':' + '"' + Ms_EncPr + '"' + '';
  Ms_Param := '{' + Ms_Param + '}';

  Ms_Retrn := Fcv_HttpComm01('', Ms_URLPr, Ms_Param);

  Mj_JRslt := TlkJSON.ParseText(UTF8Encode(Ms_Retrn));
  Ms_VariB := Trim(VarToStr(Mj_JRslt.Field['Result'].Value));
  Ms_VariB := Fcv_GAes256Dec(Ms_VariB); //AES256복호화

  Pcb_APISearchI(Trim(Edt3_DBIDS.Text), Grd0_DLIST.Cols[0].IndexOf(Trim(Edt3_DBIDS.Text)));


  Fcb_MessageBox('01', 'API 통신', Ms_VariB);
end;

procedure TFormTrChatGPT.Edt0_DOCMTKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  If Key = Vk_Return Then
  Begin
    Btn0_Srch1.Click;
  End Else
  If (ssCtrl in Shift) And (Key = Ord('A')) Then
  Begin
    (Sender as TMemo).SelectAll;
    Key := 0; // 기본 처리 막기
  End;;
end;

procedure TFormTrChatGPT.Btn3_IMG01Click(Sender: TObject);
Var
  Mb_Check : Boolean;
  Mi_IntCk : Integer;
begin
  If Not ODig_FILES.Execute Then
    Exit;

  Mb_Check := False;
  If TryStrToInt(Copy(TButton(Sender).Name,10, 1), Mi_IntCk) Then
  Begin
    Mi_IntCk := Mi_IntCk - 1;
    Mb_Check := True;
  End;

  If (Mb_Check) And (Rl_ImgAr[Mi_IntCk].Picture.Graphic <> NIl) Then
  Begin
    Rl_ImgAr[Mi_IntCk].Picture.LoadFromFile(ODig_FILES.FileName);
    Rl_ImgLs[Mi_IntCk] := Rl_ImgAr[Mi_IntCk];
  End Else
  Begin
    If Ri_ImgId >= 5 Then
      Exit;
    Rl_ImgAr[Ri_ImgId].Picture.LoadFromFile(ODig_FILES.FileName);

    // 리스트에 새 이미지 등록
    If Ri_ImgId >= Rl_ImgLs.Count Then
      Rl_ImgLs.Add(Rl_ImgAr[Ri_ImgId])
    Else
      Rl_ImgLs[Ri_ImgId] := Rl_ImgAr[Ri_ImgId];
    
    Inc(Ri_ImgId);  // 다음 인덱스로 이동
  End;
end;

procedure TFormTrChatGPT.Img3_IMG01Click(Sender: TObject);
Var
  Mi_CrIdx : Integer;
begin
  If TImage(Sender).Picture.Graphic = Nil Then
    Exit;

  Mi_CrIdx := Rl_ImgLs.IndexOf(Sender);
  FormImgsViewr := TFormImgsViewr.Create(Self);
  FormImgsViewr.Pcb_ImgListIdx(Rl_ImgLs, Mi_CrIdx);
  FormImgsViewr.Show;
end;

procedure TFormTrChatGPT.Pcb_LoadImages(Is_EnStr : AnsiString; Ig_TImage : TImage);
Var
  Mj_JPEGI : TJPEGImage;
  Mm_Mestm : TMemoryStream;
  Ss_StrSm : TStringStream;
Begin
  If Trim(Is_EnStr) = '' Then
    Exit;

  If FindComponent(TImage(Ig_TImage).Name) <> Nil Then
  Begin
    Mj_JPEGI := TJPEGImage.Create;
    Mm_Mestm := TMemoryStream.Create;
    Ss_StrSm := TStringStream.Create(Is_EnStr);
    Try
      DecodeStream(Ss_StrSm, Mm_Mestm);
      Mm_Mestm.Position := 0;
      Mj_JPEGI.LoadFromStream(Mm_Mestm);
      TImage(Ig_TImage).Picture.Assign(Mj_JPEGI);
    Finally
      Mj_JPEGI.Free;
      Mm_Mestm.Free;
      Ss_StrSm.Free;
    End;
  End;
End;

procedure TFormTrChatGPT.NImgDeleteClick(Sender: TObject);
Var
  Mi_LstId : Integer;
begin
  If Rl_ImgLs.Count = 0 Then
    Exit;

  Mi_LstId := Rl_ImgLs.Count - 1;

  // 이미지 초기화 (해당 TImage 지우기)
  Rl_ImgAr[Mi_LstId].Picture := nil;

  // 리스트에서 제거
  Rl_ImgLs.Delete(Mi_LstId);

  // 인덱스 감소
  Dec(Ri_ImgId);
end;

procedure TFormTrChatGPT.NImgDelAllClick(Sender: TObject);
Var
  Mi_Index : Integer;
begin
  If Fcb_MessageBox('02', '삭제', '정말로 전체 삭제하시겠습니까?') <> 1 Then
    Exit;

  For Mi_Index := 0 To 4 Do
    Rl_ImgAr[Mi_Index].Picture := Nil;

  // 리스트 초기화
  Rl_ImgLs.Clear;
  Ri_ImgId := 0;
end;

procedure TFormTrChatGPT.NImgSaveClick(Sender: TObject);
var
  Mm_CrImg: TImage;
begin
  Mm_CrImg := TImage(Apm3_IMGPM.PopupComponent);

  If Mm_CrImg.Picture.Graphic = Nil then
    Exit;

  // 저장 다이얼로그 열기
  If ODig_FILES.Execute Then
  Begin
    If Pos('.JPG', UpperCase(ODig_FILES.FileName)) > 0 Then
      Mm_CrImg.Picture.SaveToFile(ODig_FILES.FileName)
    Else
      Mm_CrImg.Picture.SaveToFile(ODig_FILES.FileName + '.JPG');
  End;
end;

procedure TFormTrChatGPT.Mmo3_ANSWRKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  If (ssCtrl in Shift) And (Key = Ord('A')) Then
  Begin
    (Sender as TMemo).SelectAll;
    Key := 0; // 기본 처리 막기
  End;
end;

procedure TFormTrChatGPT.Mmo3_QUESTKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  If (ssCtrl in Shift) And (Key = Ord('A')) Then
  Begin
    (Sender as TMemo).SelectAll;
    Key := 0; // 기본 처리 막기
  End;
end;

procedure TFormTrChatGPT.Grd0_DLISTClick(Sender: TObject);
begin
  Grd0_DLISTClickCell(Grd0_DLIST, Grd0_DLIST.Row, Grd0_DLIST.Col);
end;

end.
