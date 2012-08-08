{
  This file is part of DelphiMvcWeb project.
  Created By : Guru Kathiresan.
  License : MPL - http://www.mozilla.org/MPL/MPL-1.1.html

  TryMVCInvoke function - taken and modified from SuperObject project
  (For License info Check http://code.google.com/p/superobject/)

  ParseRazorContentFromStream - taken and modified from Delphi Relax project
  (For License info Check http://code.marcocantu.com/p/delphirelax/)
}

unit MvcWeb;

{$INCLUDE Mvc.inc}
{$IF CompilerVersion >= 21.0}
{$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished])  FIELDS([vcPublic, vcPublished])}
{$IFEND}

interface

uses Classes, Generics.Collections, StrUtils, Types, SysUtils,
  {$IF CompilerVersion > 22.0}System.RTTI, {$ELSE}RTTI, {$IFEND}
  superobject, TypInfo, IniFiles, MvcWebUtils, dwsComp, dwsRTTIExposer,
  dwsHtmlFilter, dwsCompiler, dwsExprs, dwsFunctions, dwsRTTIConnector,
  CopyPrsr, HTTPProd, uHTMLWriter, HTMLWriterUtils,
  dwsStringFunctions, dwsTimeFunctions, dwsVariantFunctions,
  dwsGlobalVarsFunctions,
  dwsMathFunctions,MvcCommon,MvcDBCommon,
{$IF CompilerVersion > 22.0}Winapi.Windows, {$ELSE}Windows, {$IFEND} TrivialXmlWriter
{$IFDEF WEBMODULE_BASED}
{$IFDEF WEBMODULE_INDY}
    , IdHTTPWebBrokerBridge
{$ENDIF WEBMODULE_INDY}
    , {$IF CompilerVersion > 22.0}Web.WebReq, {$ELSE}WebReq, {$IFEND} {$IF CompilerVersion > 22.0}Web.WebBroker, {$ELSE}WebBroker, {$IFEND} {$IF CompilerVersion > 22.0}Web.HTTPApp{$ELSE}HTTPApp{$IFEND}
{$ENDIF WEBMODULE_BASED};

type
  TRequestType = (rtInternal, rtFile, rtText, rtStream);

  TMvcStringObj = class
  private
    FValue: string;
  public
    property Value: String read FValue write FValue;
    constructor Create(const AValue: String);
  end;

  TMvcIntegerObj = class
  public
    Value: Integer;
    constructor Create(const AValue: Integer);
  end;

  TMvcRealObj = class
  public
    Value: real;
    constructor Create(const AValue: real);
  end;

  TMvcDateTimeObj = class
  public
    Value: TDateTime;
    constructor Create(const AValue: TDateTime);
  end;

  TMvcBooleanObj = class
  public
    Value: Boolean;
    constructor Create(const AValue: Boolean);
  end;

