unit Form_AiChatGPT;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, AdvGlowButton, StdCtrls, AdvSmoothPanel, DB, ADODB, IniFiles,
  StrUtils, DCPcrypt2, DCPblockciphers, DCPrijndael, uLkJSON,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  ExtCtrls, JPEG, EncdDecd, Math, AppEvnts;

type
  TFormAiChatGPT = class(TForm)
    Pnl0_Samp1: TAdvSmoothPanel;
    Btn3_SUBMT: TAdvGlowButton;
    Cipher: TDCP_rijndael;
    IdHttp1: TIdHTTP;
    Btn0_Atpn1: TAdvGlowButton;
    Label1: TLabel;
    Scr3_MainB: TScrollBox;
    Qlb3_WELCM: TLabel;
    Img3_IMG01: TImage;
    Mmo3_INPUT: TMemo;
    AdvSmoothPanel1: TAdvSmoothPanel;
    ApplicationEvents1: TApplicationEvents;
    procedure FormShow(Sender: TObject);
    procedure Btn3_SUBMTClick(Sender: TObject);
    procedure Btn0_Atpn1Click(Sender: TObject);
    procedure Img3_IMG01Click(Sender: TObject);
    procedure Mmo3_INPUTEnter(Sender: TObject);
    procedure Mmo3_INPUTKeyPress(Sender: TObject; var Key: Char);
    procedure ApplicationEvents1Message(var Msg: tagMSG;
      var Handled: Boolean);
    procedure Mmo3_INPUTKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    Rl_ImgLs : TList;
    Rs_RoadT : TStringList;

    procedure Pcb_UserMsgAdd(Is_Messa : AnsiString);
    procedure Pcb_ResizeMemo(Im_AMemo : TMemo);
    procedure Pcb_SevrMsgAdd(Is_Messa, Is_IMGYN : AnsiString; Ii_ImgCt : Integer; Ms_ImgVA : Array Of AnsiString);
    procedure Pcb_LoadImages(Is_EnStr : AnsiString; Ig_TImage : TImage);

    function PointInRect(const Pt: TPoint; const R: TRect): Boolean;
    { Private declarations }
  public
    Rs_KEYST, Rs_IVSTR : AnsiString;
    Rs_RolBk : AnsiString;
    Rs_SERVR : AnsiString;
    
    function Fcv_HttpComm01(Is_Gubun, Is_EhUrl, Is_Param : AnsiString) : AnsiString;
    function Fcv_JsonEscap(Is_Value: AnsiString) : AnsiString;
    function Fcv_GAes256Dec(Is_Value: AnsiString): AnsiString;
    function Fcv_GAes256Enc(Is_Value: AnsiString): AnsiString;
    function Fcv_GetPdPKCS7(Is_value: AnsiString): AnsiString;
    function Fcv_GetPadZero(const Is_Value: AnsiString; Ii_Sizes: integer): AnsiString;
    function Fcv_RemovePadd(Is_Value: AnsiString): AnsiString;  //패딩 제거 함수
    function Base64Encode(const Input: AnsiString): AnsiString;
    function Base64Decode(const Input: AnsiString): AnsiString;

    Function Fcb_CpySEValue(Is_Gubun, Is_RData, Is_StGbn, Is_EdGbn : AnsiString) : AnsiString; //시작및끝구분으로 복사
    { Public declarations }
  end;

var
  FormAiChatGPT: TFormAiChatGPT;

implementation

uses Form_TrChatGPT, Form_ImgsViewr;

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

  PLACEHOLDER = '질문 입력';

{$R *.dfm}

procedure TFormAiChatGPT.FormShow(Sender: TObject);
begin
  Rs_KEYST := 'srmXqcz35qqoSw1zUYbJFuRg9qa==srm';
  Rs_IVSTR := 'SRIV1p2k3p4c5l6c';

  //Rs_SERVR := 'http://118.32.152.111:8000' ;
  Rs_SERVR := 'http://127.0.0.1:8000';
  //Rs_SERVR := 'http://121.165.242.220:8000';

  //Mmm3_CHTLG.Lines.Text := '새롬이한테 질문해보세요!';
  Mmo3_INPUT.Lines.Text := PLACEHOLDER;
  Mmo3_INPUT.Font.Color := clGray;     // 회색으로 표시

  Scr3_MainB.VertScrollBar.Increment := 32;

  Rl_ImgLs := TList.Create;

  Rs_RoadT := TStringList.Create;
  Rs_RoadT.Add('잠시만요, 문서를 살펴보고 있어요!');
  Rs_RoadT.Add('적절한 답변을 위해 자료를 모으고 있어요.');
  Rs_RoadT.Add('데이터를 연결 중이에요, 곧 알려드릴게요!');
  Rs_RoadT.Add('잠시만요… AI 두뇌 풀가동 중입니다');
  Rs_RoadT.Add('최상의 답변을 만들기 위해 고민 중이에요!');

  //With ModuDbsEngine.Aqy2_Qury4 Do
  //Begin
  //  Close;
  //  SQL.Text := ''
  //  Open;
  //End;
