unit MvcApp;

interface

{$INCLUDE Mvc.inc}

uses
{$IFDEF WEBMODULE_BASED}
  {$IF CompilerVersion > 22.0}Web.WebReq,{$ELSE}WebReq,{$IFEND}

  {$IFDEF WEBMODULE_ISAPI}
  {$IF CompilerVersion > 22.0}Winapi.{$IFEND}ActiveX,
  {$IF CompilerVersion > 22.0}System.Win.{$IFEND}ComObj,
  {$IF CompilerVersion > 22.0}Web.{$IFEND}WebBroker,
  {$IF CompilerVersion > 22.0}Web.Win.{$IFEND}ISAPIApp,
  {$IF CompilerVersion > 22.0}Web.Win.{$IFEND}ISAPIThreadPool,
  {$ENDIF WEBMODULE_ISAPI}

  {$IFDEF WEBMODULE_INDY}
  IdHTTPWebBrokerBridge,
    {$IFDEF MVC_GUI}
  {$IF CompilerVersion > 22.0}Vcl.Forms,{$ELSE}Forms,{$IFEND}
  WMLaunchForm,
    {$ENDIF MVC_GUI}
  {$ENDIF WEBMODULE_INDY}

{$ENDIF WEBMODULE_BASED}

  SysUtils,
  Classes,
  MvcWebUtils,
  MvcWeb;

const
  ServerName = 'Mvc-Server';

procedure StartApp;

implementation

procedure StartApp;
begin
  FileMode      := fmShareDenyWrite + fmOpenReadWrite;
  FormatSettings.DecimalSeparator := '.';

  // Default Routes are added automatically
  //If you want to add additional routes uncomment the following line
  //and add your own route
  //RouteList.Add(TMvcRoute.Create('Default','{Action}/{Controller}/{Id}','Home','Index','',true));

{$IFDEF WEBMODULE_BASED}

  {$IFDEF WEBMODULE_ISAPI}
  CoInitFlags := COINIT_MULTITHREADED;
  Application.Initialize;
  Application.WebModuleClass := WebModuleClass;
  Application.Run;
  {$ENDIF WEBMODULE_ISAPI}

  {$IFDEF WEBMODULE_INDY}
  if WebRequestHandler <> nil then
    WebRequestHandler.WebModuleClass := WebModuleClass;

    {$IFDEF MVC_CONSOLE}
  RunConsoleIndyServer(8014);
    {$ENDIF MVC_CONSOLE}

    {$IFDEF MVC_GUI}
  Application.Initialize;
  Application.CreateForm(TWMLaunchFrm, WMLaunchFrm);
  Application.Run;
    {$ENDIF MVC_GUI}
  {$ENDIF WEBMODULE_INDY}

{$ENDIF WEBMODULE_BASED}

end;

end.