//  TMvcArrayObj<T> = class
//  public
//    Value: TArray<T>;
//    constructor Create(const AValue: TArray<T>);
//  end;

  TMvcRoute = class;
  TMvcRequestType = (rtGet, rtPost, rtDelete);

  TMvcRouteData = class
  public
    Route: TMvcRoute;
    Url: string;
    Controller: string;
    Action: string;
    Area: string;
    Param: string;
    Id: String;
    Method: string;
  end;

  TMvcRoute = class
  protected
    FRouteName: string;
    FRouteUrl: string;
    FDefaultController: string;
    FDefaultAction: string;
    FDefaultParam: string;
    FParamOptional: Boolean;
    FParsedStructure: TStringList;
  public
    property RouteName: string read FRouteName;
    property RouteUrl: string read FRouteUrl;
    property DefaultController: string read FDefaultController;
    property DefaultAction: string read FDefaultAction;
    property DefaultParam: string read FDefaultParam;
    property ParamOptional: Boolean read FParamOptional;
    constructor Create(ARouteName, ARouteUrl, ADefaultController,
      ADefaultAction, ADefaultParam: String; AParamOptional: Boolean);
    destructor Destroy; override;
    procedure ParseUrlStructure(ARouteUrl: String;
      AParsedStructure: TStringList);
    function DataFromUrl(Url: String): TMvcRouteData;
    function UrlFromData(AData: TMvcRouteData): string;
    function DefaultRouteData: TMvcRouteData;
  end;

  TMvcRouteList = class
  private
    FRouteList: TList<TMvcRoute>;
  public
    constructor Create;
    destructor Destroy; override;
    property RouteList: TList<TMvcRoute> read FRouteList;
    procedure Add(Item: TMvcRoute);
    procedure Remove(Item: TMvcRoute);
    function RouteDataFromUrl(AUrl: String): TMvcRouteData;
  end;

  IMvcViewResult = Interface
    function GetHttpResponse: String; // read FResponse write FResponse;
    function GetHttpFileType: String;
    function GetHttpResponseCode: Integer;
    procedure SetHttpResponse(AValue: String);
    procedure SetHttpResponseCode(AValue: Integer);
    procedure SetHttpFileType(AValue: String);
    function GetInternalError: String;
    procedure SetInternalError(AValue: String);
    function GetRequestType: TRequestType;
    procedure SetRequestType(AValue: TRequestType);
    function GetRequestStream: TStream;
    procedure SetRequestStream(AValue: TStream);
    function GetRequestFileName: string;
    procedure SetRequestFileName(AValue: string);
    function GetRequestDownloadFileName: string;
    procedure SetRequestDownloadFileName(AValue: string);
    function GetScript: String;
    procedure SetScript(AValue: String);
    procedure AssignDataTo(AAssignTo: IMvcViewResult);
    property HttpResponse: String read GetHttpResponse write SetHttpResponse;
    property HttpResponseCode: Integer read GetHttpResponseCode
      write SetHttpResponseCode;
    property HttpFileType: String read GetHttpFileType write SetHttpFileType;
    property InternalError: String read GetInternalError write SetInternalError;
    property Script: String read GetScript write SetScript;
    property RequestType: TRequestType read GetRequestType write SetRequestType;
    property RequestStream: TStream read GetRequestStream
      write SetRequestStream;
    property RequestFileName: String read GetRequestFileName
      write SetRequestFileName;
    property RequestDownloadFileName: String read GetRequestDownloadFileName
      write SetRequestDownloadFileName;
  end;

  TMvcViewResult = class(TInterfacedObject, IMvcViewResult)
  private
    FHttpResponse: String;
    FHttpResponseCode: Integer;
    FHttpFileType: String;
    FInternalError: String;
    FInternalScript: String;
    FRequestType: TRequestType;
    FRequestStream: TStream;
    FRequestFileName: String;
    FRequestDownloadFileName: String;
    function GetHttpResponse: String;
    function GetHttpResponseCode: Integer;
    function GetHttpFileType: String;
    procedure SetHttpResponse(AValue: String);
    procedure SetHttpResponseCode(AValue: Integer);
    procedure SetHttpFileType(AValue: String);
    function GetInternalError: String;
    procedure SetInternalError(AValue: String);
    function GetScript: String;
    procedure SetScript(AValue: String);
    function GetRequestType: TRequestType;
    procedure SetRequestType(AValue: TRequestType);
    function GetRequestStream: TStream;
    procedure SetRequestStream(AValue: TStream);
    function GetRequestFileName: string;
    procedure SetRequestFileName(AValue: string);
    function GetRequestDownloadFileName: string;
    procedure SetRequestDownloadFileName(AValue: string);
  public
    property Script: String read GetScript write SetScript;
    property HttpResponse: String read FHttpResponse write FHttpResponse;
    property HttpResponseCode: Integer read FHttpResponseCode
      write FHttpResponseCode;
    property HttpFileType: String read FHttpFileType write FHttpFileType;
    property InternalError: String read GetInternalError write SetInternalError;
    property RequestType: TRequestType read GetRequestType write SetRequestType
      default rtInternal;
    property RequestStream: TStream read GetRequestStream
      write SetRequestStream;
    property RequestFileName: String read GetRequestFileName
      write SetRequestFileName;
    property RequestDownloadFileName: String read GetRequestDownloadFileName
      write SetRequestDownloadFileName;

    constructor Create(AResponse: String; AResposeCode: Integer = 0;
      AFileType: String = '');
    procedure AssignDataTo(AAssignTo: IMvcViewResult);
  end;
{
  TMvcViewResultError = class
  private
    FHttpResponse: String;
    FHttpResponseCode: Integer;
    FHttpFileType: String;
    FInternalError: String;
    FInternalScript: String;
    FRequestType: TRequestType;
    FRequestStream: TStream;
    FRequestFileName: String;
    FRequestDownloadFileName: String;
    FScript: String;
  public
    property Script: String read FScript write FScript;
    property HttpResponse: String read FHttpResponse write FHttpResponse;
    property HttpResponseCode: Integer read FHttpResponseCode
      write FHttpResponseCode;
    property HttpFileType: String read FHttpFileType write FHttpFileType;
    property InternalError: String read FInternalError write FInternalError;
    property RequestType: TRequestType read FRequestType write FRequestType;
    property RequestStream: TStream read GetRequestStream
      write SetRequestStream;
    property RequestFileName: String read GetRequestFileName
      write SetRequestFileName;
    property RequestDownloadFileName: String read GetRequestDownloadFileName
      write SetRequestDownloadFileName;

    constructor Create(AResponse: String; AResposeCode: Integer = 0;
      AFileType: String = '');
    procedure AssignDataTo(AAssignTo: IMvcViewResult);
  end;
}

  TMvcViewData = class(TMvcStringObjectDictionary)
  end;


  TMvcQueryItems  = class(TMvcGenericStringDictionary)
  end;

  TMvcPage = class
  private
    FTitle: string;
    FLayout: string;
  public
    property Title: string read FTitle write FTitle;
    property Layout: string read FLayout write FLayout;
    constructor Create;
  end;

  TMvcHtmlHelper = class;

  TMvcController = class
  protected
    FRouteData: TMvcRouteData;
    FHtml: TMvcHtmlHelper;
    FViewData: TMvcViewData;
    FPage: TMvcPage;
    FModelState:TMvcModelState;
  public
    property HtmlHelper: TMvcHtmlHelper read FHtml write FHtml;
    property ViewData: TMvcViewData read FViewData;
    property Page: TMvcPage read FPage write FPage;
    property ModelState:TMvcModelState read FModelState write FModelState;
    constructor Create; virtual;
    destructor Destroy;override;
    function RedirectToAction(AAction: string): TMvcViewResult;
    function RedirectTo(AController, AAction: string): TMvcViewResult;
    function View: TMvcViewResult; overload;
    function View(AViewName: string): TMvcViewResult; overload;
    function View<T:Class>(AViewName: string; ViewObject: T): TMvcViewResult;
      overload;
    function View<T>(ViewObject: T): TMvcViewResult; overload;
    function JsonView<T>(ViewObject: T): TMvcViewResult;
    function XmlView<T>(ViewObject: T): TMvcViewResult;
    function FileView(fileName: string): TMvcViewResult;
    function Invoke(ARouteData: TMvcRouteData;
      const AQueryItems: TMvcQueryItems): TMvcViewResult;
    class procedure RegisterClass;
    procedure FlashInfo(AMessage:string);
    procedure FlashWarning(AMessage:string);
    procedure FlashError(AMessage:string);
  end;


  IMvcView = interface
    function GetValue: TValue;
    function GetController: TMvcController;
    function GetPage: TMvcPage;
    procedure SetPage(AValue: TMvcPage);
    procedure SetController(Value: TMvcController);
    property Value: TValue read GetValue;
    property Page: TMvcPage read GetPage write SetPage;
    property Controller: TMvcController read GetController write SetController;
    function BuildViewOutput(AArea, AViewName, AControllerName: String;
      Model: TValue; ignoreViewFileNameExistence: Boolean = false)
      : TMvcViewResult;
  end;

  TMvcView = class(TInterfacedObject, IMvcView)
  private
    FValue: TValue;
    FModelName: String;
    FController: TMvcController;
    FPage: TMvcPage;
    FNonControllerPage: TMvcPage;
    FNonControllerHtmlHelper: TMvcHtmlHelper;
    FIgnoreOtherObjectForViewObject: Boolean;
    function GetValue: TValue;
    function GetController: TMvcController;
    procedure SetController(Value: TMvcController);
    function GetPage: TMvcPage;
    procedure SetPage(AValue: TMvcPage);
    function ExtractHtmlForView(fileName: string; Model: TValue;
      includeViewBagClass: Boolean): IMvcViewResult;
    procedure BuildViewBagClass(DynamicUnit: TdwsUnit);
    function SubstituteLayoutValues(AResponse: string;
      viewResult: IMvcViewResult): String;
    procedure DynamicExposeInstancesAfterInitTable(Sender: TObject);
    procedure OnViewBagMethodEval(Info: TProgramInfo; ExtObject: TObject);
    class function FindViewFile(AArea, AControllerName,
      AViewName: String): string;
    class function FindErrorViewName(AHttpResponseCode: Integer;AViewForResult:boolean = false): String;
  public
    property Controller: TMvcController read FController write FController;
    property Value: TValue read FValue;
    property Page: TMvcPage read GetPage write SetPage;
    function BuildViewOutput(AArea, AViewName, AControllerName: String;
      Model: TValue; ignoreViewFileNameExistence: Boolean = false)
      : TMvcViewResult;
    constructor Create(AIgnoreOtherObjectForViewObject: Boolean = false);
    destructor Destroy;override;
    class function BuildErrorView(AErrorMsg: String;
      AHttpResponseCode: Integer = 0): String;overload;
    class function BuildErrorView(AErrorView: TMvcViewResult;
      AHttpResponseCode: Integer=0): String;overload;
  end;

  TMvcHtmlHelper = class
  private
    FCurrentRoute: TMvcRoute;
    FCurrentController : TMvcController;
    FV: string;
  public
    property CurrentRoute: TMvcRoute read FCurrentRoute write FCurrentRoute;
    property CurrentController : TMvcController read FCurrentController write FCurrentController;
    property V: string read FV write FV;
    constructor Create(ACurrentRoute: TMvcRoute);
    function ActionUrl(AAction, AController: String): string;
    function ActionLink(ACaption, AAction, AController: String): string;
    function RenderPartialWithParam(AViewName: String; Value: TValue): string;
    function RenderPartial(AViewName: String): string;
    function ValidationSummary(AMessage: string): string;
    function ValidationMessage(AIdName: string; AMessage: string = ''): string;
    function HtmlLabel(ALabel: string): string;
    function Password(AIdName, AValue: string): string;
    function CheckBox(AIdName, AValue: string): string;
    function TextBox(AIdName, AValue: string): string;
    function TextArea(AIdName, AValue: string): string;
    function Button(AIdName, AValue: string): string;
    function Hidden(AIdName, AValue: string): string;
    function ResetButton(AIdName, AValue: string): string;
    function SubmitButton(AIdName, AValue: string): string;
    function RadioButton(AIdName, AValue: string): string;
    function FileInput(AIdName, AValue: string): string;
    function HtmlEncode(AMessage:string):string;
    function HtmlDecode(AMessage:string):string;
    function FlashMessage():string;
  end;

  IMvcSession = interface
    function GetExpireInterval : TDateTime;
    function GetSessionID: Integer;
    function GetSessionTimeStamp: TDateTime;
    function GetSessionData: TStringList;
    procedure SetExpireInterval(AExpireInterval : TDateTime);
    procedure SetSessionID(ASessionID: Integer);
    procedure SetSessionTimeStamp(ASessionTimeStamp: TDateTime);
    procedure SetSessionData(ASessionData: TStringList);
    procedure SetValue(const Name, Value: string);
    function GetValue(const Name: string): string;
    property  Values[const Name: string]: string read GetValue write SetValue;
    property ExpireInterval : TDateTime read GetExpireInterval write SetExpireInterval;
    property SessionID: Integer read GetSessionID write SetSessionID;
    property SessionTimeStamp: TDateTime read GetSessionTimeStamp write SetSessionTimeStamp;
    property SessionData: TStringList read GetSessionData write SetSessionData;
    function  FindSessionRecord:boolean;
    procedure DeleteExpiredSessions(thetime:tdatetime);
    procedure CreateSessionRecord;
  end;

  TMvcInMemorySession = class(TInterfacedObject, IMvcSession)
  private
    FBaseStringList:TStringList;
    function GetExpireInterval : TDateTime;
    function GetSessionID: Integer;
    function GetSessionTimeStamp: TDateTime;
    function GetSessionData: TStringList;
    procedure SetExpireInterval(AExpireInterval : TDateTime);
    procedure SetSessionID(ASessionID: Integer);
    procedure SetSessionTimeStamp(ASessionTimeStamp: TDateTime);
    procedure SetSessionData(ASessionData: TStringList);
    procedure SetValue(const Name, Value: string);
    function GetValue(const Name: string): string;
  public
    property  Values[const Name: string]: string read GetValue write SetValue;
    property ExpireInterval : TDateTime read GetExpireInterval write SetExpireInterval;
    property SessionID: Integer read GetSessionID write SetSessionID;
    property SessionTimeStamp: TDateTime read GetSessionTimeStamp write SetSessionTimeStamp;
    property SessionData: TStringList read GetSessionData write SetSessionData;
    constructor Create;
    destructor Destroy;override;
    function  FindSessionRecord:boolean;
    procedure DeleteExpiredSessions(thetime:tdatetime);
    procedure CreateSessionRecord;
  end;

  TMvcInMemorySessionList = class
  private
    FSessionList:TList<TMvcInMemorySession>;
  public
    property SessionList:TList<TMvcInMemorySession> read FSessionList write FSessionList;
    constructor Create;
    destructor Destroy;override;
    procedure Add(ASession:TMvcInMemorySession);
    procedure Delete(ASession:TMvcInMemorySession);
  end;


{$IFDEF WEBMODULE_BASED}

  TMvcWebModule = class(TWebModule)
  private
    FAspDotNetMode:Boolean;
  published
    procedure OnDefaultHandler(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
    function TryToServeFile(Request: TWebRequest; Response: TWebResponse;
      AFileName: string = ''): Boolean;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent);override;
    constructor CreateForAspDotNet(AOwner: TComponent);
  end;

var
  WebModuleClass: TComponentClass = TMvcWebModule;
  MvcWebModule: TMvcWebModule;