end;

Function TFormAiChatGPT.Fcb_CpySEValue(Is_Gubun, Is_RData, Is_StGbn, Is_EdGbn : AnsiString) : AnsiString;
Begin
  If Is_Gubun = '2' Then  //뒤에서부터 가져오기
    Is_RData := ReverseString(Is_RData);

  If Is_StGbn <> '' Then
  Begin
    If Pos(Is_StGbn, Is_RData) > 0 Then
      Is_RData := Copy(Is_RData, Pos(Is_StGbn, Is_RData) + Length(Is_StGbn) ,Length(Is_RData))
    Else
      Is_RData := '';
  End;
  If Is_EdGbn <> '' Then
    Is_RData := Copy(Is_RData, 1, Pos(Is_EdGbn, Is_RData)-1);

  If Is_Gubun = '2' Then
    Is_RData := ReverseString(Is_RData);

  Result := Is_RData;
End;

function TFormAiChatGPT.Fcv_GAes256Enc(Is_Value : AnsiString) : AnsiString;
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

function TFormAiChatGPT.Fcv_GAes256Dec(Is_Value : AnsiString) : AnsiString;
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

function TFormAiChatGPT.Fcv_GetPadZero(const Is_Value : AnsiString; Ii_Sizes : Integer) : AnsiString;
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

function TFormAiChatGPT.Fcv_GetPdPKCS7(Is_value : AnsiString) : AnsiString;
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

function TFormAiChatGPT.Fcv_RemovePadd(Is_Value: AnsiString): AnsiString;
var
  Mi_LenPd : Integer;
Begin
  Mi_LenPd := Ord(Is_Value[Length(Is_Value)]); // 패딩 길이는 마지막 바이트의 값
  If (Mi_LenPd > 0) And (Mi_LenPd <= Length(Is_Value)) Then
    Result := Copy(Is_Value, 1, Length(Is_Value) - Mi_LenPd)
  Else
    Result := Is_Value;
End;

function TFormAiChatGPT.Base64Encode(const Input: AnsiString): AnsiString;
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

function TFormAiChatGPT.Base64Decode(const Input: AnsiString): AnsiString;
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

procedure TFormAiChatGPT.Btn3_SUBMTClick(Sender: TObject);
Var
  Ms_URLPr : AnsiString;
  Ms_Param : AnsiString;
  Ms_Retrn : AnsiString;
  Ms_EncPr : AnsiString;
  MS_WHORU, Ms_DBIDS, Ms_QUEST, Ms_ANSWR, Ms_GPTPS, Ms_SUBJT, Ms_CTGRY, Ms_VENDR, Ms_ACCLV, Ms_HSPCD : AnsiString;
  Ms_USEYN : AnsiString;
  Mj_JRslt : TlkJSONbase;
  Ms_VariB, Ms_SqlCd : AnsiString;
  Ms_IMGYN : AnsiString;
  Mi_FullA, Mi_FillA, Mi_FindC : Integer;
  Ms_ImgVA : Array[0..4] Of AnsiString;
