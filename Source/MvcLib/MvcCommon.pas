unit MvcCommon;

interface

{$IF CompilerVersion >= 21.0}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished])  FIELDS([vcPublic, vcPublished])}
{$IFEND}

uses Rtti , Classes, SysUtils , TypInfo, Generics.Defaults,
Generics.Collections,XmlDoc,XMLIntf,StrUtils,MvcDBCommon,SynCommons, SynDBODBC, SynDBOracle ,SynDBSQLite3,
SynOleDB,SynDB;

type
  TMvcDBConnectionSetting = class(TPersistent)
  private
    FDBType:TMvcDBType;
    FName:string;
    FServer:string;
    FDatabase:string;
    FUserName:string;
    FPassword:string;
    FConnectionString:string;
    FCodePage:Integer;
  public
    property DBType: TMvcDBType read FDBType write FDBType;
    property Name:string read FName write FName;
    property Server:string read FServer write FServer;
    property Database:string read FDatabase write FDatabase;
    property UserName:string read FUserName write FUserName;
    property Password:string read FPassword write FPassword;
    property CodePage:Integer read FCodePage write FCodePage;
    property ConnectionString:string read FConnectionString write FConnectionString;
  end;


  IMvcErrorList = interface
    function GetItem(AIndex:Integer):TPair<string,string>;
    property Items[AIndex: Integer]: TPair<string,string> read GetItem;default;
    procedure Add(AKey:string;AValue:string);overload;
    procedure Add(ALst:IMvcErrorList);overload;
    function Count:Integer;
    function IsValid:Boolean;
  end;

  TMvcModelState = class(TInterfacedObject,IMvcErrorList)
  private
    FErrorList:TList<TPair<string,string>>;
    FErrorMessage:string;
    FErrorException:Exception;
    function GetItem(AIndex:Integer):TPair<string,string>;
  public
    property Items[AIndex: Integer]: TPair<string,string> read GetItem;default;
    property ErrorMessage:string read FErrorMessage write FErrorMessage;
    property ErrorException:Exception read FErrorException write FErrorException;
    procedure Add(AKey:string;AValue:string);overload;
    procedure Add(ALst:IMvcErrorList);overload;
    function Count:Integer;
    function IsValid:Boolean;
    constructor Create;virtual;
    destructor Destroy;override;
  end;

  TMvcGenericStringDictionary = class(TDictionary<string, string>)
  private
    function GetItemEx(const AKey: String): string;
    procedure SetItemEx(const AKey: String; AValue: string);
  public
    property Items[const Key: string]: string read GetItemEx
      write SetItemEx; default;
    constructor Create(AQueryString: string);
    destructor Destroy;override;
  end;

  TMvcAppSetting = class
  private
    FKey:string;
    FValue:string;
  public
    property Key:string read FKey write FKey;
    property Value:string read FValue write FValue;
  end;

  TMvcLoggingSetting = class
  private
    FEnableError:Boolean;
    FEnableDebug:Boolean;
    FEnableSql:Boolean;
    FEnableWarning:Boolean;
    FEnableInformation:Boolean;
    FLogToFile:Boolean;
    FLogToDebugger:Boolean;
    FLogToDatabase:Boolean;
    FLogToDatabaseConnectionString:String;
  public
    property EnableError:Boolean read FEnableError write FEnableError;
    property EnableDebug:Boolean read FEnableDebug write FEnableDebug;
    property EnableSql:Boolean read FEnableSql write FEnableSql;
    property EnableWarning:Boolean read FEnableWarning write FEnableWarning;
    property EnableInformation:Boolean read FEnableInformation write FEnableInformation;
    property LogToFile:Boolean read FLogToFile write FLogToFile;
    property LogToDebugger:Boolean read FLogToDebugger write FLogToDebugger;
    property LogToDatabase:Boolean read FLogToDatabase write FLogToDatabase;
    property LogToDatabaseConnectionString:String read FLogToDatabaseConnectionString write FLogToDatabaseConnectionString;
  end;

  TMvcWebSetting = class
  private
    FPortNumber:Integer;
    FSessionManagerConnectionString:string;
    FSessionManagerType:string;
  public
    property PortNumber:Integer read FPortNumber write FPortNumber;
    property SessionManagerConnectionString:string read FSessionManagerConnectionString write FSessionManagerConnectionString;
    property SessionManagerType:string read FSessionManagerType write FSessionManagerType;
  end;

  TMvcConfiguration = class
  private
    FDBSections : TDictionary<String,TMvcDBConnectionSetting>;
    FAppSettings : TMvcGenericStringDictionary;
    FWebSettings : TMvcWebSetting;
    FLoggingSetting:TMvcLoggingSetting;
    FConfigFileName:string;
    procedure SaveToXML<T:class>(node: IXMLNode;AObject:T;ANodeName:string = '');
    procedure ReadFromXML<T:class>(node: IXMLNode;AObject:T);
  public
    property DBSections : TDictionary<String,TMvcDBConnectionSetting> read FDBSections write FDBSections;
    property AppSettings : TMvcGenericStringDictionary read FAppSettings write FAppSettings;
    property WebSettings : TMvcWebSetting read FWebSettings write FWebSettings;
    property LoggingSetting:TMvcLoggingSetting read FLoggingSetting write FLoggingSetting;
    property ConfigFileName:string read FConfigFileName;
    constructor Create;
    destructor Destroy;
    function LoadFromConfig(AFileName:String):Boolean;
    function ReloadConfig:Boolean;
    function IsConfigValid:Boolean;
    function ReadConfig:Boolean;
    function WriteConfig:Boolean;
    function ReadAs<T:Record>(AElement:String):T;overload;
    function ReadAs<T:Record>(AElement:String;ADefault:T):T;overload;
    function WriteAs<T:Record>(AElement:String;AValue:T):Boolean;
  end;

  ENullableException = class(Exception)
  end;
  IntegerNullable = record
  private
    FValue: Integer;
    FHasValue: Boolean;
    FSentinel: string;
  public
    constructor Create(AValue: integer);
    function HasValue: boolean;
    procedure SetNull;
    class operator Implicit(a : IntegerNullable) : Integer;
    class operator Implicit(a : Integer) : IntegerNullable;
    class operator Implicit(a : string) : IntegerNullable;
    class operator Implicit(a : Pointer) : IntegerNullable;
    class operator Implicit(a : IntegerNullable) : string;
    class operator Explicit(a : IntegerNullable) : string;
    class operator Add(a,b : IntegerNullable) : IntegerNullable;
    class operator Subtract(a,b : IntegerNullable) : IntegerNullable;
    class operator Equal(a: IntegerNullable; b: IntegerNullable) : Boolean;
    class operator Equal(a: IntegerNullable; b: pointer) : Boolean;
    class operator Inc(a: IntegerNullable) : IntegerNullable;
    class operator Dec(a: IntegerNullable) : IntegerNullable;
    class operator Multiply(a: IntegerNullable; b: IntegerNullable) : IntegerNullable;
    class operator Divide(a: IntegerNullable; b: IntegerNullable) : Extended;
    class operator Divide(a: IntegerNullable; b: Integer): Extended;
  end;

  DoubleNullable = record
  private
    FValue: Double;
    FHasValue: Boolean;
    FSentinel: string;
  public
    constructor Create(AValue: Double);
    function HasValue: boolean;
    procedure SetNull;
    class operator Implicit(a : DoubleNullable) : Double;
    class operator Implicit(a : Double) : DoubleNullable;
    class operator Implicit(a : string) : DoubleNullable;
    class operator Implicit(a : Pointer) : DoubleNullable;
    class operator Implicit(a : DoubleNullable) : string;
    class operator Explicit(a : DoubleNullable) : string;
    class operator Add(a,b : DoubleNullable) : DoubleNullable;
    class operator Subtract(a,b : DoubleNullable) : DoubleNullable;
    class operator Equal(a: DoubleNullable; b: DoubleNullable) : Boolean;
    class operator Equal(a: DoubleNullable; b: pointer) : Boolean;
    class operator Inc(a: DoubleNullable) : DoubleNullable;
    class operator Dec(a: DoubleNullable) : DoubleNullable;
    class operator Multiply(a: DoubleNullable; b: DoubleNullable) : DoubleNullable;
    class operator Divide(a: DoubleNullable; b: DoubleNullable) : Extended;
    class operator Divide(a: DoubleNullable; b: Double): Extended;
  end;

  StringNullable = record
  private
    FValue: String;
    FHasValue: Boolean;
    FSentinel: string;
  public
    constructor Create(AValue: String);
    function HasValue: boolean;
    procedure SetNull;
    class operator Implicit(a : StringNullable) : String;
    class operator Implicit(a : String) : StringNullable;
    class operator Implicit(a : Pointer) : StringNullable;
    class operator Explicit(a : StringNullable) : string;
    class operator Add(a,b : StringNullable) : StringNullable;
    class operator Subtract(a,b : StringNullable) : StringNullable;
    class operator Equal(a: StringNullable; b: StringNullable) : Boolean;
    class operator Equal(a: StringNullable; b: pointer) : Boolean;
    class operator Inc(a: StringNullable) : StringNullable;
    class operator Dec(a: StringNullable) : StringNullable;
    class operator Multiply(a: StringNullable; b: StringNullable) : StringNullable;
    class operator Divide(a: StringNullable; b: StringNullable) : Extended;
    class operator Divide(a: StringNullable; b: String): Extended;
  end;

  TDateTimeNullable = record
  private
    FValue: TDateTime;
    FHasValue: Boolean;
    FSentinel: string;
  public
    constructor Create(AValue: TDateTime);
    function HasValue: boolean;
    procedure SetNull;
    class operator Implicit(a : TDateTimeNullable) : TDateTime;
    class operator Implicit(a : TDateTime) : TDateTimeNullable;
    class operator Implicit(a : string) : TDateTimeNullable;
    class operator Implicit(a : Pointer) : TDateTimeNullable;
    class operator Implicit(a : TDateTimeNullable) : string;
    class operator Explicit(a : TDateTimeNullable) : string;
    class operator Add(a,b : TDateTimeNullable) : TDateTimeNullable;
    class operator Subtract(a,b : TDateTimeNullable) : TDateTimeNullable;
    class operator Equal(a: TDateTimeNullable; b: TDateTimeNullable) : Boolean;
    class operator Equal(a: TDateTimeNullable; b: pointer) : Boolean;
    class operator Inc(a: TDateTimeNullable) : TDateTimeNullable;
    class operator Dec(a: TDateTimeNullable) : TDateTimeNullable;
    class operator Multiply(a: TDateTimeNullable; b: TDateTimeNullable) : TDateTimeNullable;
    class operator Divide(a: TDateTimeNullable; b: TDateTimeNullable) : Extended;
    class operator Divide(a: TDateTimeNullable; b: TDateTime): Extended;
  end;

  LongIntNullable = record
  private
    FValue: LongInt;
    FHasValue: Boolean;
    FSentinel: string;
  public
    constructor Create(AValue: LongInt);
    function HasValue: boolean;
    procedure SetNull;
    class operator Implicit(a : LongIntNullable) : LongInt;
    class operator Implicit(a : LongInt) : LongIntNullable;
    class operator Implicit(a : string) : LongIntNullable;
    class operator Implicit(a : Pointer) : LongIntNullable;
    class operator Implicit(a : LongIntNullable) : string;
    class operator Explicit(a : LongIntNullable) : string;
    class operator Add(a,b : LongIntNullable) : LongIntNullable;
    class operator Subtract(a,b : LongIntNullable) : LongIntNullable;
    class operator Equal(a: LongIntNullable; b: LongIntNullable) : Boolean;
    class operator Equal(a: LongIntNullable; b: pointer) : Boolean;
    class operator Inc(a: LongIntNullable) : LongIntNullable;
    class operator Dec(a: LongIntNullable) : LongIntNullable;
    class operator Multiply(a: LongIntNullable; b: LongIntNullable) : LongIntNullable;
    class operator Divide(a: LongIntNullable; b: LongIntNullable) : Extended;
    class operator Divide(a: LongIntNullable; b: LongInt): Extended;
  end;


  function LoadConnectionFromConfig(ASectionName:String):TSQLDBConnection;
  function VariantToString(Value: Variant): String;
  function Configuration :TMvcConfiguration;
  function FileSize(fileName : String) : Int64;
  function FileLastWriteTime(fileName : String) : TDateTime;
  function DateTimeToMilliseconds(aDateTime: TDateTime): Int64;