{$IFDEF  WEBMODULE_INDY}
{$IFDEF  MVC_CONSOLE}
procedure RunConsoleIndyServer(APort: Integer);
{$ENDIF  MVC_CONSOLE}
{$ENDIF  WEBMODULE_INDY}
{$ENDIF WEBMODULE_BASED}

type
  HttpPost = class(TCustomAttribute)
  end;

  HttpGet = class(TCustomAttribute)
  end;

  HttpDelete = class(TCustomAttribute)
  end;

  TMvcInvokeResult = record
  public
    InvokeResult: TSuperInvokeResult;
    InvokeErrorMessage: String;
  end;

function MvcProcessRequest(ARouteData: TMvcRouteData;
  const AQueryItems: TMvcQueryItems): TMvcViewResult;

const
  CONTROLLER_STR = '{Controller}';
  ACTION_STR = '{Action}';
  AREA_STR = '{Area}';
  ID_STR = '{Id}';

var
  DefaultRoute: TMvcRoute;
  RouteList: TMvcRouteList;
  {$IFDEF  MVC_ASP_DOT_NET_SUPPORT}
  procedure ProcessRequest(var resultResponse:string); export;
  {$ENDIF  MVC_ASP_DOT_NET_SUPPORT}

{$IFDEF  WEBMODULE_ISAPI}
exports
  GetExtensionVersion,
  HttpExtensionProc,
  TerminateExtension;
{$ENDIF WEBMODULE_ISAPI}

implementation

uses MvcWebConst;

const
  CBrowserNames: array [TBrowser] of string = ('Unknown', 'MSIE', 'Firefox',
    'Chrome', 'Safari', 'Opera', 'Konqueror', 'Safari');

// todo: put this map into a config file
{$IFDEF  MVC_ASP_DOT_NET_SUPPORT}
procedure ProcessRequest(var resultResponse:string);
var
  AspDotNetModule:TMvcWebModule;
  Request: TWebRequest;
  Response: TWebResponse;
  Handled: Boolean;
begin
  Request:= TWebRequest.Create;
  Response:=TWebResponse.Create(Request);
  AspDotNetModule:=TMvcWebModule.CreateForAspDotNet(nil);

  AspDotNetModule.OnDefaultHandler(AspDotNetModule, Request, Response,Handled);

  Response.Destroy;
  Request.Destroy;
  AspDotNetModule.Destroy;
end;
{$ENDIF  MVC_ASP_DOT_NET_SUPPORT}

function IsHttpMethodValid(httpMethod: string;
  atlst: TArray<TCustomAttribute>): Boolean;
var
  cattrib: TCustomAttribute;
begin
  result := false;
  if ((atlst <> nil) and (Length(atlst) > 0)) then
  begin
    for cattrib in atlst do
    begin
      if ((httpMethod = 'POST') and (cattrib is HttpPost)) then
      begin
        result := True;
        Exit;
      end;
      if ((httpMethod = 'GET') and (cattrib is HttpGet)) then
      begin
        result := True;
        Exit;
      end;
      if ((httpMethod = 'DELETE') and (cattrib is HttpDelete)) then
      begin
        result := True;
        Exit;
      end;
    end;
  end;

  if (httpMethod = 'GET') then
  begin
    result := True;
    Exit;
  end;
end;

function ProcessDottedValue(TokenStr: string; Parser: TCopyParser;
  Encoding: TEncoding): string;
var
  TokenAfterDot, blockAsString, extraChar: string;
  afterdotLst: TStringList;
begin
  result := '';
  blockAsString := '';
  extraChar := '';
  afterdotLst := TStringList.Create;
  // if followed by ., read the next element
  if Parser.Token = '.' then
  begin
    repeat
      Parser.SkipToken(True);
      TokenAfterDot := Encoding.GetString(BytesOf(Parser.TokenString));
      afterdotLst.Add(TokenAfterDot);
      Parser.SkipToken(True);
    until not(Parser.Token in [toEof, '.']);

    if (Parser.Token = '(') then
    begin
      blockAsString := Encoding.GetString(BytesOf(Parser.SkipToToken(')')));
      // Parser.SkipToken(True);
      blockAsString := '(' + blockAsString + ')';
    end
    else if (Parser.Token = '[') then
    begin
      blockAsString := Encoding.GetString(BytesOf(Parser.SkipToToken(')')));
      // Parser.SkipToken(True);
      blockAsString := '[' + blockAsString;
    end
    else if (Parser.Token = ']') then
    begin
      blockAsString := Encoding.GetString(BytesOf(Parser.SkipToToken(')')));
      // Parser.SkipToken(True);
      blockAsString := blockAsString + ']';
    end
    else
      extraChar := String(Parser.Token);
  end;
  if afterdotLst.Count > 0 then
  begin
    afterdotLst.LineBreak := '.';
    result := TokenStr + '.' + afterdotLst.Text;
    result := Copy(result, 0, Length(result) - 1);
  end
  else
    result := TokenStr;
  if Length(blockAsString) > 0 then
    result := result + blockAsString;
  result := '@{=' + result + '}' + extraChar;
  afterdotLst.Destroy;
end;

function ParseRazorContentFromStream(AStream: TStream): string;
var
  Parser: TCopyParser;
  ParsedTemplate: string;
  ParsedExtraHeader: string;
  OutStream: TStringStream;
  TokenStr, blockAsString: string;
  Encoding: TEncoding;
  SignatureSize: Integer;
begin
  result := '';
  Encoding := GetEncodingOfStream(AStream, SignatureSize);
  AStream.Position := SignatureSize;
  OutStream := TStringStream.Create('', Encoding);
  try
    Parser := TCopyParser.Create(AStream, OutStream);
    try
      while True do
      begin
        while not(Parser.Token in [toEof, '@']) do
        begin
          Parser.CopyTokenToOutput;
          Parser.SkipToken(True);
        end;
        if Parser.Token = toEof then
          Break;
        if Parser.Token = '@' then
        begin
          Parser.SkipToken(True);
          TokenStr := Encoding.GetString(BytesOf(Parser.TokenString));
          Parser.SkipToken(True);
          if TokenStr = '@' then
          begin
            OutStream.WriteString('@'); // double '@@' to '@'
          end
          else if TokenStr = 'RenderBody' then
          begin
            OutStream.WriteString('@RenderBody'); // leave it in
          end
          else if TokenStr = 'RenderHeader' then
          begin
            OutStream.WriteString('@RenderHeader'); // leave it in
          end
          else if TokenStr = '{' then
          begin
            TokenStr := Encoding.GetString(BytesOf(Parser.TokenString));
            blockAsString := TokenStr + Encoding.GetString
              (BytesOf(Parser.SkipToToken('}')));
            // Parser.SkipToken(True);
            // blockAsString := Encoding.GetString(BytesOf(Parser.SkipToToken('}')));
            Parser.SkipToken(True);
            // process the block
            OutStream.WriteString('@{' + blockAsString + '}');
          end
          else
          begin
            OutStream.WriteString(ProcessDottedValue(TokenStr, Parser,
              Encoding));
            Parser.SkipToken(True);
          end;
        end;
      end;
    finally
      Parser.Free;
    end;

    if ParsedTemplate <> '' then
    begin
      result := StringReplace(ParsedTemplate, '@RenderBody',
        OutStream.DataString, []);
      result := StringReplace(result, '@RenderHeader', ParsedExtraHeader, []);
    end
    else
      result := OutStream.DataString;
  finally
    OutStream.Free;
  end;
end;

function TryMVCInvoke(var ctx: TSuperRttiContext; const httpMethod: string;
  const obj: TValue; const Method: string; const params: ISuperObject;
  var RValue: TMvcViewResult): TMvcInvokeResult;
var
  T: TRttiInstanceType;
  m, mitem: TRttiMethod;
  a: TArray<TValue>;
  ps: TArray<TRttiParameter>;
  V: TValue;
  index: ISuperObject;
  ml: TArray<TRttiMethod>;
  tmp: String;
  function GetParams: Boolean;
  var
    i: Integer;
  begin
    case ObjectGetType(params) of
      stArray:
        for i := 0 to Length(ps) - 1 do
          if (pfOut in ps[i].Flags) then
            TValue.Make(nil, ps[i].ParamType.Handle, a[i])
          else if not ctx.FromJson(ps[i].ParamType.Handle, params.AsArray[i],
            a[i]) then
          begin
            //
          end;
      stObject:
        for i := 0 to Length(ps) - 1 do
          if (pfOut in ps[i].Flags) then
            TValue.Make(nil, ps[i].ParamType.Handle, a[i])
          else
          begin
            try
              a[i] := ctx.AsType(params, ps[i].ParamType.Handle);
            except
            end;
          end;
      stNull:
        ;
    else
      Exit(false);
    end;
    result := True;
  end;

  procedure SetParams;
  var
    i: Integer;
  begin
    case ObjectGetType(params) of
      stArray:
        for i := 0 to Length(ps) - 1 do
          if (ps[i].Flags * [pfVar, pfOut]) <> [] then
            params.AsArray[i] := ctx.ToJson(a[i], index);
      stObject:
        for i := 0 to Length(ps) - 1 do
          if (ps[i].Flags * [pfVar, pfOut]) <> [] then
            params.AsObject[ps[i].Name] := ctx.ToJson(a[i], index);
    end;
  end;

