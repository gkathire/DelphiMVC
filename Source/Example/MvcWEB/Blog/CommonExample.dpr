{$INCLUDE Mvc.inc}

{$IFDEF  MVC_LIBRARY}
library CommonExample;
{$ELSE}
program CommonExample;
{$ENDIF MVC_LIBRARY}

{$IFDEF  MVC_CONSOLE}
  {$APPTYPE CONSOLE}
{$ENDIF MVC_CONSOLE}

{$IFDEF  MVC_GUI}
  {$APPTYPE GUI}
{$ENDIF MVC_GUI}

{$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished])  FIELDS([vcPublic, vcPublished])}

uses
  SysUtils,
  MvcApp in 'MvcApp.pas',
  HomeController in 'Controllers\HomeController.pas',
  AccountController in 'Controllers\AccountController.pas',
  AccountModel in 'Models\AccountModel.pas',
  BlogBLL in 'BusinessLogic\BlogBLL.pas',
  BOClasses in 'Models\BOClasses.pas',
  BlogDAL in 'DataLayer\BlogDAL.pas';

{$IFDEF  WEBMODULE_ISAPI}
exports
  GetExtensionVersion,
  HttpExtensionProc,
  TerminateExtension;
{$ENDIF WEBMODULE_ISAPI}
begin
  try
    StartApp;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