implementation
var
  FConfiguration: TMvcConfiguration;
  ConnectionList:TDictionary<String,TSQLDBConnection>;

function FileSize(fileName : String) : Int64;
var
  sr : TSearchRec;
begin
  if FindFirst(fileName, faAnyFile, sr ) = 0 then
    result := Int64(sr.FindData.nFileSizeHigh) shl Int64(32) + Int64(sr.FindData.nFileSizeLow)
  else
    result := -1;
  FindClose(sr) ;
 end;

function FileLastWriteTime(fileName : String) : TDateTime;
var
  sr : TSearchRec;
begin
  if FindFirst(fileName, faAnyFile, sr ) = 0 then
    result := FileDateToDateTime(sr.Time)
  else
    result := -1;
  FindClose(sr) ;
 end;

function DateTimeToMilliseconds(aDateTime: TDateTime): Int64;
var
  TimeStamp: TTimeStamp;
begin
  TimeStamp := DateTimeToTimeStamp (aDateTime);
  Result := Int64 (TimeStamp.Date) * MSecsPerDay + TimeStamp.Time;
end;


function Configuration :TMvcConfiguration;
begin
  Result:=FConfiguration;
end;


procedure TMvcModelState.Add(AKey:string;AValue:string);
begin
  FErrorList.Add(TPair<string,string>.Create(AKey,AValue));
