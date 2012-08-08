unit MvcDB;

interface

uses Generics.Collections,Rtti , SynDB, SynCommons , TypInfo,
SysUtils,StrUtils, MvcDBUtils,Variants, MvcDBCommon;

type
  TMvcDBColumnDetail = class
  public
    DBColumnName :string;
    ColumnName:string;
    PrimaryKey:Boolean;
    AutoIncrement:Boolean;
    IgnoredColumn:Boolean;
    ForeignKey:Boolean;
    ForeignTableName:string;
    ForeignColumnName:string;
    ColumnRttiType : TRttiType;
  end;

  TMvcDBTableDetail = class
  public
    DBTableName:string;
    TableName:string;
    PrimaryKeyColumn:string;
    PrimaryKeyColumnIsAutoIncrement:Boolean;
    Columns:TDictionary<string,TMvcDBColumnDetail>;
    RttiContext: TRttiContext;
    TableRttiType : TRttiInstanceType;
    function GetColumnValue(AObj:TObject;AColumn:string):Variant;
  end;

  TMvcDBTableDetailsCache = class(TDictionary<string,TMvcDBTableDetail>)
  public
  end;

  TMvcDBBase = class
  protected
    FDbType:TMvcDBType;
    FDbConnection:TSQLDBConnection;
    FTableCache:TMvcDBTableDetailsCache;
    class function TableDetail(Obj:TClass ):TMvcDBTableDetail;
    function MyGetPropValue(AObj:TObject;AColumnName:string):Variant;
    procedure MySetPropValue(AObj:TObject;AColumnName:string;AData:Variant);
  public
    function Update(ASql:string):LongInt;overload;
    function Insert(ASql:string;APrimaryKeySQL:string=''):LongInt;
    function Delete(ATable,AWhere:string):LongInt;overload;
    function Exists(ASql:string):boolean;overload;
    function Select<T:class,constructor>(ASql:string):TMvcList<T>;overload;
    function First<T:class,constructor>(ASql:string):T;overload;
    function FirstAsVariant(ASql:string ):Variant;
    function FirstAsString(ASql:string ):String;overload;
    function FirstAsInteger(ASql:string ):Integer;overload;
    function FirstAsDouble(ASql:string ):Double;overload;
    function FirstAsLongInt(ASql:string ):LongInt;overload;
    function FirstAsDateTime(ASql:string ):TDateTime;overload;
    procedure BeginTransaction;
    procedure RollbackTransaction;
    procedure CommitTransaction;
  public
    constructor Create(ADbConnection:TSQLDBConnection);
  end;

  TMVcDB<T: class,constructor> = class(TMvcDBBase)
  protected
    FCurrentTableDetail:TMvcDBTableDetail;
    function InsertColumnNamesAndValues(AObject:TObject):string;
    function UpdateColumnAndValues(AObject:TObject):string;
    function GetInsertPrimaryKeyValueSQL(AObject:TObject):string;
  public
    function Insert(var AObject:T):LongInt;
    function Update(var AObject:T):LongInt;overload;
    function Update(var AObject:TMvcList<T>):LongInt;overload;
    function Update(AUpdateClause,AWhere:String):LongInt;overload;
    function Update(var AObject:T;AWhere:String):LongInt;overload;
    function Delete(AObject:T):LongInt;overload;
    function Delete(AWhere:string):LongInt;overload;
    function DeleteById(APrimaryKey:TValue):LongInt;overload;
    function Exists(AWhere:string=''):boolean;overload;
    function ExistsById(APrimaryKey:TValue):boolean;overload;
    function Count(AWhere:string=''):Integer;
    function FirstById(APrimaryKey:TValue):T;overload;
    function First(AWhere:string=''):T;overload;
    function FirstAsString(AColumn,AWhere:string ):String;overload;
    function FirstAsInteger(AColumn,AWhere:string ):Integer;overload;
    function FirstAsDouble(AColumn,AWhere:string ):Double;overload;
    function FirstAsLongInt(AColumn,AWhere:string ):LongInt;overload;
    function FirstAsDateTime(AColumn,AWhere:string ):TDateTime;overload;
    function Select(AWhere:string =''):TMvcList<T>;overload;
    function Page(APageNumber,APageSize:Integer;Where:string):TMvcList<T>;overload;
    constructor Create(ADbConnection:TSQLDBConnection);
  end;

