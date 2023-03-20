program zMonitor_3rd_Core_Demo;

uses
  jemalloc4p,
  System.StartUpCopy,
  FMX.Forms,
  StyleModuleUnit in 'StyleModuleUnit.pas' {StyleDataModule: TDataModule},
  zMonitor_3rd_Core_Demo_Frm in 'zMonitor_3rd_Core_Demo_Frm.pas' {zMonitor_3rd_Core_Demo_Form};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TStyleDataModule, StyleDataModule);
  Application.CreateForm(TzMonitor_3rd_Core_Demo_Form, zMonitor_3rd_Core_Demo_Form);
  Application.Run;
end.