end;

function TMvcModelState.IsValid:Boolean;
begin
  result:= Count = 0;
end;

procedure TMvcModelState.Add(ALst:IMvcErrorList);
var
  I: Integer;
begin
  for I := 0 to ALst.Count -1 do
  begin
    //PairItem:=TPair<string,string>.Create;
    Self.Add(ALst[I].Key,ALst[I].Value);
  end;
end;

function TMvcModelState.Count:Integer;
begin
  Result:=FErrorList.Count;
end;

function TMvcModelState.GetItem(AIndex:Integer):TPair<string,string>;
begin
  result:=FErrorList[AIndex];
end;

constructor TMvcModelState.Create;
begin
  inherited Create;
  FErrorList := TList<TPair<string,string>>.Create;
end;

destructor TMvcModelState.Destroy;
begin
  FErrorList.Destroy;
  inherited;
end;

constructor TMvcGenericStringDictionary.Create(AQueryString: string);
var
  queryLst: TStringList;
  i, eqPos: Integer;
  AName, AValue: string;
begin
  inherited Create;
  queryLst := TStringList.Create;
  queryLst.Delimiter := '&';
  queryLst.DelimitedText := AQueryString;
  queryLst.StrictDelimiter := True;
  for i := 0 to queryLst.Count - 1 do
  begin
    eqPos := Pos('=', queryLst[i]);
    if (eqPos = 0) then
    begin
      self[queryLst[i]] := '';
    end
    else
    begin
      AName := Copy(queryLst[i], 0, eqPos);
      AValue := Copy(queryLst[i], eqPos + 1, Length(queryLst[i]));
      self[AName] := AValue
    end;
  end;
  queryLst.Destroy;
end;

destructor TMvcGenericStringDictionary.Destroy;
begin
  self.Clear;
end;

function TMvcGenericStringDictionary.GetItemEx(const AKey: String): String;
begin
  if (self.TryGetValue(AKey, result) = false) then
    Add(AKey, '');
end;

procedure TMvcGenericStringDictionary.SetItemEx(const AKey: String; AValue: String);
begin
  self.AddOrSetValue(AKey, AValue);
end;

constructor TMvcConfiguration.Create;
begin
  inherited;
  FDBSections := TDictionary<String,TMvcDBConnectionSetting>.Create;
  FAppSettings := TMvcGenericStringDictionary.Create('');