implementation

var
  TableCache:TMvcDBTableDetailsCache;
  DefaultConnection:TSQLDBConnection = nil;
  DefaultConnectionProperties:TSQLDBConnectionProperties = nil;

function MyGetPropValue2(AObj:TObject;AColumnName:string):Variant;
begin
  result:=GetPropValue(AObj,AColumnName,true);
end;

procedure MySetPropValue2(AObj:TObject;AColumnName:string;AData:Variant);
begin
  SetPropValue(AObj,AColumnName,AData);
end;

function IsOracle(ADBType:TMvcDBType):Boolean;
begin
  result:= ( (ADBType = dbNativeOracle) or (ADBType = dbADOOracle) or (ADBType = dbADOMsOracle));
end;


function TMvcDBBase.MyGetPropValue(AObj:TObject;AColumnName:string):Variant;
begin
  result:=MyGetPropValue2(AObj,AColumnName);
end;

procedure TMvcDBBase.MySetPropValue(AObj:TObject;AColumnName:string;AData:Variant);
begin
  MySetPropValue2(AObj,AColumnName,AData);
end;

function TMvcDBTableDetail.GetColumnValue(AObj:TObject;AColumn:string):Variant;
begin
  Result:=MyGetPropValue2(AObj,AColumn);
end;

class function TMvcDBBase.TableDetail(Obj:TClass):TMvcDBTableDetail;
var
  ctx : TRttiContext;
  t : TRttiType;
  p : TRttiProperty;
  a : TCustomAttribute;
  column:TMvcDBColumnDetail;
begin
  if (tableCache.TryGetValue(Obj.ClassName,result)) then
    Exit;

  MonitorEnter(tableCache);
  try
    ctx := TRttiContext.Create;
    t := ctx.GetType(Obj.ClassInfo);
    result:=TMvcDBTableDetail.Create;
    result.RttiContext := ctx;
    result.TableName := Obj.ClassName;
    Result.TableRttiType := t as TRttiInstanceType;
    for a in t.GetAttributes do
    begin
      if (a is TMvcDBTableName) then
        result.DBTableName :=TMvcDBTableName(a).Name;
    end;
    if (result.DBTableName = '') then
      result.DBTableName := Obj.ClassName;

    result.Columns := TDictionary<string,TMvcDBColumnDetail>.Create;

    for p in t.GetProperties do
    begin
      column:=TMvcDBColumnDetail.Create;
      column.ColumnName := p.Name;
      column.ColumnRttiType := p.PropertyType;

      for a in p.GetAttributes do
      begin
        if (a is TMvcDBColumnName) then
          column.DBColumnName :=TMvcDBColumnName(a).Name;

        if (a is TMvcDBForeignKeyColumn) then
        begin
          column.ForeignKey := true;
          column.ForeignTableName := TMvcDBForeignKeyColumn(a).ReferenceTable;
          column.ForeignColumnName := TMvcDBForeignKeyColumn(a).ReferenceColumn;
        end;
        if (a is TMvcDBPrimaryKeyColumn) then
        begin
          column.PrimaryKey := true;
        end;
        if (a is TMvcDBAutoIncrementColumn) then
        begin
          column.AutoIncrement := true;
        end;
        if (a is TMvcDBIgnoreColumn) then
        begin
          column.IgnoredColumn := true;
        end;
      end;

      if (column.DBColumnName = '') then
        column.DBColumnName :=column.ColumnName;

      if(column.PrimaryKey) then
      begin
        result.PrimaryKeyColumn := column.DBColumnName;
        result.PrimaryKeyColumnIsAutoIncrement := column.AutoIncrement;
      end;

      result.Columns.Add(column.ColumnName,column);
    end;
    tableCache.Add(Obj.ClassName,result);

  finally
    MonitorEnter(tableCache);
  end;

end;


