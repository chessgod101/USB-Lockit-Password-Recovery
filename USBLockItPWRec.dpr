program USBLockItPWRec;

uses
  Forms,
  FrmMain in 'FrmMain.pas' {USBLPWRMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TUSBLPWRMain, USBLPWRMain);
  Application.Run;
end.
