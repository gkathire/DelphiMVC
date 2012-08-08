{$INCLUDE Mvc.inc}

{$IFDEF  MVC_LIBRARY}
library CommonExample.XE;
{$ELSE}
program CommonExample.XE;
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
  MvcWeb,
  MvcApp in 'MvcApp.pas',
  HomeController in 'Controllers\HomeController.pas',
  AccountController in 'Controllers\AccountController.pas',
  AccountModel in 'Models\AccountModel.pas',
  BlogBLL in 'BusinessLogic\BlogBLL.pas',
  BlogDAL in 'DataLayer\BlogDAL.pas',
  BOClasses in 'Models\BOClasses.pas';

{$IFDEF  WEBMODULE_ISAPI}
exports
  GetExtensionVersion,
  HttpExtensionProc,
  TerminateExtension;
{$ENDIF WEBMODULE_ISAPI}

{$IFDEF  MVC_ASP_DOT_NET_SUPPORT}
exports
  ProcessRequest;
{$ENDIF MVC_ASP_DOT_NET_SUPPORT}

begin
  try
    StartApp;
  except
  end;
end.
