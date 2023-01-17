program GUI;

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  uFiltersForm in 'uFiltersForm.pas' {FiltersForm},
  MainFormLogic in 'MainFormLogic.pas',
  Settings in 'Settings.pas',
  JSONSerializer in 'JSONSerializer.pas',
  Network.Consts in '..\Shared\Network.Consts.pas',
  Network.Message in '..\Shared\Network.Message.pas',
  Network.PacketBuilder in '..\Shared\Network.PacketBuilder.pas',
  UDPSocket in '..\Shared\UDPSocket.pas';

{$R *.res}

begin
{$IFDEF DEBUG}
    ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