function TMvcDBBase.Update(ASql:string):LongInt;
var
  Stmt:TSQLDBStatement;
begin
  Stmt:=FDbConnection.NewStatement;
  try
    Stmt.Execute(StringToUTF8(ASql),false);
    Result:=Stmt.UpdateCount;
  finally
    Stmt.Destroy;
  end;
end;

function TMvcDBBase.Insert(ASql:string;APrimaryKeySQL:string):LongInt;
var
  Stmt:TSQLDBStatement;
  rowData:Variant;
begin
  Result:= 0;
  Stmt:=FDbConnection.NewStatement;
  try
    Stmt.Execute(StringToUTF8(ASql),false);
    if (Length(Trim(APrimaryKeySQL)) > 0) then
    begin
      if ( (Length(Trim(APrimaryKeySQL)) > 0) and IsOracle(FDbType)) then
      begin
        Stmt.Bind(1,0,paramOut);
      end;
      Stmt.Execute(StringToUTF8(APrimaryKeySQL),true);
      if (Stmt.ColumnCount = 1) then
      begin
      if(Stmt.Step()) then
      begin
          Stmt.ColumnToVariant(0,rowData);
          try
            Result:= rowData;
          except
          end;
        end;
      end;
    end;

  finally
    Stmt.Destroy;
  end;
end;

function TMvcDBBase.Delete(ATable,AWhere:string):LongInt;
var
  Stmt:TSQLDBStatement;
begin
  Stmt:=FDbConnection.NewStatement;
  try
    Stmt.Execute(StringToUTF8('DELETE FROM ' + ATable + IfThen(Length(AWhere)>0,'WHERE ' + AWhere,'')),false);
    Result:=Stmt.UpdateCount;
  finally
    Stmt.Destroy;
  end;
end;

function TMvcDBBase.Exists(ASql:string):Boolean;
var
  Stmt:TSQLDBStatement;
begin
  result:= False;
  Stmt:=FDbConnection.NewStatement;
  try
    Stmt.Execute(StringToUTF8(ASql),true);
    if (Stmt.Step()) then
      result:= True;
  finally
    Stmt.Destroy;
  end;
end;

function TMvcDBBase.Select<T>(ASql:string):TMvcList<T>;
var
  Stmt:TSQLDBStatement;
  J: Integer;
  Row:T;
  TblDetail:TMvcDBTableDetail;
  rowData:Variant;
  ColumnName:string;
begin
  TblDetail:=TableDetail(T);
  Stmt:=FDbConnection.NewStatement;
  try
    result := nil;
    Stmt.Execute(StringToUTF8(ASql),true);
    while Stmt.Step() do
    begin
      Row:=T.Create;
      for J := 0 to Stmt.ColumnCount -1 do
      begin
        try
        ColumnName:=UTF8ToString(Stmt.ColumnName(J));
        if TblDetail.Columns.ContainsKey(ColumnName) = false then
          continue;
        Stmt.ColumnToVariant(J,rowData);
        if VarIsNull(rowData) then
          Continue;
            MySetPropValue(Row,ColumnName,rowData);
        except
        end;
      end;
      if result = nil then
        result:=TMvcList<T>.Create;
      result.Add(Row);
    end;
  finally
    Stmt.Destroy;
  end;
end;

function TMvcDBBase.First<T>(ASql:string):T;
var
  Stmt:TSQLDBStatement;
  I: Integer;
  J,Idx: Integer;
  TblDetail:TMvcDBTableDetail;
  rowData:Variant;
  ColumnName:string;
begin
  Result:=nil;
  TblDetail:=TableDetail(T);
  Stmt:=FDbConnection.NewStatement;
  try
    Stmt.Execute(StringToUTF8(ASql),true);
    if(Stmt.Step()) then
    begin
      Result:=T.Create;
      for J := 0 to Stmt.ColumnCount -1 do
      begin
        ColumnName:= UTF8ToString(Stmt.ColumnName(J));
        if TblDetail.Columns.ContainsKey(ColumnName) = false then
          continue;
        Stmt.ColumnToVariant(J,rowData);
        SetPropValue(Result,ColumnName,rowData);
      end;
    end;
  finally
    Stmt.Destroy;
  end;