begin
  If Trim(Mmo3_INPUT.Lines.Text) = '' Then
    Exit;

  If Qlb3_WELCM.Visible = True Then
    Qlb3_WELCM.Visible := False;

  //유저 메세지 등록
  Pcb_UserMsgAdd(Trim(Mmo3_INPUT.Lines.Text));
  //Pcb_SevrMsgAdd(Trim(Mmo3_INPUT.Lines.Text), '', 0, Ms_ImgVA);
  //Exit;
  Application.ProcessMessages;
  Ms_URLPr := Rs_SERVR + '/ask';

  MS_WHORU := 'SRMSOFT';
  Ms_DBIDS := '';
  Ms_QUEST := Fcv_JsonEscap(Trim(Mmo3_INPUT.Lines.Text));
  Ms_ANSWR := '';
  Ms_GPTPS := '';
  Ms_SUBJT := '';
  Ms_CTGRY := '';
  Ms_VENDR := '';
  Ms_ACCLV := 'ADMIN';
  Ms_HSPCD := '';
  Ms_USEYN := 'Y';

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
              '"CLs_USEYN":' + '"' + Ms_USEYN + '"' + ',' +
              '"CLs_VECKD":' + '"' + ''       + '"' + ' ' +
              '';
  Ms_Param := '{' + Ms_Param + '}';
  Ms_EncPr := Fcv_GAes256Enc(Ms_Param);

  Ms_Param := '"Is_EncDt"' + ':' + '"' + Ms_EncPr + '"' + '';
  Ms_Param := '{' + Ms_Param + '}';

  //. 질문 공뱍처리
  Mmo3_INPUT.Lines.Text := '';

  //----AI가 생각하고 답변 하는 효과-----
  Mi_FullA := Random(Rs_RoadT.Count);
  Pcb_SevrMsgAdd(Rs_RoadT[Mi_FullA], 'N', 0, Ms_ImgVA);
  Application.ProcessMessages;
  //----종료-----------------------------

  //. API통신
  Ms_Retrn := Fcv_HttpComm01('', Ms_URLPr, Ms_Param);

  If (Ms_Retrn = '') Or (Ms_Retrn = Null) Or (UpperCase(Ms_Retrn) = 'NULL') Then
    Exit;

  If Rs_RolBk <> 'N' Then
  Begin
    Mj_JRslt := TlkJSON.ParseText(UTF8Encode(Ms_Retrn));

    Ms_SqlCd := Trim(VarToStr(Mj_JRslt.Field['SqlCode'].Value));
    
    Ms_VariB := Trim(VarToStr(Mj_JRslt.Field['Result'].Value));
    Ms_VariB := Trim(Fcv_GAes256Dec(Ms_VariB)); //AES256복호화
    If Ms_SqlCd = '1' Then
    Begin
      Ms_IMGYN := Trim(VarToStr(Mj_JRslt.Field['IMGYN'].Value));
      Ms_IMGYN := Trim(Fcv_GAes256Dec(Ms_IMGYN)); //AES256복호화
    End;
    
    Mi_FillA := 0;
    If Ms_IMGYN = 'Y' Then
    Begin
      Ms_ImgVA[0] := Trim(VarToStr(Mj_JRslt.Field['IMG01'].Value));
      Ms_ImgVA[0] := Trim(Fcv_GAes256Dec(Ms_ImgVA[0]));
      Ms_ImgVA[1] := Trim(VarToStr(Mj_JRslt.Field['IMG02'].Value));
      Ms_ImgVA[1] := Trim(Fcv_GAes256Dec(Ms_ImgVA[1]));
      Ms_ImgVA[2] := Trim(VarToStr(Mj_JRslt.Field['IMG03'].Value));
      Ms_ImgVA[2] := Trim(Fcv_GAes256Dec(Ms_ImgVA[2]));
      Ms_ImgVA[3] := Trim(VarToStr(Mj_JRslt.Field['IMG04'].Value));
      Ms_ImgVA[3] := Trim(Fcv_GAes256Dec(Ms_ImgVA[3]));
      Ms_ImgVA[4] := Trim(VarToStr(Mj_JRslt.Field['IMG05'].Value));
      Ms_ImgVA[4] := Trim(Fcv_GAes256Dec(Ms_ImgVA[4]));
    
      // 빈 값이 아닌 것만 앞으로 땡기기
      For Mi_FullA := 0 To 4 DO
      Begin
        If Ms_ImgVA[Mi_FullA] <> '' Then
        Begin
          Ms_ImgVA[Mi_FillA] := Ms_ImgVA[Mi_FullA];
          Inc(Mi_FillA);
        End;
      End;
      // 남은 뒤쪽 슬롯은 빈 문자열로 초기화
      For Mi_FullA := Mi_FillA To 4 Do
        Ms_ImgVA[Mi_FullA] := '';
    End;
  End;

  // AI가 생각하고 답변 하는 효과 삭제
  For Mi_FindC := Scr3_MainB.ControlCount - 1 Downto 0 Do
  Begin
    If Scr3_MainB.Controls[Mi_FindC] Is TAdvSmoothPanel Then
    Begin
      TAdvSmoothPanel(Scr3_MainB.Controls[Mi_FindC]).Free;
      Break;
    End;
  End;

  // 서버 메세지 등록
  If Rs_RolBk <> 'N' Then
    Pcb_SevrMsgAdd(Ms_VariB, Ms_IMGYN, Mi_FillA, Ms_ImgVA)
  Else
    Pcb_SevrMsgAdd(Ms_Retrn, '', 0, Ms_ImgVA);