end;

destructor TMvcConfiguration.Destroy;
begin
  FDBSections.Destroy;
  FAppSettings.Destroy;
  inherited;
end;

function TMvcConfiguration.LoadFromConfig(AFileName:String):Boolean;
var
  Doc: IXMLDocument;
  RootNode: IXMLNode;
  AppSettingsNode: IXMLNode;
  DBConfigSettingsNode,SettingsNode: IXMLNode;
  I: Integer;
  DbConfigItem:TMvcDBConnectionSetting;
  AppConfigItem:TMvcAppSetting;
begin
  Result:= False;
  if FileExists(AFileName) = false then
    Exit(False);
  FConfigFileName:= AFileName;
  try
    doc := TXMLDocument.Create(nil);
    doc.LoadFromFile(AFileName);
  except
    Exit(False);
  end;
  rootNode:=doc.Node;
  if (rootNode = nil) or (rootNode.HasChildNodes = false) then
    Exit;

  rootNode:=rootNode.ChildNodes.FindNode('configuration');

  FAppSettings.Clear;
  AppSettingsNode:=rootNode.ChildNodes.FindNode('AppSettings');
  if (AppSettingsNode <> nil) AND (AppSettingsNode.HasChildNodes = true) then
  begin
    for I := 0 to AppSettingsNode.ChildNodes.Count -1 do
    begin
      AppConfigItem:=TMvcAppSetting.Create;
      ReadFromXML<TMvcAppSetting>(AppSettingsNode.ChildNodes[I],AppConfigItem);
      FAppSettings.Add(AppConfigItem.Key,AppConfigItem.Value);
    end;
  end;

  FDBSections.Clear;
  DBConfigSettingsNode:=rootNode.ChildNodes.FindNode('DBConnections');
  if (DBConfigSettingsNode <> nil) AND (DBConfigSettingsNode.HasChildNodes = true) then
  begin
    for I := 0 to DBConfigSettingsNode.ChildNodes.Count -1 do
    begin
      dbConfigItem:=TMvcDBConnectionSetting.Create;
      ReadFromXML<TMvcDBConnectionSetting>(DBConfigSettingsNode.ChildNodes[I],dbConfigItem);
      FDBSections.Add(dbConfigItem.Name ,dbConfigItem);
    end;
  end;

  SettingsNode:=rootNode.ChildNodes.FindNode('WebSettings');
  if (SettingsNode <> nil) then
    ReadFromXML<TMvcWebSetting>(SettingsNode,FWebSettings);

  SettingsNode:=rootNode.ChildNodes.FindNode('LoggingSetting');
  if (SettingsNode <> nil) then
    ReadFromXML<TMvcLoggingSetting>(SettingsNode,FLoggingSetting);

  Result:= True;
end;


function TMvcConfiguration.ReloadConfig:Boolean;
begin
  LoadFromConfig(FConfigFileName);
end;

function TMvcConfiguration.IsConfigValid:Boolean;
begin

end;

function TMvcConfiguration.ReadConfig:Boolean;
begin
  LoadFromConfig(FConfigFileName);
end;

function TMvcConfiguration.WriteConfig:Boolean;
begin
  //SaveToConfig(FConfigFileName);
end;

function TMvcConfiguration.ReadAs<T>(AElement:String):T;
begin

end;

function TMvcConfiguration.ReadAs<T>(AElement:String;ADefault:T):T;
begin

end;


function TMvcConfiguration.WriteAs<T>(AElement:String;AValue:T):Boolean;
begin

end;

procedure TMvcConfiguration.SaveToXML<T>(node: IXMLNode;AObject:T;ANodeName:string);
var
  child , subchild : IXMLNode ;
  FContext : TRttiContext ;
  FType    : TRttiType ;
  FProp    : TRttiProperty ;
  Value    : TValue ;
  FField   : TRttiField ;
  FRecord  : TRttiRecordType ;
  Data     : TValue ;
begin
  FContext := TRttiContext.Create ;
  FType := FContext.GetType ( AObject.ClassType ) ;
  Child := node.AddChild( ifthen(Trim(ANodeName) = '', AObject.ClassName,ANodeName)) ;
  for FProp in FType.GetProperties do
  begin
    if FProp.IsWritable then
    begin
      case FProp.PropertyType.TypeKind of
        tkClass :
        begin
          raise Exception.Create('Class Serialization is not supported');
        end ;
        tkRecord :
        begin
          raise Exception.Create('Record Serialization is not supported');
        end ;
        else
        begin
          Value := FProp.GetValue(TObject(AObject)) ;
          Child.Attributes[FProp.Name] := Value.ToString
        end;
      end;
    end ;
  end ;
  FContext.Free ;
end;

procedure TMvcConfiguration.ReadFromXML<T>(node: IXMLNode;AObject:T);
var
  valueChild : IXMLNode ;
  FContext : TRttiContext ;
  FType    : TRttiType ;
  FProp    : TRttiProperty ;
  Value    : TValue ;
  FField   : TRttiField ;
  FRecord  : TRttiRecordType ;
  Data     : TValue ;
