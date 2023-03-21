program ZDB2_Thread_Tech;

uses
  jemalloc4p,
  Vcl.Forms,
  ZDB2_Thread_Tech_Frm in 'ZDB2_Thread_Tech_Frm.pas' {ZDB2_Thread_Tech_Form};

{$R *.res}


begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TZDB2_Thread_Tech_Form, ZDB2_Thread_Tech_Form);
  Application.Run;

end.
