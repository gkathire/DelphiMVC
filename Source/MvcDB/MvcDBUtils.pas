unit MvcDBUtils;

interface

uses Rtti , SysUtils , TypInfo, Generics.Defaults, SynDB,
Generics.Collections,SynCommons, SynDBODBC, SynDBOracle ,SynDBSQLite3,
SynOleDB, StrUtils, Classes,MvcDBCommon;

function SqlEqualValue(AColumn:string;AValue:TValue):string;overload;
function SqlEqualValue(AColumn:string;AValue:Variant):string;overload;
function DBTypeFromConnectionProperty(AProperties:TSQLDBConnectionProperties):TMvcDBType;
function SqlString(AValue:TValue):string;overload;
function SqlString(AValue:Variant):string;overload;

implementation

function SqlString(AValue:TValue):string;
begin
  Result:= '';
  case AValue.Kind of
    tkInteger,
    tkFloat,
    tkInt64:
    begin
      Result:= AValue.AsString;
      Exit;
    end;

    tkChar,
    tkString,
    tkWChar,
    tkLString,
    tkWString,
    tkUString:
    begin
      Result:= QuotedStr(AValue.AsString);
      Exit;
    end;

    tkVariant:
    begin
      Result:= QuotedStr(AValue.AsString);
      Exit;
    end;

  end;
end;

function SqlString(AValue:Variant):string;
begin
  case TVarData(AValue).VType of
    varSmallInt,
    varShortInt,
    varByte,
    varWord,
    varLongWord,
    varInt64,
    varUInt64,
    varInteger : Result := IntToStr(AValue);


    varSingle,
    varDouble,
    varCurrency  : Result := FloatToStr(AValue);

    varDate      : Result := QuotedStr(FormatDateTime('dd/mm/yyyy', AValue));
    varBoolean   : if AValue then Result := 'True' else Result := 'False';

    varOleStr,
    varUString,
    varString    : Result := QuotedStr(AValue);
  else
    Result := '';
  end;
end;

function DBTypeFromConnectionProperty(AProperties:TSQLDBConnectionProperties):TMvcDBType;
begin
  Result := dbUnknown;
  if (AProperties is TSQLDBSQLite3ConnectionProperties) then
    Result := dbNativeSqlite
  else if (AProperties is TSQLDBOracleConnectionProperties) then
    Result := dbNativeOracle
  else if (AProperties is TOleDBMSOracleConnectionProperties) then
    Result := dbADOOracle
  else if (AProperties is TOleDBMSSQLConnectionProperties) then
    Result := dbADOMsSql
  else if (AProperties is TOleDBMySQLConnectionProperties) then
    Result := dbADOMySql
  else if (AProperties is TOleDBAS400ConnectionProperties) then
    Result := dbADOAS400;
end;


function SqlEqualValue(AColumn:string;AValue:Variant):string;
begin
  case TVarData(AValue).VType of
    varSmallInt,
    varInteger   : Result := AColumn + ' = ' + IntToStr(AValue);

    varSingle,
    varDouble,
    varCurrency  : Result := AColumn + ' = ' + FloatToStr(AValue);

    varDate      : Result := AColumn + ' = ' + FormatDateTime('dd/mm/yyyy', AValue);
    varBoolean   : Result := AColumn + ' = ' + ifthen(AValue,'True','False');
    varString    : Result := AValue;
    else           Result := '';
  end;
end;

function SqlEqualValue(AColumn:string;AValue:TValue):string;
begin
  Result:='';
  if AColumn = '' then
    Exit;

  if (AValue.IsEmpty) then
  begin
    Result:= AColumn + ' IS NULL';
    Exit;
  end;
  case AValue.Kind of
    tkChar,
    tkUString,
    tkString,
    tkWChar,
    tkLString,
    tkWString :
      Result:= AColumn + ' = ' + QuotedStr(AValue.AsString);
    tkInteger,
    tkInt64:
      Result:= AColumn + ' = ' +  IntToStr(AValue.AsInt64);
    tkFloat:
      Result:= AColumn + ' = ' +  FloatToStr(AValue.AsExtended);
    tkVariant :
      Result:= SqlEqualValue(AColumn,AValue);
    else
      raise Exception.Create('Unable to determine the Column Datatype');
  end;

end;



initialization


finalization


end.