begin
  FContext := TRttiContext.Create ;
  FType := FContext.GetType (AObject.ClassType ) ;
  for FProp in FType.GetProperties do
  begin
    if FProp.IsWritable then
    begin
      case FProp.PropertyType.TypeKind of
        tkClass :
        begin
          Continue;
        end ;
        tkRecord :
        begin
          Continue;
        end ;
        tkEnumeration:
        begin
          if (node.HasAttribute(FProp.Name)) then
          begin
            Data:=FProp.GetValue(TObject(AObject));
            Data:=TValue.FromOrdinal(Data.TypeInfo,GetEnumValue(Data.TypeInfo,node.Attributes[FProp.Name]));
            FProp.SetValue(TObject(AObject),Data);
          end;
          continue;
        end;
        else
        begin
          if (node.HasAttribute(FProp.Name)) then
            FProp.SetValue(TObject(AObject),TValue.FromVariant(node.Attributes[FProp.Name]));
        end;
      end;
    end ;
  end ;
  FContext.Free ;
end;





function CheckValue(a,b: IntegerNullable): boolean; overload;
begin
  Result := a.HasValue and b.HasValue;
end;

function CheckValue(a: IntegerNullable): boolean; overload;
begin
  Result := a.HasValue;
end;

class operator IntegerNullable.Add(a,b : IntegerNullable) : IntegerNullable;
begin
  if not CheckValue(a,b) then
    Result := nil
  else
    Result := a.FValue + b.FValue;
end;

constructor IntegerNullable.Create(AValue: Integer);
begin
  FHasValue := False;
end;

class operator IntegerNullable.Dec(a: IntegerNullable): IntegerNullable;
begin
  if not a.HasValue then
    raise ENullableException.Create('Value not present');
  Result := a.FValue - 1;
end;

class operator IntegerNullable.Divide(a, b: IntegerNullable): Extended;
begin
  if not CheckValue(a,b) then
    raise ENullableException.Create('Cannot assign nil to Extended')
  else
    Result := a.FValue / b.FValue;
end;

class operator IntegerNullable.Divide(a: IntegerNullable; b: Integer): Extended;
begin
  if not CheckValue(a) then
    raise ENullableException.Create('Cannot assign nil to Extended')
  else
    Result := a.FValue / b;
end;


class operator IntegerNullable.Equal(a: IntegerNullable; b: pointer): Boolean;
begin
  if b = nil then
    Exit(not a.HasValue)
  else
    raise ENullableException.Create('Cannot compare an integer with a pointer <> nil');

end;

class operator IntegerNullable.Explicit(a: IntegerNullable): string;
begin
  Result := inttostr(a.FValue);
end;

class operator IntegerNullable.Equal(a, b: IntegerNullable): Boolean;
begin
  if (not a.HasValue) or (not b.HasValue) then
    Exit(false);
  Result := a.FValue = b.FValue;
end;

function IntegerNullable.HasValue: boolean;
begin
  Result := FSentinel <> '';
end;

class operator IntegerNullable.Implicit(a : Integer) : IntegerNullable;
begin
  Result.FSentinel := 'yes';
  Result.FValue := a;
end;

procedure IntegerNullable.SetNull;
begin
  FSentinel := '';
end;

class operator IntegerNullable.Subtract(a, b: IntegerNullable): IntegerNullable;
begin
  if (not a.HasValue) or (not b.HasValue) then
    raise ENullableException.Create('Value not present');
  Result := a.FValue - b.FValue;
end;

class operator IntegerNullable.Implicit(a : IntegerNullable) : Integer;
begin
  if a.HasValue then
    Result := a.FValue
  else
    raise ENullableException.Create('Value not present');
end;

class operator IntegerNullable.Implicit(a: Pointer): IntegerNullable;
begin
  if a = nil then
    Result.SetNull;
end;

class operator IntegerNullable.Implicit(a: string): IntegerNullable;
begin
  Result := StrToInt(a);
end;

class operator IntegerNullable.Implicit(a: IntegerNullable): string;
begin
  Result := IntToStr(a.FValue);
end;

class operator IntegerNullable.Inc(a: IntegerNullable): IntegerNullable;
begin
  if not a.HasValue then
    raise ENullableException.Create('Value not present');
  Result := a.FValue + 1;
end;


class operator IntegerNullable.Multiply(a, b: IntegerNullable): IntegerNullable;
begin
  CheckValue(a,b);
  Result := a.FValue * b.FValue;
end;

function CheckValue(a,b: DoubleNullable): boolean; overload;
begin
  Result := a.HasValue and b.HasValue;
end;

function CheckValue(a: DoubleNullable): boolean; overload;
begin
  Result := a.HasValue;
end;

class operator DoubleNullable.Add(a,b : DoubleNullable) : DoubleNullable;
begin
  if not CheckValue(a,b) then
    Result := nil
  else
    Result := a.FValue + b.FValue;
end;

constructor DoubleNullable.Create(AValue: Double);
begin
  FHasValue := False;
end;

class operator DoubleNullable.Dec(a: DoubleNullable): DoubleNullable;
begin
  if not a.HasValue then
    raise ENullableException.Create('Value not present');
  Result := a.FValue - 1;
end;

class operator DoubleNullable.Divide(a, b: DoubleNullable): Extended;
begin
  if not CheckValue(a,b) then
    raise ENullableException.Create('Cannot assign nil to Extended')
  else
    Result := a.FValue / b.FValue;
end;

class operator DoubleNullable.Divide(a: DoubleNullable; b: Double): Extended;
begin
  if not CheckValue(a) then
    raise ENullableException.Create('Cannot assign nil to Extended')
  else
    Result := a.FValue / b;
end;