end;

function TMvcDBBase.FirstAsVariant(ASql:string ):Variant;
var
  Stmt:TSQLDBStatement;
begin
  Stmt:=FDbConnection.NewStatement;
  try
    Stmt.Execute(StringToUTF8(ASql),true);
    if(Stmt.Step()) then
    begin
      if(Stmt.ColumnCount > 0 ) then
      begin
        Stmt.ColumnToVariant(0,Result);
      end;
    end;
  finally
    Stmt.Destroy;
  end;
end;

function TMvcDBBase.FirstAsString(ASql:string ):String;
begin
  Result:=FirstAsVariant(ASql);
end;

function TMvcDBBase.FirstAsInteger(ASql:string ):Integer;
begin
  Result:=FirstAsVariant(ASql);
end;
function TMvcDBBase.FirstAsDouble(ASql:string ):Double;
begin
  Result:=FirstAsVariant(ASql);
end;

function TMvcDBBase.FirstAsLongInt(ASql:string ):LongInt;
begin
  Result:=FirstAsVariant(ASql);
end;

function TMvcDBBase.FirstAsDateTime(ASql:string ):TDateTime;
begin
  Result:=FirstAsVariant(ASql);
end;

procedure TMvcDBBase.BeginTransaction;
begin
  FDbConnection.StartTransaction;
end;

procedure TMvcDBBase.RollbackTransaction;
begin
  FDbConnection.Rollback;
end;
procedure TMvcDBBase.CommitTransaction;
begin
  FDbConnection.Commit;
end;
constructor TMvcDBBase.Create(ADbConnection:TSQLDBConnection);
begin
  inherited Create;
  if  not Assigned(ADbConnection) then
    raise Exception.Create('TSQLDBConnection is not intialized');

  if not Assigned(ADbConnection.Properties) then
    raise Exception.Create('TSQLDBConnection.Properties is not intialized');

  FDbType := DBTypeFromConnectionProperty(ADbConnection.Properties);
  if (FDbType = dbUnknown) then
    raise Exception.Create('Unknown DB Type');
  FDbConnection := ADbConnection;
end;

constructor TMVcDB<T>.Create(ADbConnection:TSQLDBConnection);
begin
  inherited Create(ADbConnection);
  FCurrentTableDetail:= TableDetail(T);
end;

function TMVcDB<T>.InsertColumnNamesAndValues(AObject:TObject):string;
var
  I: Integer;
  KeyEnum:TDictionary<string,TMvcDBColumnDetail>.TKeyEnumerator;
begin
  Result:=' ( ';
  KeyEnum := FCurrentTableDetail.Columns.Keys.GetEnumerator;

  I:=0;
  with KeyEnum do
  begin
    while MoveNext do
    begin
      if FCurrentTableDetail.Columns[Current].AutoIncrement or FCurrentTableDetail.Columns[Current].IgnoredColumn then
        Continue;
      try
        if (I > 0 ) then
          Result := Result + ' , ' + Current
        else
          Result := Result + '  ' + Current;
      except
      end;
      Inc(I);
    end;
  end;

  Result := Result + ' ) ';
  Result := Result + ' VALUES ( ';

  KeyEnum := FCurrentTableDetail.Columns.Keys.GetEnumerator;

  I:=0;
  with KeyEnum do
  begin
    while MoveNext do
    begin
      if FCurrentTableDetail.Columns[Current].AutoIncrement or FCurrentTableDetail.Columns[Current].IgnoredColumn then
        Continue;
      try
        if (I > 0 ) then
          Result := Result + ' , ' +  SqlString(FCurrentTableDetail.GetColumnValue(AObject, Current))
        else
          Result := Result + '  ' + SqlString(FCurrentTableDetail.GetColumnValue(AObject, Current));
      except
      end;
      Inc(I);
    end;
  end;

  Result := Result + ' ) '
end;