begin
  result.InvokeResult := irSuccess;
  index := SO;
  case obj.Kind of
    tkClass:
      begin
        T := TRttiInstanceType(ctx.Context.GetType(obj.AsObject.ClassType));
        ml := T.GetMethods(Method);
        m := nil;
        if (ml <> nil) then
        begin
          for mitem in ml do
          begin
            if IsHttpMethodValid(httpMethod, mitem.GetAttributes()) = True then
            begin
              m := mitem;
              Break;
            end;
          end;
        end;
        if m = nil then
        begin
          result.InvokeResult := irMethothodError;
          Exit(result);
        end;

        if (m.ReturnType = nil) then
        begin
          result.InvokeResult := irMethothodError;
          Exit(result);
        end;

        tmp := m.ReturnType.QualifiedName;
        ps := m.GetParameters;
        SetLength(a, Length(ps));
        if not GetParams then
        begin
          result.InvokeResult := irParamError;
          Exit(result);
        end;
        if m.IsClassMethod then
        begin
          V := m.Invoke(obj.AsObject.ClassType, a);
          RValue := V.AsType<TMvcViewResult>;
          SetParams;
        end
        else
        begin
          V := m.Invoke(obj, a);
          RValue := V.AsType<TMvcViewResult>;
          tmp := (index as TSuperObject).ToJson().AsString;
          SetParams;
        end;
      end;
    tkClassRef:
      begin
        m := nil;
        T := TRttiInstanceType(ctx.Context.GetType(obj.AsClass));
        ml := T.GetMethods(Method);
        if (ml <> nil) then
        begin
          m := nil;
          for mitem in ml do
          begin
            if IsHttpMethodValid(httpMethod, mitem.GetAttributes()) = True then
            begin
              m := mitem;
              Break;
            end;
          end;
        end;
        if m = nil then
        begin
          result.InvokeResult := irMethothodError;
          Exit(result);
        end;
        ps := m.GetParameters;
        SetLength(a, Length(ps));
        if not GetParams then
        begin
          result.InvokeResult := irParamError;
          Exit(result);
        end;
        if m.IsClassMethod then
        begin
          V := m.Invoke(obj, a);
          RValue := V.AsType<TMvcViewResult>;
          SetParams;
        end
        else
        begin
          result.InvokeResult := irError;
          Exit(result);
        end;
      end;
  else
    begin
      result.InvokeResult := irError;
      Exit(result);
    end;
  end;
end;

constructor TMvcStringObj.Create(const AValue: String);
begin
  inherited Create;
  Value := AValue;
end;

constructor TMvcIntegerObj.Create(const AValue: Integer);
begin
  inherited Create;
  Value := AValue;
end;

constructor TMvcRealObj.Create(const AValue: real);
begin
  inherited Create;
  Value := AValue;
end;

constructor TMvcDateTimeObj.Create(const AValue: TDateTime);
begin
  inherited Create;
  Value := AValue;
end;

constructor TMvcBooleanObj.Create(const AValue: Boolean);
begin
  inherited Create;
  Value := AValue;
end;

constructor TMvcRoute.Create(ARouteName, ARouteUrl, ADefaultController,
  ADefaultAction, ADefaultParam: String; AParamOptional: Boolean);
begin
  // inherited Create;
  FRouteName := ARouteName;
  FRouteUrl := ARouteUrl;
  FDefaultController := ADefaultController;
  FDefaultAction := ADefaultAction;
  FDefaultParam := ADefaultParam;
  FParamOptional := AParamOptional;
  FParsedStructure := TStringList.Create;
  ParseUrlStructure(FRouteUrl, FParsedStructure);
end;

destructor TMvcRoute.Destroy;
begin
  FParsedStructure.Destroy;
end;

procedure TMvcRoute.ParseUrlStructure(ARouteUrl: String;
  AParsedStructure: TStringList);
var
  spltStrList: TStringDynArray;
  spltStr: String;
begin
  AParsedStructure.Clear;
  spltStrList := SplitString(RouteUrl, '/');
  for spltStr in spltStrList do
    AParsedStructure.Add(spltStr);
end;

function TMvcRoute.DataFromUrl(Url: String): TMvcRouteData;
var
  Path, StrippedPath, Param: string;
  spltStrList: TStringDynArray;
  i, QPos: Integer;
  RouteData: TMvcRouteData;
  DataFound: Boolean;
begin
  result := nil;
  if (Trim(Url) = '') or (Trim(Url) = '/') then
    Exit;
  if StartsText('/', Url) then
    Path := Copy(Url, 2, Length(Url))
  else
    Path := Url;

  QPos := Pos('?', Path);
  StrippedPath := Path;
  if (QPos <> 0) then
  begin
    StrippedPath := Copy(StrippedPath, 0, QPos - 1);
    Param := Copy(StrippedPath, QPos, Length(StrippedPath));
  end;

  spltStrList := SplitString(Path, '/');
  if spltStrList = nil then
    Exit;
  DataFound := false;
  RouteData := TMvcRouteData.Create;
  for i := Low(spltStrList) to High(spltStrList) do
  begin
    if (i > FParsedStructure.Count - 1) then
      continue;

    if (FParsedStructure[i] = CONTROLLER_STR) then
    begin
      DataFound := True;
      RouteData.Controller := spltStrList[i];
    end
    else if (FParsedStructure[i] = ACTION_STR) then
    begin
      DataFound := True;
      RouteData.Action := spltStrList[i];
    end
    else if (FParsedStructure[i] = AREA_STR) then
    begin
      DataFound := True;
      RouteData.Area := spltStrList[i];
    end
    else if (FParsedStructure[i] = ID_STR) then
    begin
      DataFound := True;
      RouteData.Id := spltStrList[i];
    end;
  end;

  if (DataFound = True) then
  begin
    RouteData.Param := Param;
    result := RouteData;
  end;
  if result <> nil then
  begin
    // if the action is not specified then the request should go to the Index
    if (Length(Trim(result.Controller)) > 0) and
      (Length(Trim(result.Action)) = 0) then
    begin
      result.Action := 'Index';
    end;
    result.Route := self;
  end;

end;

function TMvcRoute.UrlFromData(AData: TMvcRouteData): string;
var
  sep, partData: string;
  sl: TStringList;
begin
  sl := TStringList.Create;
  sl.Assign(FParsedStructure);
  sl.Delimiter := '/';
  partData := '/' + sl.DelimitedText;
  partData := StringReplace(partData, CONTROLLER_STR, AData.Controller,
    [rfReplaceAll, rfIgnoreCase]);
  partData := StringReplace(partData, ACTION_STR, AData.Action,
    [rfReplaceAll, rfIgnoreCase]);
  partData := StringReplace(partData, AREA_STR, AData.Area,
    [rfReplaceAll, rfIgnoreCase]);
  partData := StringReplace(partData, ID_STR, AData.Param,
    [rfReplaceAll, rfIgnoreCase]);
  partData := StringReplace(partData, '//', '/', [rfReplaceAll, rfIgnoreCase]);
  sl.Destroy;
  result := partData;

  if Pos('?', result) = 0 then
    sep := '?'
  else
    sep := '&';
  if Length(AData.Param) > 0 then
    result := result + sep + AData.Param
  else
    result := result
end;

function TMvcRoute.DefaultRouteData: TMvcRouteData;
begin
  result := TMvcRouteData.Create;
  result.Controller := self.FDefaultController;
  result.Action := self.FDefaultAction;
  result.Param := self.FDefaultParam;
  result.Route := self;
end;

constructor TMvcRouteList.Create;
begin
  FRouteList := TList<TMvcRoute>.Create;
end;

destructor TMvcRouteList.Destroy;
var
  i: Integer;
begin
  for i := 0 to FRouteList.Count - 1 do
    FRouteList[i].Free;
  FRouteList.Clear;
  FRouteList.Destroy;
end;

procedure TMvcRouteList.Add(Item: TMvcRoute);
begin
  FRouteList.Add(Item);
end;

procedure TMvcRouteList.Remove(Item: TMvcRoute);
begin
  FRouteList.Remove(Item);
end;

function TMvcRouteList.RouteDataFromUrl(AUrl: String): TMvcRouteData;
var
  i: Integer;
begin
  result := nil;
  for i := 0 to FRouteList.Count - 1 do
  begin
    result := FRouteList[i].DataFromUrl(AUrl);
    if result <> nil then
      Break;
  end;
end;

constructor TMvcViewResult.Create(AResponse: String; AResposeCode: Integer;
  AFileType: String);
begin
  inherited Create;
  FHttpResponse := AResponse;
  FHttpResponseCode := AResposeCode;
  FHttpFileType := AFileType;
end;

function TMvcViewResult.GetHttpResponse: String;
begin
  result := FHttpResponse;
end;

function TMvcViewResult.GetHttpResponseCode: Integer;
begin
  result := FHttpResponseCode;
end;

function TMvcViewResult.GetHttpFileType: String;
begin
  result := FHttpFileType;
end;

procedure TMvcViewResult.SetHttpResponse(AValue: String);
begin
  FHttpResponse := AValue;
end;

procedure TMvcViewResult.SetHttpResponseCode(AValue: Integer);
begin
  FHttpResponseCode := AValue;
end;

procedure TMvcViewResult.SetHttpFileType(AValue: String);
begin
  FHttpFileType := AValue;
end;

function TMvcViewResult.GetInternalError: string;
begin
  result := FInternalError;
end;

