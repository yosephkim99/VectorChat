program Prjt_AiChatGPT;

uses
  Forms,
  Form_TrChatGPT in 'Form_TrChatGPT.pas' {FormTrChatGPT},
  Form_AiChatGPT in 'Form_AiChatGPT.pas' {FormAiChatGPT},
  Form_MesageBox in 'Form_MesageBox.pas' {FormMesageBox},
  Form_ImgsViewr in 'Form_ImgsViewr.pas' {FormImgsViewr};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormAiChatGPT, FormAiChatGPT);
  Application.Run;
end.