function TMVcDB<T>.GetInsertPrimaryKeyValueSQL(AObject:TObject):string;
begin
  Result:='';
  if (FCurrentTableDetail.PrimaryKeyColumnIsAutoIncrement = false) then
  begin
    exit;
  end;

  case FDbType of
    dbUnknown:
    begin
      Result := '';
    end;

    dbNativeSqlite:
    begin
      Result:='; SELECT last_insert_rowid();';
    end;

    dbNativeOracle,
    dbADOOracle,
    dbADOMsOracle :
    begin
      Result := Format(' returning %s into :newid', [FCurrentTableDetail.PrimaryKeyColumn]);
    end;

    dbADOPostgreSql:
    begin
      Result:= Format(' returning %s as NewID', [FCurrentTableDetail.PrimaryKeyColumn]);
    end;

    dbADOMsSqlCE:
    begin
      Result:= '; SELECT @@IDENTITY AS NewID;';
    end;

    dbADOMsSql:
    begin
      Result:= '; SELECT SCOPE_IDENTITY() AS NewID;';
    end;

    dbADOMySql:
    begin
      Result:= '; SELECT LAST_INSERT_ID() AS NewID;';
    end;

    dbADOAS400:
    begin
      Result := '';
    end;

  end;
end;


function TMVcDB<T>.UpdateColumnAndValues(AObject:TObject):string;
var
  I: Integer;
  KeyEnum:TDictionary<string,TMvcDBColumnDetail>.TKeyEnumerator;
begin
  Result:='';
  KeyEnum := FCurrentTableDetail.Columns.Keys.GetEnumerator;
  I:=0;
  with KeyEnum do
  begin
    while MoveNext do
    begin
      if FCurrentTableDetail.Columns[Current].AutoIncrement or FCurrentTableDetail.Columns[Current].IgnoredColumn then
        Continue;
      try
        if (I > 0 ) then
          Result := Result + ' , ' + Current + ' = ' + SqlString(FCurrentTableDetail.GetColumnValue(AObject, Current))
        else
          Result := Result + ' ' + Current + ' = ' + SqlString(FCurrentTableDetail.GetColumnValue(AObject, Current));
      except
      end;
      Inc(I);
    end;
  end;
  if Length(Result) > 0 then
    Result := ' SET ' + Result;
end;

function TMVcDB<T>.Insert(var AObject:T):LongInt;
var
  PrimaryKeySql:String;
begin
  PrimaryKeySql:=GetInsertPrimaryKeyValueSQL(AObject);
  result:= inherited Insert('INSERT INTO ' + FCurrentTableDetail.DBTableName + InsertColumnNamesAndValues(AObject), PrimaryKeySql);

  if (FCurrentTableDetail.PrimaryKeyColumn <> '') then
  begin
    SetPropValue(AObject,UTF8ToString(FCurrentTableDetail.PrimaryKeyColumn),result);
  end;
end;

function TMVcDB<T>.Update(var AObject:T):LongInt;
begin
  result:= Update('UPDATE ' + FCurrentTableDetail.DBTableName + UpdateColumnAndValues(AObject) + ' WHERE ' + SqlEqualValue(FCurrentTableDetail.PrimaryKeyColumn , FCurrentTableDetail.GetColumnValue(AObject,FCurrentTableDetail.PrimaryKeyColumn)));
end;

function TMVcDB<T>.Update(var AObject:T;AWhere:String):LongInt;
begin
  result:= Update('UPDATE ' + FCurrentTableDetail.DBTableName + UpdateColumnAndValues(AObject) + ' WHERE ' + AWhere);
end;

function TMVcDB<T>.Update(var AObject:TMvcList<T>):LongInt;
var
  I: Integer;
  ObjectToUpdate:T;
begin
  for I := 0 to AObject.Count -1 do
  begin
    ObjectToUpdate := AObject[I];
    Update(ObjectToUpdate);
    AObject[I] := ObjectToUpdate;
  end;
end;

function TMVcDB<T>.Update(AUpdateClause,AWhere:String):LongInt;
begin
  result:= Update('UPDATE ' + FCurrentTableDetail.DBTableName + ' SET ( ' +AUpdateClause +' ) ' +' WHERE ' + AWhere );
end;