procedure TMvcViewResult.SetInternalError(AValue: String);
begin
  FInternalError := AValue;
end;

function TMvcViewResult.GetRequestType: TRequestType;
begin
  result := FRequestType;
end;

procedure TMvcViewResult.SetRequestType(AValue: TRequestType);
begin
  FRequestType := AValue;
end;

function TMvcViewResult.GetRequestStream: TStream;
begin
  result := FRequestStream;
end;

procedure TMvcViewResult.SetRequestStream(AValue: TStream);
begin
  FRequestStream := AValue;
end;

function TMvcViewResult.GetRequestFileName: string;
begin
  result := FRequestFileName;
end;

procedure TMvcViewResult.SetRequestFileName(AValue: string);
begin
  FRequestFileName := AValue;
end;

function TMvcViewResult.GetRequestDownloadFileName: string;
begin
  result := FRequestDownloadFileName;
end;

procedure TMvcViewResult.SetRequestDownloadFileName(AValue: string);
begin
  RequestDownloadFileName := AValue;
end;

function TMvcViewResult.GetScript: String;
begin
  result := FInternalScript
end;

procedure TMvcViewResult.SetScript(AValue: String);
begin
  FInternalScript := AValue;
end;

procedure TMvcViewResult.AssignDataTo(AAssignTo: IMvcViewResult);
begin
  AAssignTo.HttpResponse := HttpResponse;
  AAssignTo.HttpResponseCode := HttpResponseCode;
  AAssignTo.HttpFileType := HttpFileType;
  AAssignTo.InternalError := InternalError;
  AAssignTo.Script := Script;
end;

constructor TMvcPage.Create;
begin
  inherited;
end;

constructor TMvcController.Create;
begin
  inherited Create;
  FHtml := TMvcHtmlHelper.Create(nil);
  FViewData := TMvcViewData.Create;
  FPage := TMvcPage.Create;
  FHtml.CurrentController := self;
  FModelState:=TMvcModelState.Create;
end;

destructor TMvcController.Destroy;
begin
  FHtml.Destroy;
  FViewData.Destroy;
  FPage.Destroy;
  FModelState.Destroy;
  inherited;
end;

function TMvcController.RedirectToAction(AAction: string): TMvcViewResult;
begin
  result := TMvcViewResult.Create(FHtml.ActionUrl(AAction,
    FRouteData.Controller));
  result.HttpResponseCode := 302;
end;

function TMvcController.RedirectTo(AController, AAction: string)
  : TMvcViewResult;
begin
  result := TMvcViewResult.Create(FHtml.ActionUrl(AAction, AController));
  result.HttpResponseCode := 302;
end;

function TMvcController.View: TMvcViewResult;
var
  View: IMvcView;
  strObj: TMvcStringObj;
begin
  strObj := TMvcStringObj.Create('');
  View := TMvcView.Create;
  View.Controller := self;
  View.Page := self.FPage;
  result := View.BuildViewOutput(FRouteData.Area, FRouteData.Action,
    FRouteData.Controller, strObj);
  strObj.Destroy;
end;

function TMvcController.View(AViewName: string): TMvcViewResult;
begin
  result := TMvcViewResult.Create('Hello World', 200);
end;

function TMvcController.View<T>(ViewObject: T): TMvcViewResult;
var
  viewCode: IMvcViewResult;
  View: IMvcView;
begin
  View := TMvcView.Create;
  View.Controller := self;
  View.Page := self.FPage;
  result := View.BuildViewOutput(FRouteData.Area, FRouteData.Action,
    FRouteData.Controller, TValue.From<T>(ViewObject));
end;

function TMvcController.View<T>(AViewName: string; ViewObject: T)
  : TMvcViewResult;
var
  viewCode: IMvcViewResult;
  View: IMvcView;
begin
  View := TMvcView.Create;
  View.Controller := self;
  View.Page := self.FPage;
  result := View.BuildViewOutput(FRouteData.Area, AViewName,
    FRouteData.Controller, ViewObject as TObject);
end;

function TMvcController.JsonView<T>(ViewObject: T): TMvcViewResult;
begin
  result := TMvcViewResult.Create(TValue.From<T>(ViewObject).AsObject.ToJson().AsString, 200, TMvcWebUtils.JsonType);
end;

function TMvcController.XmlView<T>(ViewObject: T): TMvcViewResult;
var
  xmlWriter: TTrivialXmlWriter;
  sstream: TStringStream;
begin
  sstream := TStringStream.Create;
  xmlWriter := TTrivialXmlWriter.Create(sstream);
  try
    xmlWriter.WriteObjectRtti(TValue.From<T>(ViewObject).AsObject);
    result := TMvcViewResult.Create(sstream.DataString, 200, TMvcWebUtils.XMLType);
  finally
    sstream.Free;
    xmlWriter.Destroy;
  end;
end;

function TMvcController.FileView(fileName: string): TMvcViewResult;
begin
  result := TMvcViewResult.Create('fileView', 200,
    TMvcWebUtils.DownloadContentType(fileName));
end;

function TMvcController.Invoke(ARouteData: TMvcRouteData;
  const AQueryItems: TMvcQueryItems): TMvcViewResult;
var
  ctx: TSuperRttiContext;
  params: ISuperObject;
  InvokeResult: TMvcInvokeResult;
const
  DEFAULT_CP = 65001;
  DEFAULT_CHARSET = 'utf-8';
begin
  FHtml.CurrentRoute := ARouteData.Route;
  FHtml.CurrentController := Self;

  FRouteData := ARouteData;

  params := TSuperObject.Create;
  ctx := TSuperRttiContext.Create;

  params := TMvcWebUtils.HTTPInterprete(PSOChar(ARouteData.Param), True, '&',
    false, DEFAULT_CP);
  InvokeResult := TryMVCInvoke(ctx, ARouteData.Method, self, ARouteData.Action,
    params, result);
  ctx.Free;
end;

procedure TMvcController.FlashInfo(AMessage:string);
begin
  FViewData[delphi_mvc_flash_type] := 'info';
  FViewData[delphi_mvc_flash_message] := AMessage;
end;

procedure TMvcController.FlashWarning(AMessage:string);
begin
  FViewData[delphi_mvc_flash_type] := 'warning';
  FViewData[delphi_mvc_flash_message] := AMessage;
end;

procedure TMvcController.FlashError(AMessage:string);
begin
  FViewData[delphi_mvc_flash_type] := 'error';
  FViewData[delphi_mvc_flash_message] := AMessage;
end;

class procedure TMvcController.RegisterClass;
begin
end;

function TMvcView.GetValue: TValue;
begin
  result := FValue;
end;

procedure TMvcView.DynamicExposeInstancesAfterInitTable(Sender: TObject);
var
  AUnit: TdwsUnit;
  ModelName: string;
begin
  AUnit := (Sender as TdwsUnit);
  ModelName := GetTypeName(FValue.TypeInfo);
  if (FIgnoreOtherObjectForViewObject = false) then
  begin
    AUnit.ExposeInstanceToUnit('Model', FModelName, FValue.AsType<TObject>);
    if Controller = nil then
    begin
      AUnit.ExposeInstanceToUnit('Page', 'TMvcPage', FNonControllerPage);
      AUnit.ExposeInstanceToUnit('Html', 'TMvcHtmlHelper',
        FNonControllerHtmlHelper);
    end
    else
    begin
      AUnit.ExposeInstanceToUnit('Page', 'TMvcPage',
        Controller.Page as TObject);
      AUnit.ExposeInstanceToUnit('Html', 'TMvcHtmlHelper',
        Controller.HtmlHelper as TObject);
    end;
  end;
  // AUnit.ExposeInstanceToUnit('ViewBag', 'TMvcViewData', Controller.FViewData);
end;

function TMvcView.GetController: TMvcController;
begin
  result := FController;
end;

procedure TMvcView.SetController(Value: TMvcController);
begin
  FController := Value;
end;

function TMvcView.GetPage: TMvcPage;
begin
  result := FPage;
end;

procedure TMvcView.SetPage(AValue: TMvcPage);
begin
  FPage := AValue;
end;

procedure TMvcView.OnViewBagMethodEval(Info: TProgramInfo; ExtObject: TObject);
var
  Value: TValue;
begin
  Value := Controller.FViewData[Info.FuncSym.Name];
  case Value.TypeInfo.Kind of
    tkUString, tkString, tkWString, tkWChar, tkChar, tkLString:
      Info.ResultAsString := Value.AsString;
    tkInteger:
      Info.ResultAsInteger := Value.AsInteger;
    tkInt64:
      Info.ResultAsInteger := Value.AsInt64;
    tkClassRef, tkClass:
      Info.ResultAsVariant := Value.AsVariant;
    tkFloat:
      Info.ResultAsFloat := Value.AsExtended;
    tkInterface:
      Info.ResultAsVariant := Value.AsInterface;
    tkVariant:
      Info.ResultAsVariant := Value.AsVariant;
  else
    Info.ResultAsVariant := Value.AsVariant;
  end;

  // Info.ResultAsInteger:=Info.ValueAsInteger['FField']*10;
  // Controller.FViewData.Keys
end;

procedure TMvcView.BuildViewBagClass(DynamicUnit: TdwsUnit);
var
  cls: TdwsClass;
  md: TdwsMethod;
  keyName: string;
  keyValue:TValue;