class operator DoubleNullable.Equal(a: DoubleNullable; b: pointer): Boolean;
begin
  if b = nil then
    Exit(not a.HasValue)
  else
    raise ENullableException.Create('Cannot compare an Double with a pointer <> nil');

end;

class operator DoubleNullable.Explicit(a: DoubleNullable): string;
begin
  Result := FloatToStr(a.FValue);
end;

class operator DoubleNullable.Equal(a, b: DoubleNullable): Boolean;
begin
  if (not a.HasValue) or (not b.HasValue) then
    Exit(false);
  Result := a.FValue = b.FValue;
end;

function DoubleNullable.HasValue: boolean;
begin
  Result := FSentinel <> '';
end;

class operator DoubleNullable.Implicit(a : Double) : DoubleNullable;
begin
  Result.FSentinel := 'yes';
  Result.FValue := a;
end;

procedure DoubleNullable.SetNull;
begin
  FSentinel := '';
end;

class operator DoubleNullable.Subtract(a, b: DoubleNullable): DoubleNullable;
begin
  if (not a.HasValue) or (not b.HasValue) then
    raise ENullableException.Create('Value not present');
  Result := a.FValue - b.FValue;
end;

class operator DoubleNullable.Implicit(a : DoubleNullable) : Double;
begin
  if a.HasValue then
    Result := a.FValue
  else
    raise ENullableException.Create('Value not present');
end;

class operator DoubleNullable.Implicit(a: Pointer): DoubleNullable;
begin
  if a = nil then
    Result.SetNull;
end;

class operator DoubleNullable.Implicit(a: string): DoubleNullable;
begin
  Result := StrToInt(a);
end;

class operator DoubleNullable.Implicit(a: DoubleNullable): string;
begin
  Result := FloatToStr(a.FValue);
end;

class operator DoubleNullable.Inc(a: DoubleNullable): DoubleNullable;
begin
  if not a.HasValue then
    raise ENullableException.Create('Value not present');
  Result := a.FValue + 1;
end;

class operator DoubleNullable.Multiply(a, b: DoubleNullable): DoubleNullable;
begin
  CheckValue(a,b);
  Result := a.FValue * b.FValue;
end;

function CheckValue(a,b: StringNullable): boolean; overload;
begin
  Result := a.HasValue and b.HasValue;
end;

function CheckValue(a: StringNullable): boolean; overload;
begin
  Result := a.HasValue;
end;

class operator StringNullable.Add(a,b : StringNullable) : StringNullable;
begin
  if not CheckValue(a,b) then
    Result := nil
  else
    Result := a.FValue + b.FValue;
end;

constructor StringNullable.Create(AValue: String);
begin
  FHasValue := False;
end;

class operator StringNullable.Dec(a: StringNullable): StringNullable;
begin
  if not a.HasValue then
    raise ENullableException.Create('Value not present');
  Result := a.FValue;
end;

class operator StringNullable.Divide(a, b: StringNullable): Extended;
begin
  raise ENullableException.Create('Operation not supported')
end;

class operator StringNullable.Divide(a: StringNullable; b: String): Extended;
begin
  raise ENullableException.Create('Operation not supported')
end;


class operator StringNullable.Equal(a: StringNullable; b: pointer): Boolean;
begin
  if b = nil then
    Exit(not a.HasValue)
  else
    raise ENullableException.Create('Cannot compare an String with a pointer <> nil');

end;

class operator StringNullable.Explicit(a: StringNullable): string;
begin
  Result := a.FValue;
end;

class operator StringNullable.Equal(a, b: StringNullable): Boolean;
begin
  if (not a.HasValue) or (not b.HasValue) then
    Exit(false);
  Result := a.FValue = b.FValue;
end;

function StringNullable.HasValue: boolean;
begin
  Result := FSentinel <> '';
end;

class operator StringNullable.Implicit(a : String) : StringNullable;
begin
  Result.FSentinel := 'yes';
  Result.FValue := a;
end;

procedure StringNullable.SetNull;
begin
  FSentinel := '';
end;

class operator StringNullable.Subtract(a, b: StringNullable): StringNullable;
begin
  raise ENullableException.Create('Operation not supported')
end;

class operator StringNullable.Implicit(a : StringNullable) : String;
begin
  if a.HasValue then
    Result := a.FValue
  else
    raise ENullableException.Create('Value not present');
end;

class operator StringNullable.Implicit(a: Pointer): StringNullable;
begin
  if a = nil then
    Result.SetNull;
end;



class operator StringNullable.Inc(a: StringNullable): StringNullable;
begin
  raise ENullableException.Create('Operation not supported')
end;


class operator StringNullable.Multiply(a, b: StringNullable): StringNullable;
begin
  raise ENullableException.Create('Operation not supported')
end;

function CheckValue(a,b: TDateTimeNullable): boolean; overload;
begin
  Result := a.HasValue and b.HasValue;
end;

function CheckValue(a: TDateTimeNullable): boolean; overload;
begin
  Result := a.HasValue;
end;

class operator TDateTimeNullable.Add(a,b : TDateTimeNullable) : TDateTimeNullable;
begin
  if not CheckValue(a,b) then
    Result := nil
  else
    Result := a.FValue + b.FValue;
end;

constructor TDateTimeNullable.Create(AValue: TDateTime);
begin
  FHasValue := False;
end;

class operator TDateTimeNullable.Dec(a: TDateTimeNullable): TDateTimeNullable;
begin
  if not a.HasValue then
    raise ENullableException.Create('Value not present');
  Result := a.FValue - 1;