end;

Function TFormAiChatGPT.Fcv_JsonEscap(Is_Value : AnsiString) : AnsiString;
Var
  Ms_Reslt : AnsiString;
Begin
  Result := '';

  Ms_Reslt := Trim(Is_Value);
  Ms_Reslt := StringReplace(Ms_Reslt, '\n', sLineBreak, [rfReplaceAll, rfIgnoreCase]);
  Ms_Reslt := StringReplace(Ms_Reslt, '\', '\\', [rfReplaceAll]);
  Ms_Reslt := StringReplace(Ms_Reslt, '"', '\"', [rfReplaceAll]);
  // 줄바꿈도 JSON 표준 이스케이프로
  Ms_Reslt := StringReplace(Ms_Reslt, sLineBreak, '\n', [rfReplaceAll]);

  Result := Ms_Reslt;
End;

Function TFormAiChatGPT.Fcv_HttpComm01(Is_Gubun, Is_EhUrl, Is_Param : AnsiString) : AnsiString;
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
      Result := '서버와 연결에 실패했습니다.';
      Mmo3_INPUT.Enabled := False;
      Btn3_SUBMT.Enabled := False;
      //ShowMessage('실패' +#13#10+#13#10+ E.Message + #13#10 + Is_EhUrl + Is_Param + #13#10 + Result);
    End;
  End;

  //성공은 200 이고 204는 데이터 없음 나머지는 에러라고함. 예외처리 안걸리는 경우가 있을까봐 한줄 추가함.
  If (IdHTTP1.ResponseCode <> 200) And (IdHTTP1.ResponseCode <> 204) And (Rs_RolBk = 'Y') Then
  Begin
    Rs_RolBk := 'N';  //실패
    //ShowMessage('실패' +#13#10+#13#10+ Is_EhUrl + Is_Param + #13#10 + Result);
  End;
  Ss_Param.Free;
  Ss_Retrn.Free;
End;

procedure TFormAiChatGPT.Btn0_Atpn1Click(Sender: TObject);
begin
  FormTrChatGPT := TFormTrChatGPT.Create(Application);
  WindowState := wsMinimized;
  FormTrChatGPT.ShowModal;

  FreeAndNil(FormTrChatGPT);
  WindowState := wsNormal;
end;

procedure TFormAiChatGPT.Pcb_UserMsgAdd(Is_Messa : AnsiString);
var
  Mp_MsgPn : TAdvSmoothPanel;
  Mm_MsgMm : TMemo;
  Mi_PreBt : Integer;
  Mi_Intgr : Integer;
begin
  //이전에 추가된 마지막 패널의 Bottom 계산
  Mi_PreBt := 5;  // 첫 패널 위쪽 여백
  For Mi_Intgr := 0 To Scr3_MainB.ControlCount - 1 Do
    If Scr3_MainB.Controls[Mi_Intgr] Is TAdvSmoothPanel Then
      Mi_PreBt := (Scr3_MainB.Controls[Mi_Intgr] As TWinControl).Top +
                  (Scr3_MainB.Controls[Mi_Intgr] As TWinControl).Height;

  //. 먼저 판넬 생성
  Mp_MsgPn := TAdvSmoothPanel.Create(Scr3_MainB);
  Mp_MsgPn.Parent := Scr3_MainB;
  Mp_MsgPn.Align := alNone;
  Mp_MsgPn.Anchors := [akTop, akRight];
  Mp_MsgPn.Top := Mi_PreBt; // 이전 패널 아래로
  Mp_MsgPn.Width := Scr3_MainB.Width - 5;
  Mp_MsgPn.Height := 40;
  Mp_MsgPn.Fill.Color := RGB(233, 241, 250);
  Mp_MsgPn.Fill.ColorTo := RGB(233, 241, 250); // 그라디언트 제거

  //. 메모 생성
  Mm_MsgMm := TMemo.Create(Mp_MsgPn);
  Mm_MsgMm.Parent := Mp_MsgPn;
  Mm_MsgMm.Font.Size := 10;
  Mm_MsgMm.ReadOnly := True;
  Mm_MsgMm.Top := 5;
  Mm_MsgMm.Color := $0084FFFF;
  //Mm_MsgMm.Color := $00FAF1E9;
  Mm_MsgMm.Anchors := [akRight, akTop];
  Mm_MsgMm.Height := 25;
  Mm_MsgMm.Font.Name := '나눔고딕';
  Mm_MsgMm.BorderStyle := bsNone;
  Mm_MsgMm.Ctl3D := False;
  Mm_MsgMm.ParentCtl3D := False;
  Mm_MsgMm.OnKeyDown := Mmo3_INPUTKeyDown;
  Mm_MsgMm.Lines.Text := Is_Messa;

  //메모 With길이와 높이 지정
  Pcb_ResizeMemo(Mm_MsgMm);

  Mm_MsgMm.Left := Mp_MsgPn.Width - Mm_MsgMm.Width - 15; // 오른쪽 정렬

  // 패널 높이를 메모에 딱 맞게 조정
  Mp_MsgPn.Height := Mm_MsgMm.Height + Mm_MsgMm.Top;

  Scr3_MainB.VertScrollBar.Position := Scr3_MainB.VertScrollBar.Range;
end;

procedure TFormAiChatGPT.Pcb_ResizeMemo(Im_AMemo : TMemo);
Var
  Mi_MaxWh : Integer;
  Mb_BitMp : TBitmap;
  Mr_TRect : TRect;
  Mt_TxtMt : TTextMetric;
  Mh_DcHdc: HDC;
Begin
  Mi_MaxWh := 520;

  // 가상 캔버스 준비
  Mb_BitMp := TBitmap.Create;
  Try
    Mb_BitMp.Canvas.Font := Im_AMemo.Font;
    Mh_DcHdc := Mb_BitMp.Canvas.Handle;

    SetBkMode(Mh_DcHdc, TRANSPARENT);

    GetTextMetrics(Mh_DcHdc, Mt_TxtMt);

    // DrawText로 DT_CALCRECT + DT_WORDBREAK 측정
    Mr_TRect := Rect(0, 0, Mi_MaxWh, 0);
    DrawText(Mh_DcHdc,
             PChar(Im_AMemo.Text), Length(Im_AMemo.Text),
             Mr_TRect,
             DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX);

    // Memo 크기 적용
    Im_AMemo.Width := Min(Mr_TRect.Right + 8, Mi_MaxWh);  // 좌우 여백 8px 추가
    Im_AMemo.Height := Mr_TRect.Bottom + Mt_TxtMt.tmExternalLeading + 8;
    // 위아래 여백 4px 정도 추가 (필요에 따라 조정)
  Finally
    Mb_BitMp.Free;
  End;
  // WordWrap 설정: MaxWidth에 딱 걸리면 줄바꿈 모드
  //Im_AMemo.WordWrap := (Im_AMemo.Width >= Mi_MaxWh);
  Im_AMemo.WordWrap := True;
  Im_AMemo.ScrollBars := ssNone;
End;

procedure TFormAiChatGPT.Pcb_SevrMsgAdd(Is_Messa, Is_IMGYN : AnsiString; Ii_ImgCt : Integer; Ms_ImgVA : Array Of AnsiString);
Var
  Mi_PreBt : Integer;
  Mi_Intgr : Integer;
  Mp_MsgPn : TAdvSmoothPanel;
  Mm_MsgMm : TMemo;
  Mi_MmTop : Integer;
  Mi_ImgWh, Mi_ImgHt, Mi_ImgLt, Mi_ImgTp : Integer;
  Mm_TIMge : TImage;
Begin
  //이전에 추가된 마지막 패널의 Bottom 계산
  Mi_PreBt := 5;  // 첫 패널 위쪽 여백
  For Mi_Intgr := 0 To Scr3_MainB.ControlCount - 1 Do
    If Scr3_MainB.Controls[Mi_Intgr] Is TAdvSmoothPanel Then
      Mi_PreBt := (Scr3_MainB.Controls[Mi_Intgr] As TWinControl).Top +
                  (Scr3_MainB.Controls[Mi_Intgr] As TWinControl).Height;

  //먼저 판넬 생성
  Mp_MsgPn := TAdvSmoothPanel.Create(Scr3_MainB);
  Mp_MsgPn.Parent := Scr3_MainB;
  Mp_MsgPn.Align := alNone;
  Mp_MsgPn.Top := Mi_PreBt; // 이전 패널 아래로
  Mp_MsgPn.Width := Scr3_MainB.Width - 5;
  Mp_MsgPn.Height := 40;
  Mp_MsgPn.Fill.Color := RGB(233, 241, 250);
  Mp_MsgPn.Fill.ColorTo := RGB(233, 241, 250); // 그라디언트 제거

  Mi_MmTop := 5;
  If Is_IMGYN = 'Y' Then
  Begin
    If Ii_ImgCt <= 2 Then
    Begin
      Mm_TIMge := TImage.Create(Mp_MsgPn);
      Mm_TIMge.Parent := Mp_MsgPn;

      //이미지 위치와 크기 값
      Mi_ImgWh := 400; Mi_ImgHt := 225;
      Mi_ImgLt := 5; Mi_ImgTp := 5;

      //. 이미지를 넣으면 메모 탑을 그 밑으로 내려주자
      Mi_MmTop := Mi_MmTop + Mi_ImgHt + 5;

      //. 위치와 크기 설정
      Mm_TIMge.Left := Mi_ImgLt;
      Mm_TIMge.Top := Mi_ImgTp;
      Mm_TIMge.Width := Mi_ImgWh;
      Mm_TIMge.Height := Mi_ImgHt;

       //. 더블클릭 이벤트를 받도록 스타일에 csDoubleClicks 추가 (필수인 경우)
      Mm_TIMge.ControlStyle := Mm_TIMge.ControlStyle + [csDoubleClicks];
      Mm_TIMge.OnClick := Img3_IMG01Click;

      Mm_TIMge.Stretch := True;    // True면 Width/Height에 맞춰 그림을 늘림
      Pcb_LoadImages(Ms_ImgVA[0], Mm_TIMge);
      Rl_ImgLs.Add(Mm_TIMge);

      If Ii_ImgCt = 2 Then
      Begin
        Mm_TIMge := TImage.Create(Mp_MsgPn);
        Mm_TIMge.Parent := Mp_MsgPn;

        //. 이미지 탑을 메모위치로
        Mi_ImgTp := Mi_MmTop;

        //. 이미지를 넣으면 메모 탑을 그 밑으로 내려주자
        Mi_MmTop := Mi_MmTop + Mi_ImgHt + 5;

        Mm_TIMge.Left := Mi_ImgLt;
        Mm_TIMge.Top := Mi_ImgTp;
        Mm_TIMge.Width := Mi_ImgWh;
        Mm_TIMge.Height := Mi_ImgHt;

        Mm_TIMge.ControlStyle := Mm_TIMge.ControlStyle + [csDoubleClicks];
        Mm_TIMge.OnClick := Img3_IMG01Click;

        Mm_TIMge.Stretch := True;
        Pcb_LoadImages(Ms_ImgVA[1], Mm_TIMge);
        Rl_ImgLs.Add(Mm_TIMge);
      End;
    End Else
    If Ii_ImgCt > 2 Then
    Begin
      //.. 첫번째 이미지
      Mm_TIMge := TImage.Create(Mp_MsgPn);
      Mm_TIMge.Parent := Mp_MsgPn;

      //이미지 위치와 크기 값
      Mi_ImgWh := 140; Mi_ImgHt := 79;
      Mi_ImgLt := 5; Mi_ImgTp := 5;

      //이미지를 넣으면 메모 탑을 그 밑으로 내려주자
      Mi_MmTop := Mi_MmTop + Mi_ImgHt + 5;

      //위치와 크기 설정
      Mm_TIMge.Left := Mi_ImgLt;
      Mm_TIMge.Top := Mi_ImgTp;
      Mm_TIMge.Width := Mi_ImgWh;
      Mm_TIMge.Height := Mi_ImgHt;

       //더블클릭 이벤트를 받도록 스타일에 csDoubleClicks 추가 (필수인 경우)
      Mm_TIMge.ControlStyle := Mm_TIMge.ControlStyle + [csDoubleClicks];
      Mm_TIMge.OnClick := Img3_IMG01Click;

      Mm_TIMge.Stretch := True;    // True면 Width/Height에 맞춰 그림을 늘림
      Pcb_LoadImages(Ms_ImgVA[0], Mm_TIMge);
      Rl_ImgLs.Add(Mm_TIMge);

      //.. 두 번째 이미지
      Mm_TIMge := TImage.Create(Mp_MsgPn);
      Mm_TIMge.Parent := Mp_MsgPn;

      Mi_ImgLt := Mi_ImgLt + Mi_ImgWh + 1;

      Mm_TIMge.Left := Mi_ImgLt;
      Mm_TIMge.Top := Mi_ImgTp;
      Mm_TIMge.Width := Mi_ImgWh;
      Mm_TIMge.Height := Mi_ImgHt;

      Mm_TIMge.ControlStyle := Mm_TIMge.ControlStyle + [csDoubleClicks];
      Mm_TIMge.OnClick := Img3_IMG01Click;

      Mm_TIMge.Stretch := True;
      Pcb_LoadImages(Ms_ImgVA[1], Mm_TIMge);
      Rl_ImgLs.Add(Mm_TIMge);

      //.. 세 번째 이미지
      Mm_TIMge := TImage.Create(Mp_MsgPn);
      Mm_TIMge.Parent := Mp_MsgPn;

      Mi_ImgLt := Mi_ImgLt + Mi_ImgWh + 1;

      Mm_TIMge.Left := Mi_ImgLt;
      Mm_TIMge.Top := Mi_ImgTp;
      Mm_TIMge.Width := Mi_ImgWh;
      Mm_TIMge.Height := Mi_ImgHt;

      Mm_TIMge.ControlStyle := Mm_TIMge.ControlStyle + [csDoubleClicks];
      Mm_TIMge.OnClick := Img3_IMG01Click;

      Mm_TIMge.Stretch := True;
      Pcb_LoadImages(Ms_ImgVA[2], Mm_TIMge);
      Rl_ImgLs.Add(Mm_TIMge);

      If Ii_ImgCt >= 4 Then
      Begin
        //.. 네 번째 이미지
        Mm_TIMge := TImage.Create(Mp_MsgPn);
        Mm_TIMge.Parent := Mp_MsgPn;

        // 4번째 이미지는 다시 5로
        Mi_ImgLt := 5;

        //. 이미지 탑을 메모위치로
        Mi_ImgTp := Mi_MmTop;

        //. 이미지를 넣으면 메모 탑을 그 밑으로 내려주자
        Mi_MmTop := Mi_MmTop + Mi_ImgHt + 5;

        Mm_TIMge.Left := Mi_ImgLt;
        Mm_TIMge.Top := Mi_ImgTp;
        Mm_TIMge.Width := Mi_ImgWh;
        Mm_TIMge.Height := Mi_ImgHt;

        Mm_TIMge.ControlStyle := Mm_TIMge.ControlStyle + [csDoubleClicks];
        Mm_TIMge.OnClick := Img3_IMG01Click;

        Mm_TIMge.Stretch := True;
        Pcb_LoadImages(Ms_ImgVA[3], Mm_TIMge);
        Rl_ImgLs.Add(Mm_TIMge);
        If Ii_ImgCt >= 5 Then
        Begin
          //.. 다섯 번째 이미지
          Mm_TIMge := TImage.Create(Mp_MsgPn);
          Mm_TIMge.Parent := Mp_MsgPn;

          Mi_ImgLt := Mi_ImgLt + Mi_ImgWh + 1;
          
          Mm_TIMge.Left := Mi_ImgLt;
          Mm_TIMge.Top := Mi_ImgTp;
          Mm_TIMge.Width := Mi_ImgWh;
          Mm_TIMge.Height := Mi_ImgHt;
          
          Mm_TIMge.ControlStyle := Mm_TIMge.ControlStyle + [csDoubleClicks];
          Mm_TIMge.OnClick := Img3_IMG01Click;
          
          Mm_TIMge.Stretch := True;
          Pcb_LoadImages(Ms_ImgVA[4], Mm_TIMge);
          Rl_ImgLs.Add(Mm_TIMge);
        End;
      End;
    End;
  End;

  // 메모 생성
  Mm_MsgMm := TMemo.Create(Mp_MsgPn);
  Mm_MsgMm.Parent := Mp_MsgPn;
  Mm_MsgMm.Font.Size := 11;
  Mm_MsgMm.ReadOnly := True;
  Mm_MsgMm.Top := Mi_MmTop;
  Mm_MsgMm.Color := clWindow;
  Mm_MsgMm.Anchors := [akRight, akTop];
  Mm_MsgMm.Height  := 25;
  Mm_MsgMm.Font.Name := '나눔고딕';
  Mm_MsgMm.BorderStyle := bsNone;
  Mm_MsgMm.Ctl3D := False;
  Mm_MsgMm.ParentCtl3D := False;
  Mm_MsgMm.OnKeyDown := Mmo3_INPUTKeyDown;
  Mm_MsgMm.Lines.Text := Is_Messa;

  //메모 With길이와 높이 지정
  Pcb_ResizeMemo(Mm_MsgMm);

  Mm_MsgMm.Left := 5; // 왼쪽 정렬

  // 패널 높이를 메모에 딱 맞게 조정
  Mp_MsgPn.Height := Mm_MsgMm.Height + Mm_MsgMm.Top;

  Scr3_MainB.VertScrollBar.Position := Scr3_MainB.VertScrollBar.Range;
End;

procedure TFormAiChatGPT.Pcb_LoadImages(Is_EnStr : AnsiString; Ig_TImage : TImage);
Var
  Mj_JPEGI : TJPEGImage;
  Mm_Mestm : TMemoryStream;
  Ss_StrSm : TStringStream;
Begin
  If Trim(Is_EnStr) = '' Then
    Exit;

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

procedure TFormAiChatGPT.Img3_IMG01Click(Sender: TObject);
Var
  Mi_CrIdx : Integer;
begin
  If TImage(Sender).Picture.Graphic <> Nil Then
  Begin
    Mi_CrIdx := Rl_ImgLs.IndexOf(Sender);

    FormImgsViewr := TFormImgsViewr.Create(Self);
    FormImgsViewr.Pcb_ImgListIdx(Rl_ImgLs, Mi_CrIdx);
    //FormImgsViewr.Img3_Views.Picture.Graphic := TImage(Sender).Picture.Graphic;
    FormImgsViewr.Show;
  End;
end;

procedure TFormAiChatGPT.Mmo3_INPUTEnter(Sender: TObject);
begin
  If Trim(Mmo3_INPUT.Lines.Text) = PLACEHOLDER then
  Begin
    Mmo3_INPUT.Lines.Text := '';
    Mmo3_INPUT.Font.Color := clWindowText;  // 기본 글자색으로 복귀
  End;
end;

procedure TFormAiChatGPT.Mmo3_INPUTKeyPress(Sender: TObject;
  var Key: Char);
begin
  If Key = #13 Then  // Enter
  Begin
    // Shift가 안 눌렸다면 전송
    If Not (GetKeyState(VK_SHIFT) < 0) then
    Begin
      Key := #0;       // 줄바꿈 방지
      Btn3_SUBMT.Click;
    End;
  End;
end;

procedure TFormAiChatGPT.ApplicationEvents1Message(var Msg: tagMSG;
  var Handled: Boolean);
Var
  Mi_Delta : Smallint;
  Mp_Point : TPoint;
  Mi_NwPos : Integer;
begin
  If Msg.message = WM_MOUSEWHEEL Then
  Begin
    // 현재 마우스 위치가 ScrollBox 위에 있는지 확인
    Mp_Point := ScreenToClient(Msg.pt);
    If PointInRect(Mp_Point, Scr3_MainB.BoundsRect) then
    Begin
      Mi_Delta := SmallInt(Msg.wParam shr 16); // +120 또는 -120

      Mi_NwPos := Scr3_MainB.VertScrollBar.Position - (Mi_Delta div 2);

      // 범위 제한 (0 ~ Max)
      If Mi_NwPos < 0 Then
        Mi_NwPos := 0
      Else if Mi_NwPos > Scr3_MainB.VertScrollBar.Range - Scr3_MainB.Height then
        Mi_NwPos := Scr3_MainB.VertScrollBar.Range - Scr3_MainB.Height;

      Scr3_MainB.VertScrollBar.Position := Mi_NwPos;
      Handled := True;
    End;
  End;
end;

function TFormAiChatGPT.PointInRect(const Pt: TPoint; const R: TRect): Boolean;
begin
  Result := (Pt.X >= R.Left) and (Pt.X <= R.Right) and
            (Pt.Y >= R.Top) and (Pt.Y <= R.Bottom);
end;

procedure TFormAiChatGPT.Mmo3_INPUTKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  If (ssCtrl in Shift) And (Key = Ord('A')) Then
  Begin
    (Sender as TMemo).SelectAll;
    Key := 0; // 기본 처리 막기
  End;
end;

end.