begin

  cls := DynamicUnit.Classes.Add;;
  cls.Name := 'TMvcDynamicViewBag';
  if (Controller <> nil) and (Controller.FViewData <> nil) then
  begin
    for keyName in Controller.FViewData.Keys do
    begin
      keyValue:=Controller.FViewData[keyName];
      if keyValue.TypeInfo = nil then
        continue;
      md := cls.Methods.Add;
      md.Name := keyName;
      md.ResultType := String(Controller.FViewData[keyName].TypeInfo.Name);
      md.OnEval := OnViewBagMethodEval;
    end;
  end;
end;

function TMvcView.ExtractHtmlForView(fileName: string; Model: TValue;
  includeViewBagClass: Boolean): IMvcViewResult;
var
  exec: IdwsProgramExecution;
  rtype: TRttiType;
  FFilter: TdwsHtmlFilter;
  sl: TStringList;
  Context: TRttiContext;
  FCompiler: TDelphiWebScript;
  FConstUnit: TdwsUnit;
  FDynamicUnit: TdwsUnit;
  prog: IdwsProgram;
  strStr: TStringStream;
  meth:TRttiMethod;
  TyInfo:PTypeInfo;
  InterReturnFunc:TValue;
  function ViewBagScript: string;
  begin
    result := ' @{ var ViewBag : TMvcDynamicViewBag; ViewBag := TMvcDynamicViewBag.Create;} ';
  end;

begin
  FCompiler := TDelphiWebScript.Create(nil);
  Context := TRttiContext.Create;
  rtype := Context.GetType(Model.TypeInfo);
  FValue := Model;
  FModelName := rtype.Name;

  // FCompiler.OnInclude := DoInclude;
  FFilter := TdwsHtmlFilter.Create(nil);
  FFilter.PatternOpen := '@{';
  FFilter.PatternClose := '}';
  FFilter.PatternEval := '=';
  FCompiler.Config.Filter := FFilter;
  // if (Model <> nil) then
  begin
    FConstUnit := TdwsUnit.Create(nil);
    FDynamicUnit := TdwsUnit.Create(nil);

    FDynamicUnit.UnitName := fileName;
    FConstUnit.UnitName := '_Const_Unit_Is_This_Unit';
    if (FIgnoreOtherObjectForViewObject = false) then
    begin
      FDynamicUnit.ExposeRTTI(TypeInfo(TMvcHtmlHelper),
        [eoExposeVirtual, eoNoFreeOnCleanup, eoExposePublic]);
      FDynamicUnit.ExposeRTTI(TypeInfo(TMvcPage),
        [eoExposeVirtual, eoNoFreeOnCleanup, eoExposePublic]);
      FDynamicUnit.ExposeRTTI(TypeInfo(TMethod),
        [eoExposeVirtual, eoNoFreeOnCleanup, eoExposePublic]);
      FDynamicUnit.ExposeRTTI(TypeInfo(TValueData),
        [eoExposeVirtual, eoNoFreeOnCleanup, eoExposePublic]);
      FDynamicUnit.ExposeRTTI(TypeInfo(TValue),
        [eoExposeVirtual, eoNoFreeOnCleanup, eoExposePublic]);
    end;



    if rtype.TypeKind = tkClass then
    begin
      meth := rtype.GetMethod('InnerClassTypeInfo');
      if (meth <> nil )then
      begin
        InterReturnFunc:=meth.Invoke(Model,[]);

        if InterReturnFunc.IsEmpty = false then
        begin
          TyInfo := InterReturnFunc.AsType<PTypeInfo>;
          if TyInfo <> nil then
          begin
            FDynamicUnit.ExposeRTTI(TyInfo, [eoExposeVirtual, eoNoFreeOnCleanup,
            eoExposePublic]);
          end;
        end;
      end;
    end;
    // FDynamicUnit.ExposeRTTI(TypeInfo(TMvcViewData),[eoExposeVirtual,eoNoFreeOnCleanup,eoExposePublic]);
    FDynamicUnit.ExposeRTTI(Model.TypeInfo, [eoExposeVirtual, eoNoFreeOnCleanup,
      eoExposePublic]);

    BuildViewBagClass(FDynamicUnit);
    FDynamicUnit.OnAfterInitUnitTable := DynamicExposeInstancesAfterInitTable;

    // FCompiler.AddUnit(FConstUnit);
    FCompiler.AddUnit(FDynamicUnit);
  end;

  sl := TStringList.Create;
  sl.LoadFromFile(fileName);

  strStr := TStringStream.Create(sl.Text);
  // sl.SaveToFile('c:\in.html');
  try
    sl.Text := ParseRazorContentFromStream(strStr);
    // sl.SaveToFile('c:\out.html');
  finally
    strStr.Destroy;
  end;

  try
    if (includeViewBagClass = True) then
    begin
      sl.Text := ViewBagScript + ' ' + sl.Text;
    end;
    prog := FCompiler.Compile(sl.Text);
    if ((prog.Msgs.Count > 0) and (prog.Msgs.HasErrors)) then
    begin
      result := TMvcViewResult.Create('');
      result.InternalError := HtmlEncode('Script Compile Error - ' + fileName + #10 + #13 +
        prog.Msgs.AsInfo);
      result.Script := HtmlEncode(sl.Text);
      sl.Destroy;
      FCompiler.Destroy;
      Exit;
    end;
    try
      exec := prog.Execute;
    except

    end;

    if (exec <> nil) and (exec.Msgs.HasErrors) then
    begin
      result := TMvcViewResult.Create('');
      result.InternalError := HtmlEncode('Script Execution Error - ' + fileName + #10 + #13
        + exec.Msgs.AsInfo);
      result.Script := HTMLEncode(sl.Text);
      sl.Destroy;
      FCompiler.Destroy;
      Exit;
    end;

    sl.Text := exec.result.ToString;
    result := TMvcViewResult.Create(sl.Text);

  except
    On Ex: Exception do
    begin
      result := TMvcViewResult.Create(Ex.Message + Ex.StackTrace);
      // sl.SaveToFile('c:\Test.html');
    end;
  end;
  sl.Destroy;
  FCompiler.Destroy;
end;

function TMvcView.SubstituteLayoutValues(AResponse: string;
  viewResult: IMvcViewResult): String;
begin
  result := StringReplace(AResponse, '@RenderBody()', viewResult.HttpResponse,
    [rfReplaceAll]);
end;

class function TMvcView.FindViewFile(AArea, AControllerName,
  AViewName: String): string;
var
  fileName: string;
