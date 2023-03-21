program ZDB2_Core_Tech;

uses
  System.StartUpCopy,
  FMX.Forms,
  ZDB2_Core_Tech_Frm in 'ZDB2_Core_Tech_Frm.pas' {ZDB2_Core_Tech_Form};

{$R *.res}


begin
  System.ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.CreateForm(TZDB2_Core_Tech_Form, ZDB2_Core_Tech_Form);
  Application.Run;

end.