function TMVcDB<T>.Delete(AObject:T):LongInt;
begin
  result:= Delete('DELETE FROM ' + FCurrentTableDetail.DBTableName + ' WHERE ' + SqlEqualValue(FCurrentTableDetail.PrimaryKeyColumn , FCurrentTableDetail.GetColumnValue(AObject,FCurrentTableDetail.PrimaryKeyColumn)));
end;

function TMVcDB<T>.Delete(AWhere:string):LongInt;
begin
  result:= Delete('DELETE FROM ' + FCurrentTableDetail.DBTableName + ' WHERE ' + AWhere);
end;

function TMVcDB<T>.DeleteById(APrimaryKey:TValue):LongInt;
begin
  result:= Delete('DELETE FROM ' + FCurrentTableDetail.DBTableName + ' WHERE ' + SqlEqualValue(FCurrentTableDetail.PrimaryKeyColumn ,APrimaryKey));
end;

function TMVcDB<T>.Exists(AWhere:string):boolean;
begin
  result:= FirstAsInteger('Count(*)',AWhere) > 0;
end;

function TMVcDB<T>.ExistsById(APrimaryKey:TValue):boolean;
begin
  result:= FirstAsInteger('Count(*)',SqlEqualValue(FCurrentTableDetail.PrimaryKeyColumn ,APrimaryKey) ) > 0;
end;

function TMVcDB<T>.Count(AWhere:string):Integer;
begin
  result:= FirstAsInteger('Count(*)',AWhere);
end;

function TMVcDB<T>.FirstById(APrimaryKey:TValue):T;
begin
  result:= inherited First<T>('SELECT * FROM ' + FCurrentTableDetail.DBTableName + ' WHERE ' + SqlEqualValue(FCurrentTableDetail.PrimaryKeyColumn ,APrimaryKey));
end;

function TMVcDB<T>.First(AWhere:string):T;
begin
  result:= inherited First<T>('SELECT * FROM ' + FCurrentTableDetail.DBTableName + ifthen(AWhere <>'', ' WHERE ' + AWhere,''));
end;

function TMVcDB<T>.FirstAsString(AColumn,AWhere:string ):String;
begin
  result:= FirstAsString('SELECT '+ AColumn+' FROM ' + FCurrentTableDetail.DBTableName + ifthen(AWhere <>'', ' WHERE ' + AWhere,''));
end;

function TMVcDB<T>.FirstAsInteger(AColumn,AWhere:string ):Integer;
begin
  result:= FirstAsInteger('SELECT '+ AColumn+' FROM ' + FCurrentTableDetail.DBTableName + ifthen(AWhere <>'', ' WHERE ' + AWhere,''));
end;

function TMVcDB<T>.FirstAsDouble(AColumn,AWhere:string ):Double;
begin
  result:= FirstAsDouble('SELECT '+ AColumn+' FROM ' + FCurrentTableDetail.DBTableName + ifthen(AWhere <>'', ' WHERE ' + AWhere,''));
end;

function TMVcDB<T>.FirstAsLongInt(AColumn,AWhere:string ):LongInt;
begin
  result:= FirstAsLongInt('SELECT '+ AColumn+' FROM ' + FCurrentTableDetail.DBTableName + ifthen(AWhere <>'', ' WHERE ' + AWhere,''));
end;

function TMVcDB<T>.FirstAsDateTime(AColumn,AWhere:string ):TDateTime;
begin
  result:= FirstAsDateTime('SELECT '+ AColumn+' FROM ' + FCurrentTableDetail.DBTableName + ifthen(AWhere <>'', ' WHERE ' + AWhere,''));
end;

function TMVcDB<T>.Select(AWhere:string ):TMvcList<T>;
begin
  result:= Select<T>('SELECT * FROM ' + FCurrentTableDetail.DBTableName + ifthen(AWhere <>'', ' WHERE ' + AWhere,''));
end;

function TMVcDB<T>.Page(APageNumber,APageSize:Integer;Where:string):TMvcList<T>;
begin

end;

initialization
  tableCache:=TMvcDBTableDetailsCache.Create();

finalization
  tableCache.Destroy;

end.