begin
  fileName := ExpandFileName('.\Views\' + AControllerName + '\' + AViewName);
  if FileExists(fileName) then
  begin
    Exit(fileName);
  end;

  fileName := ExpandFileName('.\Views\Shared\' + AViewName);
  if FileExists(fileName) then
  begin
    Exit(fileName);
  end;

  fileName := ExpandFileName('.\Views\Common\' + AViewName);
  if FileExists(fileName) then
  begin
    Exit(fileName);
  end;

  fileName := ExpandFileName('.\Views\' + AControllerName + '\' + AViewName +
    '.phtml');
  if FileExists(fileName) then
  begin
    Exit(fileName);
  end;

  fileName := ExpandFileName('.\Views\Shared\' + AViewName + '.phtml');
  if FileExists(fileName) then
  begin
    Exit(fileName);
  end;

  fileName := ExpandFileName('.\Views\Common\' + AViewName + '.phtml');
  if FileExists(fileName) then
  begin
    Exit(fileName);
  end;

  fileName := ExpandFileName('.\Views\' + AControllerName + '\' + AViewName +
    '.layout');
  if FileExists(fileName) then
  begin
    Exit(fileName);
  end;

  fileName := ExpandFileName('.\Views\Shared\' + AViewName + '.layout');
  if FileExists(fileName) then
  begin
    Exit(fileName);
  end;

  fileName := ExpandFileName('.\Views\Common\' + AViewName + '.layout');
  if FileExists(fileName) then
  begin
    Exit(fileName);
  end;

  result := '';
end;

constructor TMvcView.Create(AIgnoreOtherObjectForViewObject: Boolean);
begin
  inherited Create;
  FIgnoreOtherObjectForViewObject := AIgnoreOtherObjectForViewObject;
  FNonControllerPage := TMvcPage.Create;
  FNonControllerHtmlHelper := TMvcHtmlHelper.Create(DefaultRoute);
end;

destructor TMvcView.Destroy;
begin
  FNonControllerPage.Destroy;
  FNonControllerHtmlHelper.Destroy;
end;

class function TMvcView.FindErrorViewName(AHttpResponseCode: Integer;AViewForResult:boolean): String;
begin
  if (AHttpResponseCode < 1) then
    result := 'Error'
  else
  begin
    result := IntToStr(AHttpResponseCode);
    if (Length(FindViewFile('', '', result)) = 0) then
      result := 'Error'
  end;
   result := result + IfThen(AViewForResult,'ForView','');
end;

class function TMvcView.BuildErrorView(AErrorView: TMvcViewResult;
  AHttpResponseCode: Integer): String;
var
  View: IMvcView;
  //ErrorMsg: TMvcStringObj;
  AViewName: string;
  viewResult: IMvcViewResult;
begin
  //ErrorMsg := TMvcStringObj.Create(AErrorMsg);
  View := TMvcView.Create(false);
  AViewName := TMvcView.FindErrorViewName(AHttpResponseCode, true);
  viewResult := View.BuildViewOutput('', AViewName, '', AErrorView, false);
  //ErrorMsg.Destroy;
  if (Length(viewResult.InternalError) > 0) then
    result := '<html><body><H1> ' + AErrorView.InternalError + ' </H1></body></html>'
  else
    result := viewResult.HttpResponse;
end;

class function TMvcView.BuildErrorView(AErrorMsg: String;
  AHttpResponseCode: Integer): String;
var
  View: IMvcView;
  ErrorMsg: TMvcStringObj;
  AViewName: string;
  viewResult: IMvcViewResult;
begin
  ErrorMsg := TMvcStringObj.Create(AErrorMsg);
  View := TMvcView.Create(false);
  AViewName := TMvcView.FindErrorViewName(AHttpResponseCode);
  viewResult := View.BuildViewOutput('', AViewName, '', ErrorMsg, false);
  ErrorMsg.Destroy;
  if (Length(viewResult.InternalError) > 0) then
    result := '<html><body><H1> ' + AErrorMsg + ' </H1></body></html>'
  else
    result := viewResult.HttpResponse;
end;

function TMvcView.BuildViewOutput(AArea, AViewName, AControllerName: String;
  Model: TValue; ignoreViewFileNameExistence: Boolean): TMvcViewResult;
var
  fileName: string;
  layoutfileName, layoutname: string;
  pageViewResult, layoutViewResult: IMvcViewResult;
begin
  result := TMvcViewResult.Create('');
  try
    fileName := FindViewFile(AArea, AControllerName, AViewName);

    if FileExists(fileName) = false then
    begin
      result.InternalError := 'Unable to find the view file for  Area - ' +
        AArea + 'View - ' + AViewName + ' Controller - ' + AControllerName;
      Exit;
    end;

    pageViewResult := ExtractHtmlForView(fileName, Model, True);
    if Trim(pageViewResult.InternalError) <> '' then
    begin
      result.InternalError := pageViewResult.InternalError;
      result.Script := pageViewResult.Script;
      Exit;
    end;
    result.HttpResponse := pageViewResult.HttpResponse;
    if (Page <> nil) AND (Trim(Page.Layout) <> '') then
      layoutname := Page.Layout
    else if (FNonControllerPage <> nil) AND
      (Trim(FNonControllerPage.Layout) <> '') then
      layoutname := FNonControllerPage.Layout;

    if (Trim(layoutname) <> '') then
    begin
      layoutfileName := FindViewFile(AArea, AControllerName, layoutname);
      if FileExists(layoutfileName) = false then
      begin
        result.InternalError := 'Unable to find the Layout file ' +
          layoutfileName;
        Exit;
      end;
      layoutViewResult := ExtractHtmlForView(layoutfileName, Model, false);
      if Trim(layoutViewResult.InternalError) <> '' then
      begin
        result.InternalError := layoutViewResult.InternalError;
        result.Script := pageViewResult.Script;
        Exit;
      end;
      result.HttpResponse := SubstituteLayoutValues
        (layoutViewResult.HttpResponse, pageViewResult);
      result.HttpResponseCode := 200;
    end
    else
    begin
      result.HttpResponseCode := 200;
    end;
  except
    On E: Exception do
      result.InternalError := 'Unhandled Error : ' + E.Message;
  end;
end;

constructor TMvcHtmlHelper.Create(ACurrentRoute: TMvcRoute);
begin
  inherited Create;
  FCurrentRoute := ACurrentRoute;
end;

function TMvcHtmlHelper.ActionUrl(AAction, AController: String): string;
var
  AData: TMvcRouteData;
begin
  AData := TMvcRouteData.Create;
  AData.Controller := AController;
  AData.Action := AAction;
  try
    result := FCurrentRoute.UrlFromData(AData);
  finally
    AData.Free;
  end;
end;

function TMvcHtmlHelper.ActionLink(ACaption, AAction,
  AController: String): string;
begin
  result := HTMLWriterCreate.AddAnchor(ActionUrl(AAction, AController),
    ACaption).CloseTag().AsHTML;
end;

function TMvcHtmlHelper.RenderPartialWithParam(AViewName: String;
  Value: TValue): string;
var
  View: IMvcView;
  viewResult: IMvcViewResult;
begin
  View := TMvcView.Create;
  viewResult := View.BuildViewOutput('', AViewName, '', Value);
  if Length(viewResult.InternalError) > 0 then
    result := viewResult.InternalError
  else
    result := viewResult.HttpResponse;
end;

function TMvcHtmlHelper.RenderPartial(AViewName: String): string;
var
  View: IMvcView;
  strVal: TMvcStringObj;
  viewResult: IMvcViewResult;
begin
  viewResult := TMvcViewResult.Create('');
  strVal := TMvcStringObj.Create('');
  View := TMvcView.Create();
  viewResult := View.BuildViewOutput('', AViewName, '', strVal);
  strVal.Destroy;
  if Length(viewResult.InternalError) > 0 then
    result := viewResult.InternalError
  else
    result := viewResult.HttpResponse;
end;

function TMvcHtmlHelper.ValidationSummary(AMessage: string): string;
begin

end;

function TMvcHtmlHelper.ValidationMessage(AIdName: string;
  AMessage: string = ''): string;
begin

end;

function TMvcHtmlHelper.HtmlLabel(ALabel: string): string;
begin
  result := ALabel;
end;

function TMvcHtmlHelper.Password(AIdName, AValue: string): string;
begin
  result := HTMLWriterCreate.OpenInput(itPassword, AIdName)
    .AddAttribute('Value', AValue).CloseTag().AsHTML + '/>';
end;

function TMvcHtmlHelper.CheckBox(AIdName, AValue: string): string;
begin
  result := HTMLWriterCreate.OpenInput(itCheckbox, AIdName)
    .AddAttribute('Value', AValue).CloseTag().AsHTML + '/>';
end;

function TMvcHtmlHelper.TextBox(AIdName, AValue: string): string;
begin
  result := HTMLWriterCreate.OpenInput(itText, AIdName).AddAttribute('Value',
    AValue).CloseTag().AsHTML + '/>';
end;

function TMvcHtmlHelper.TextArea(AIdName, AValue: string): string;
begin
  result := HTMLWriterCreate.OpenInput(itText, AIdName).AddAttribute('Value',
    AValue).CloseTag().AsHTML + '/>';
end;

function TMvcHtmlHelper.Button(AIdName, AValue: string): string;
begin
  result := HTMLWriterCreate.OpenInput(itButton, AIdName)
    .AddAttribute('Value', AValue).CloseTag().AsHTML + '/>';
end;

function TMvcHtmlHelper.Hidden(AIdName, AValue: string): string;
begin
  result := HTMLWriterCreate.OpenInput(itHidden, AIdName)
    .AddAttribute('Value', AValue).CloseTag().AsHTML + '/>';
end;

function TMvcHtmlHelper.ResetButton(AIdName, AValue: string): string;
begin
  result := HTMLWriterCreate.OpenInput(itReset, AIdName)
    .AddAttribute('Value', AValue).CloseTag().AsHTML + '/>';
end;

function TMvcHtmlHelper.SubmitButton(AIdName, AValue: string): string;
begin
  result := HTMLWriterCreate.OpenInput(itSubmit, AIdName)
    .AddAttribute('Value', AValue).CloseTag().AsHTML + '/>';
end;

function TMvcHtmlHelper.RadioButton(AIdName, AValue: string): string;
begin
  result := HTMLWriterCreate.OpenInput(ctRadio, AIdName)
    .AddAttribute('Value', AValue).CloseTag().AsHTML + '/>';
end;

function TMvcHtmlHelper.FileInput(AIdName, AValue: string): string;
begin
  result := HTMLWriterCreate.OpenInput(itFile, AIdName).AddAttribute('Value',
    AValue).CloseTag().AsHTML + '/>';
end;

function TMvcHtmlHelper.HtmlEncode(AMessage:string):string;
begin
    result:=Web.HTTPApp.HTMLEncode(AMessage);
end;

function TMvcHtmlHelper.HtmlDecode(AMessage:string):string;
begin
    result:= Web.HttpApp.HTMLDecode(AMessage);
end;


function TMvcHtmlHelper.FlashMessage:string;
var
  flashType,flashMessage:string;
begin
  Result := '';
  if FCurrentController <> nil then
  begin
    flashType := FCurrentController.FViewData[delphi_mvc_flash_type].AsString;
    if StringIsNotEmpty(flashType) then
    begin
      flashMessage := FCurrentController.FViewData[delphi_mvc_flash_message].AsString;
      if StringIsNotEmpty(flashMessage) then
      begin
        Result := '<p class="flash ' + flashType + '"> '+ flashMessage +'</p>'
      end;
    end;
  end;
end;


function MvcProcessRequest(ARouteData: TMvcRouteData;
  const AQueryItems: TMvcQueryItems): TMvcViewResult;
var
  ctx: TRttiContext;
  rtype: TRttiType;
  Controller: TMvcController;
  ControllerClassName: String;
  controllerValue:TValue;
begin
  try
    ControllerClassName := Format('%sController.T%sController',
      [ARouteData.Controller, ARouteData.Controller]);
    rtype := ctx.FindType(ControllerClassName);
    if Assigned(rtype) = false then
    begin
      ControllerClassName := Format('T%sController', [ARouteData.Controller]);
      rtype := ctx.FindType(ControllerClassName);
    end;

    if Assigned(rtype) then
    begin
        //
        controllerValue:= rtype.GetMethod('Create').Invoke(rtype.AsInstance.MetaclassType,[]);
        Controller:= controllerValue.AsObject as TMvcController;
      //Controller := rtype.AsInstance.MetaclassType.Create ;
      try
        result := Controller.Invoke(ARouteData, AQueryItems);
      finally
        Controller.Free;
      end;
    end
    else
    begin
      Exit(Nil);
    end;
  Except
    result := nil;
  end;
end;


function TMvcInMemorySession.GetExpireInterval : TDateTime;
begin

end;

function TMvcInMemorySession.GetSessionID: Integer;
begin

end;

function TMvcInMemorySession.GetSessionTimeStamp: TDateTime;
begin

end;

function TMvcInMemorySession.GetSessionData: TStringList;
begin

end;

procedure TMvcInMemorySession.SetExpireInterval(AExpireInterval : TDateTime);
begin

end;

procedure TMvcInMemorySession.SetSessionID(ASessionID: Integer);
begin

end;

procedure TMvcInMemorySession.SetSessionTimeStamp(ASessionTimeStamp: TDateTime);
begin

end;

procedure TMvcInMemorySession.SetSessionData(ASessionData: TStringList);
begin

end;

procedure TMvcInMemorySession.SetValue(const Name, Value: string);
begin

end;

function TMvcInMemorySession.GetValue(const Name: string): string;
begin

end;

constructor TMvcInMemorySession.Create;
begin
  inherited;
  FBaseStringList := TStringList.Create;
end;

destructor TMvcInMemorySession.Destroy;
begin
  FBaseStringList.Destroy;
end;

function  TMvcInMemorySession.FindSessionRecord:boolean;
begin

end;

procedure TMvcInMemorySession.DeleteExpiredSessions(thetime:tdatetime);
begin

end;

procedure TMvcInMemorySession.CreateSessionRecord;
begin

end;

constructor TMvcInMemorySessionList.Create;
begin
  inherited;
  FSessionList := TList<TMvcInMemorySession>.Create;
end;

destructor TMvcInMemorySessionList.Destroy;
begin
  FSessionList.Destroy;
  inherited;
end;

procedure TMvcInMemorySessionList.Add(ASession:TMvcInMemorySession);
begin

end;

procedure TMvcInMemorySessionList.Delete(ASession:TMvcInMemorySession);
begin

end;


{$IFDEF WEBMODULE_BASED}
{$R MvcWebModule.dfm}

constructor TMvcWebModule.CreateForAspDotNet(AOwner: TComponent);
var
  Item: TWebActionItem;
begin
  inherited Create(AOwner);
  FAspDotNetMode:=True;
  Item := Actions.Add;
  Item.OnAction := OnDefaultHandler;
  Item.Name := 'Default';
  Item.Default := True;
  Item.Enabled := True;
  Item.PathInfo := '/';
end;

constructor TMvcWebModule.Create(AOwner: TComponent);
var
  Item: TWebActionItem;
begin
  inherited Create(AOwner);
  FAspDotNetMode:=False;
  Item := Actions.Add;
  Item.OnAction := OnDefaultHandler;
  Item.Name := 'Default';
  Item.Default := True;
  Item.Enabled := True;
  Item.PathInfo := '/';
end;

procedure TMvcWebModule.OnDefaultHandler(Sender: TObject; Request: TWebRequest;
  Response: TWebResponse; var Handled: Boolean);
type
  MethodCall = procedure of object;
var
  RouteData: TMvcRouteData;
  viewResult: TMvcViewResult;
  QueryItems: TMvcQueryItems;
begin
  try
    if not((Request.PathInfo = '') or (Request.PathInfo = '/')) then
    begin
      if TryToServeFile(Request, Response) then
      begin
        Handled := True;
        Exit;
      end;
    end;

    RouteData := RouteList.RouteDataFromUrl(String(Request.PathInfo));

    if (RouteData = nil) then
    begin
      if (RouteList.RouteList.Count > 0) then
        RouteData := RouteList.RouteList[0].DefaultRouteData;
    end;

    if (RouteData = nil) then
    begin
      Response.Content := TMvcView.BuildErrorView
        ('Unable to find a matching Routing Rule');
      Response.StatusCode := 500;
      Exit;
    end;

    RouteData.Method := Request.Method;
    RouteData.Param := Request.Content;

    QueryItems := TMvcQueryItems.Create(Request.Content);

    viewResult := MvcProcessRequest(RouteData, QueryItems);

    QueryItems.Destroy;

    RouteData.Destroy;

    if (viewResult <> nil) and (viewResult.HttpResponseCode > 0) then
    begin

      if (viewResult.RequestType = rtFile) then
      begin
        TryToServeFile(Request, Response, viewResult.RequestFileName);
      end
      else if (viewResult.RequestType = rtStream) then
      begin
        Response.ContentType := TMvcWebUtils.DownloadContentType
          (viewResult.RequestDownloadFileName);
        viewResult.RequestStream.Position := 0;
        Response.SendStream(viewResult.RequestStream);
      end
      else if (viewResult.HttpResponseCode = 302) then
      begin
        Response.StatusCode := viewResult.HttpResponseCode;
        Response.SendRedirect(viewResult.HttpResponse);
      end
      else
      begin
        if (Length(viewResult.InternalError) > 0) then
          Response.Content := TMvcView.BuildErrorView
            ('Unable to find a matching Routing Rule',
            viewResult.HttpResponseCode)
        else
          Response.Content := viewResult.HttpResponse;
        Response.StatusCode := viewResult.HttpResponseCode;
        Response.ContentType := TMvcWebUtils.DownloadContentType
          (viewResult.FHttpFileType);

      end;
    end
    else
    begin
      if (viewResult <> nil) and (Length(viewResult.InternalError) > 0) then
      begin
        Response.Content := TMvcView.BuildErrorView(viewResult);
        Response.StatusCode := 500;
      end
      else
      begin
        Response.Content := TMvcView.BuildErrorView
          ('Unable to find a matching Routing Rule');
        Response.StatusCode := 500;
      end;
    end;
  except
  end;
  Handled := True;
end;

function TMvcWebModule.TryToServeFile(Request: TWebRequest;
  Response: TWebResponse; AFileName: string): Boolean;
var
  fileName: string;
begin
  fileName := ExtractFilePath(ExpandFileName('.\Test.html'));
  fileName := StringReplace(fileName, ExtractFileDrive(fileName), '', []);
  // ExtractFilePath(ParamStr(0));
  if Length(AFileName) = 0 then
  begin
    if (Length(Request.PathInfo) > 1) and (Request.PathInfo[1] in ['/', '\'])
    then
      fileName := fileName + Copy(String(Request.PathInfo), 2, MaxInt)
    else
      fileName := fileName + String(Request.PathInfo);
    fileName := ExpandFileName(fileName);
  end
  else
  begin
    if FileExists(AFileName) = false then
    begin
      if (Length(AFileName) > 1) and (AFileName[1] in ['/', '\']) then
        fileName := fileName + Copy(AFileName, 2, MaxInt)
      else
        fileName := fileName + AFileName;
      fileName := ExpandFileName(fileName);
    end
    else
    begin
      fileName := AFileName;
    end;
  end;

  if FileExists(fileName) then
  begin
    result := True;
    Response.ContentType := String(TMvcWebUtils.DownloadContentType(fileName,
      String(TMvcWebUtils.DownloadContentType(fileName))));
    Response.FreeContentStream := True;
    Response.ContentStream := TFileStream.Create(fileName,
      fmOpenRead or fmShareDenyWrite);
    Response.SendResponse;
  end
  else
  begin
    result := false;
  end;
end;

{$ENDIF WEBMODULE_BASED}
{$IFDEF  WEBMODULE_INDY}
{$IFDEF  MVC_CONSOLE}

procedure RunConsoleIndyServer(APort: Integer);
var
  LInputRecord: TInputRecord;
  LEvent: DWord;
  LHandle: THandle;
  LServer: TIdHTTPWebBrokerBridge;
begin
  Writeln(Format('Starting HTTP Server or port %d', [APort]));
  LServer := TIdHTTPWebBrokerBridge.Create(nil);
  try
    LServer.DefaultPort := APort;
    LServer.Active := True;
    Writeln('Press ESC to stop the server');
    LHandle := GetStdHandle(STD_INPUT_HANDLE);
    while True do
    begin
      Win32Check(ReadConsoleInput(LHandle, LInputRecord, 1, LEvent));
      if (LInputRecord.EventType = KEY_EVENT) and
        LInputRecord.Event.KeyEvent.bKeyDown and
        (LInputRecord.Event.KeyEvent.wVirtualKeyCode = VK_ESCAPE) then
        Break;
    end;
  finally
    LServer.Free;
  end;
end;
{$ENDIF  MVC_CONSOLE}
{$ENDIF WEBMODULE_INDY}

initialization

RouteList := TMvcRouteList.Create;
DefaultRoute := TMvcRoute.Create('Default', '{Controller}/{Action}/{Id}',
  'Home', 'Index', '', True);
RouteList.Add(DefaultRoute);

finalization

RouteList.Destroy;

end.