end;

class operator TDateTimeNullable.Divide(a, b: TDateTimeNullable): Extended;
begin
  if not CheckValue(a,b) then
    raise ENullableException.Create('Cannot assign nil to Extended')
  else
    Result := a.FValue / b.FValue;
end;

class operator TDateTimeNullable.Divide(a: TDateTimeNullable; b: TDateTime): Extended;
begin
  if not CheckValue(a) then
    raise ENullableException.Create('Cannot assign nil to Extended')
  else
    Result := a.FValue / b;
end;


class operator TDateTimeNullable.Equal(a: TDateTimeNullable; b: pointer): Boolean;
begin
  if b = nil then
    Exit(not a.HasValue)
  else
    raise ENullableException.Create('Cannot compare an TDateTime with a pointer <> nil');

end;

class operator TDateTimeNullable.Explicit(a: TDateTimeNullable): string;
begin
  Result := DateTimeToStr(a.FValue);
end;

class operator TDateTimeNullable.Equal(a, b: TDateTimeNullable): Boolean;
begin
  if (not a.HasValue) or (not b.HasValue) then
    Exit(false);
  Result := a.FValue = b.FValue;
end;

function TDateTimeNullable.HasValue: boolean;
begin
  Result := FSentinel <> '';
end;

class operator TDateTimeNullable.Implicit(a : TDateTime) : TDateTimeNullable;
begin
  Result.FSentinel := 'yes';
  Result.FValue := a;
end;

procedure TDateTimeNullable.SetNull;
begin
  FSentinel := '';
end;

class operator TDateTimeNullable.Subtract(a, b: TDateTimeNullable): TDateTimeNullable;
begin
  if (not a.HasValue) or (not b.HasValue) then
    raise ENullableException.Create('Value not present');
  Result := a.FValue - b.FValue;
end;

class operator TDateTimeNullable.Implicit(a : TDateTimeNullable) : TDateTime;
begin
  if a.HasValue then
    Result := a.FValue
  else
    raise ENullableException.Create('Value not present');
end;

class operator TDateTimeNullable.Implicit(a: Pointer): TDateTimeNullable;
begin
  if a = nil then
    Result.SetNull;
end;

class operator TDateTimeNullable.Implicit(a: string): TDateTimeNullable;
begin
  Result := StrToInt(a);
end;

class operator TDateTimeNullable.Implicit(a: TDateTimeNullable): string;
begin
  Result := DateTimeToStr(a.FValue);
end;

class operator TDateTimeNullable.Inc(a: TDateTimeNullable): TDateTimeNullable;
begin
  if not a.HasValue then
    raise ENullableException.Create('Value not present');
  Result := a.FValue + 1;
end;

class operator TDateTimeNullable.Multiply(a, b: TDateTimeNullable): TDateTimeNullable;
begin
  CheckValue(a,b);
  Result := a.FValue * b.FValue;
end;

function CheckValue(a,b: LongIntNullable): boolean; overload;
begin
  Result := a.HasValue and b.HasValue;
end;

function CheckValue(a: LongIntNullable): boolean; overload;
begin
  Result := a.HasValue;
end;

class operator LongIntNullable.Add(a,b : LongIntNullable) : LongIntNullable;
begin
  if not CheckValue(a,b) then
    Result := nil
  else
    Result := a.FValue + b.FValue;
end;

constructor LongIntNullable.Create(AValue: LongInt);
begin
  FHasValue := False;
end;

class operator LongIntNullable.Dec(a: LongIntNullable): LongIntNullable;
begin
  if not a.HasValue then
    raise ENullableException.Create('Value not present');
  Result := a.FValue - 1;
end;

class operator LongIntNullable.Divide(a, b: LongIntNullable): Extended;
begin
  if not CheckValue(a,b) then
    raise ENullableException.Create('Cannot assign nil to Extended')
  else
    Result := a.FValue / b.FValue;
end;

class operator LongIntNullable.Divide(a: LongIntNullable; b: LongInt): Extended;
begin
  if not CheckValue(a) then
    raise ENullableException.Create('Cannot assign nil to Extended')
  else
    Result := a.FValue / b;
end;


class operator LongIntNullable.Equal(a: LongIntNullable; b: pointer): Boolean;
begin
  if b = nil then
    Exit(not a.HasValue)
  else
    raise ENullableException.Create('Cannot compare an LongInt with a pointer <> nil');

end;

class operator LongIntNullable.Explicit(a: LongIntNullable): string;
begin
  Result := inttostr(a.FValue);
end;

class operator LongIntNullable.Equal(a, b: LongIntNullable): Boolean;
begin
  if (not a.HasValue) or (not b.HasValue) then
    Exit(false);
  Result := a.FValue = b.FValue;
end;

function LongIntNullable.HasValue: boolean;
begin
  Result := FSentinel <> '';
end;

class operator LongIntNullable.Implicit(a : LongInt) : LongIntNullable;
begin
  Result.FSentinel := 'yes';
  Result.FValue := a;
end;

procedure LongIntNullable.SetNull;
begin
  FSentinel := '';
end;

class operator LongIntNullable.Subtract(a, b: LongIntNullable): LongIntNullable;
begin
  if (not a.HasValue) or (not b.HasValue) then
    raise ENullableException.Create('Value not present');
  Result := a.FValue - b.FValue;
end;

