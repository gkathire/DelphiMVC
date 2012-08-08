unit MvcDBCommon;

interface

uses Generics.Collections,TypInfo;

type
  TMvcDBType  = (dbUnknown,dbNativeSqlite,dbNativeOracle,dbADOOracle,dbADOMsOracle,dbADOMsSql,dbADOMsSqlCE,dbADOPostgreSql,dbADOMySql,dbADOAS400);
  TMvcDBTableName = class(TCustomAttribute)
  private
    FName:string;
    FSchema:string;
  public
    property Name:string read FName write FName;
    property Schema:string read FSchema write FSchema;
    constructor Create(AName, ASchema : string);
  end;

  TMvcDBColumnName = class(TCustomAttribute)
  private
    FName:string;
  public
    property Name:string read FName write FName;
    constructor Create(AName : string);
  end;

  TMvcDBPrimaryKeyColumn = class(TCustomAttribute)
  end;

  TMvcDBAutoIncrementColumn = class(TCustomAttribute)
  end;

  TMvcDBIgnoreColumn = class(TCustomAttribute)
  end;

  TMvcDBAutoUpdateDateColumn = class(TCustomAttribute)
  end;

  TMvcDBForeignKeyColumn = class(TCustomAttribute)
  private
    FReferenceTable:string;
    FReferenceColumn:string;
  public
    property ReferenceTable:string read FReferenceTable write FReferenceTable;
    property ReferenceColumn:string read FReferenceColumn write FReferenceColumn;
    constructor Create(AReferenceTable,AReferenceColumn: string);
  end;

  TMvcListFind<T : Class> = function (AItem: T): boolean;

  IMvcListInterface = interface['{1692E79A-4EE6-492F-A534-3A5D71AAB5DC}']
    function InnerClassTypeInfo:PTypeInfo;
  end;

  TMvcList<T:Class> = class(TInterfacedObject,IMvcListInterface)
  protected
    FList : TList<T>;
    function Find(Find: TMvcListFind<T>; var Found: integer):boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(AItem:T);
    procedure Delete(Index:Integer);
    function Count:Integer;
    function  GetItem(Index: integer): T;
    procedure PutItem(Index: integer; AItem: T);
    function InnerClassTypeInfo:PTypeInfo;
  public
    property Items[Index: integer]: T read GetItem write PutItem;default;
  end;


implementation

constructor TMvcDBForeignKeyColumn.Create(AReferenceTable,
  AReferenceColumn: string);
begin
  inherited Create;
  FReferenceTable := AReferenceTable;
  FReferenceColumn := AReferenceColumn
end;

constructor TMvcDBColumnName.Create(AName: string);
begin
  inherited Create;
  FName:=AName;
end;

constructor TMvcDBTableName.Create(AName, ASchema : string);
begin
  inherited Create;
  FName:=AName;
  FSchema:=ASchema;
end;

function TMvcList<T>.GetItem(Index: integer): T;
begin
  Result:=FList[Index];
end;

procedure TMvcList<T>.PutItem(Index: integer; AItem: T);
begin
  FList[Index] := AItem;
end;

destructor TMvcList<T>.Destroy;
var
  Index: integer;
begin
  FList.Destroy;
  inherited;
end;

function TMvcList<T>.InnerClassTypeInfo:PTypeInfo;
begin
  Result:=TypeInfo(T);
end;

constructor TMvcList<T>.Create;
begin
  inherited;
  FList := TList<T>.Create;
end;


function TMvcList<T>.Find(Find: TMvcListFind<T>; var Found: integer):boolean;
var
  Index: integer;
begin
  Result:=False;
{
  Found:=-1;
  for Index:=0 to Count - 1 do
    if Find(T(Get(Index))) then
    begin
      Result:=True;
      Found:=Index;
      Break;
    end;
}
end;

procedure TMvcList<T>.Add(AItem:T);
begin
  FList.Add(Pointer(T));
end;

procedure TMvcList<T>.Delete(Index:Integer);
begin
  FList.Delete(Index);
end;

function TMvcList<T>.Count:Integer;
begin
  Result:=FList.Count;
end;

end.