class operator LongIntNullable.Implicit(a : LongIntNullable) : LongInt;
begin
  if a.HasValue then
    Result := a.FValue
  else
    raise ENullableException.Create('Value not present');
end;

class operator LongIntNullable.Implicit(a: Pointer): LongIntNullable;
begin
  if a = nil then
    Result.SetNull;
end;

class operator LongIntNullable.Implicit(a: string): LongIntNullable;
begin
  Result := StrToInt(a);
end;

class operator LongIntNullable.Implicit(a: LongIntNullable): string;
begin
  Result := IntToStr(a.FValue);
end;

class operator LongIntNullable.Inc(a: LongIntNullable): LongIntNullable;
begin
  if not a.HasValue then
    raise ENullableException.Create('Value not present');
  Result := a.FValue + 1;
end;

class operator LongIntNullable.Multiply(a, b: LongIntNullable): LongIntNullable;
begin
  CheckValue(a,b);
  Result := a.FValue * b.FValue;
end;


function VariantToString(Value: Variant): String;
begin
  case TVarData(Value).VType of
    varSmallInt,
    varInteger   : Result := IntToStr(Value);
    varSingle,
    varDouble,
    varCurrency  : Result := FloatToStr(Value);
    varDate      : Result := FormatDateTime('dd/mm/yyyy', Value);
    varBoolean   : if Value then Result := 'True' else Result := 'False';
    varString    : Result := Value;
    else           Result := '';
  end;
end;


function ConnectionFromDBConfig(AConnectionSetting:TMvcDBConnectionSetting):TSQLDBConnection;
var
  ConnectionProperties:TSQLDBConnectionProperties;
begin
  case AConnectionSetting.DBType of
    dbNativeSqlite:
    begin
      ConnectionProperties:=TSQLDBSQLite3ConnectionProperties.Create(AConnectionSetting.Server,AConnectionSetting.Database,AConnectionSetting.UserName,AConnectionSetting.Password);
      Result:=TSQLDBSQLite3Connection.Create(ConnectionProperties);
      Exit(Result);
    end;
    dbNativeOracle:
    begin
      ConnectionProperties:=TSQLDBOracleConnectionProperties.Create(AConnectionSetting.Server,AConnectionSetting.UserName,AConnectionSetting.Password,AConnectionSetting.CodePage);
      Result:=TSQLDBOracleConnection.Create(ConnectionProperties);
      Exit(Result);
    end;
    dbADOOracle:
    begin
      ConnectionProperties:=TOleDBOracleConnectionProperties.Create(AConnectionSetting.Server,AConnectionSetting.Database,AConnectionSetting.UserName,AConnectionSetting.Password);
      Result:=TOleDBConnection.Create(ConnectionProperties);
      Exit(Result);
    end;
    dbADOMsOracle:
    begin
      ConnectionProperties:=TOleDBMSOracleConnectionProperties.Create(AConnectionSetting.Server,AConnectionSetting.Database,AConnectionSetting.UserName,AConnectionSetting.Password);
      Result:=TOleDBConnection.Create(ConnectionProperties);
      Exit(Result);
    end;
    dbADOMsSql:
    begin
      ConnectionProperties:=TOleDBMSSQLConnectionProperties.Create(AConnectionSetting.Server,AConnectionSetting.Database,AConnectionSetting.UserName,AConnectionSetting.Password);
      Result:=TOleDBConnection.Create(ConnectionProperties);
      Exit(Result);
    end;
    dbADOMySql:
    begin
      ConnectionProperties:=TOleDBMySQLConnectionProperties.Create(AConnectionSetting.Server,AConnectionSetting.Database,AConnectionSetting.UserName,AConnectionSetting.Password);
      Result:=TOleDBConnection.Create(ConnectionProperties);
      Exit(Result);
    end;
    dbADOAS400:
    begin
      ConnectionProperties:=TOleDBAS400ConnectionProperties.Create(AConnectionSetting.Server,AConnectionSetting.Database,AConnectionSetting.UserName,AConnectionSetting.Password);
      Result:=TOleDBConnection.Create(ConnectionProperties);
      Exit(Result);
    end
  else
    raise Exception.Create('Unknown DB type specified');
  end;
end;

function LoadConnectionFromConfig(ASectionName:String):TSQLDBConnection;
var
  NewConnection:TSQLDBConnection;
begin
  if Trim(ASectionName) = '' then
      raise Exception.Create('Section Name should not be empty');
  if ConnectionList.ContainsKey(ASectionName) = false then
  begin
    MonitorEnter(ConnectionList);
    try
      if ConnectionList.ContainsKey(ASectionName) = false then
      begin
        if Configuration.DBSections.ContainsKey(ASectionName) = false then
          raise Exception.Create('Unable to find the connection string');
        NewConnection:= ConnectionFromDBConfig(Configuration.DBSections[ASectionName]);
        ConnectionList.Add(ASectionName,NewConnection);
        Exit(NewConnection);
      end;
    finally
      MonitorExit(ConnectionList);
    end;
  end;
  Result:=ConnectionList[ASectionName];
end;



initialization
  ConnectionList:=TDictionary<String,TSQLDBConnection>.Create;
  FConfiguration:= TMvcConfiguration.Create;
  if FileExists('Web.Config') then
    FConfiguration.LoadFromConfig('Web.Config')
  else
    FConfiguration.LoadFromConfig('App.Config');
finalization
  ConnectionList.Destroy;
  FConfiguration.Destroy;

end.
