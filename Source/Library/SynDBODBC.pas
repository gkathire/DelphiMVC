/// ODBC 3.5 library direct access classes to be used with our SynDB architecture
// - this unit is a part of the freeware Synopse mORMot framework,
// licensed under a MPL/GPL/LGPL tri-license; version 1.16
unit SynDBODBC;

{
    This file is part of Synopse mORMot framework.

    Synopse mORMot framework. Copyright (C) 2011 Arnaud Bouchez
      Synopse Informatique - http://synopse.info

  *** BEGIN LICENSE BLOCK *****
  Version: MPL 1.1/GPL 2.0/LGPL 2.1

  The contents of this file are subject to the Mozilla Public License Version
  1.1 (the "License"); you may not use this file except in compliance with
  the License. You may obtain a copy of the License at
  http://www.mozilla.org/MPL

  Software distributed under the License is distributed on an "AS IS" basis,
  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
  for the specific language governing rights and limitations under the License.

  The Original Code is Synopse mORMot framework.

  The Initial Developer of the Original Code is Arnaud Bouchez.

  Portions created by the Initial Developer are Copyright (C) 2011
  the Initial Developer. All Rights Reserved.

  Contributor(s):
  Alternatively, the contents of this file may be used under the terms of
  either the GNU General Public License Version 2 or later (the "GPL"), or
  the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
  in which case the provisions of the GPL or the LGPL are applicable instead
  of those above. If you wish to allow use of your version of this file only
  under the terms of either the GPL or the LGPL, and not to allow others to
  use your version of this file under the terms of the MPL, indicate your
  decision by deleting the provisions above and replace them with the notice
  and other provisions required by the GPL or the LGPL. If you do not delete
  the provisions above, a recipient may use your version of this file under
  the terms of any one of the MPL, the GPL or the LGPL.

  ***** END LICENSE BLOCK *****

  Version 1.16
  - first public release, corresponding to mORMot Framework 1.16

}

{$I Synopse.inc} // define HASINLINE USETYPEINFO CPU32 CPU64 OWNNORMTOUPPER

interface

uses
  Windows,
  SysUtils,
{$ifndef DELPHI5OROLDER}
  Variants,
{$endif}
  Classes,
  Contnrs,
  SynCommons,
  SynDB;


{ -------------- ODBC library interfaces, constants and types }

type
  SqlSmallint = Smallint;
  SqlDate = Byte;
  SqlTime = Byte;
  SqlDecimal = Byte;
  SqlDouble = Double;
  SqlFloat = Double;
  SqlInteger = integer;
  SqlUInteger = cardinal;
  SqlNumeric = Byte;
  SqlPointer = Pointer;
  SqlReal = Single;
  SqlUSmallint = Word;
  SqlTimestamp = Byte;
  SqlVarchar = Byte;
  PSqlSmallint = ^SqlSmallint;
  PSqlInteger = ^SqlInteger;

  SqlReturn = SqlSmallint;
  SqlLen = PtrInt;
  SqlULen = PtrUInt;
  {$ifdef CPU64}
  SqlSetPosIRow = PtrUInt;
  {$else}
  SqlSetPosIRow = Word;
  {$endif}
  PSqlLen = ^SqlLen;

  SqlHandle = Pointer;
  SqlHEnv = SqlHandle;
  SqlHDbc = SqlHandle;
  SqlHStmt = SqlHandle;
  SqlHDesc = SqlHandle;

  /// direct access to the ODBC library
  // - this wrapper will initialize both Ansi and Wide versions of the ODBC
  // driver functions, and will work with 32 bit and 64 bit version of the
  // interfaces, on Windows or POSIX platforms
  // - within this unit, we will only use Wide version, and UTF-8 conversion
  TSQLDBODBCLib = class(TSQLDBLib)
  public
    AllocConnect: function(EnvironmentHandle: SqlHEnv; var ConnectionHandle: SqlHDbc): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    AllocEnv: function (var EnvironmentHandle: SqlHEnv): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    AllocHandle: function(HandleType: SqlSmallint; InputHandle: SqlHandle;
      var OutputHandle: SqlHandle): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    AllocStmt: function(ConnectionHandle: SqlHDbc; var StatementHandle: SqlHStmt): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    BindCol: function(StatementHandle: SqlHStmt; ColumnNumber: SqlUSmallint;
      TargetType: SqlSmallint; TargetValue: SqlPointer;
      BufferLength: SqlLen; StrLen_or_Ind: PSqlLen): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    BindParam: function (StatementHandle: SqlHStmt;
      ParameterNumber: SqlUSmallint; ValueType: SqlSmallint;
      ParameterType: SqlSmallint; LengthPrecision: SqlULen;
      ParameterScale: SqlSmallint; ParameterValue: SqlPointer;
      var StrLen_or_Ind: SqlLen): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    Cancel: function(StatementHandle: SqlHStmt): SqlReturn;

      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    CloseCursor: function(StatementHandle: SqlHStmt): SqlReturn;
    
 {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    ColAttributeA: function(StatementHandle: SqlHStmt; ColumnNumber: SqlUSmallint;
      FieldIdentifier: SqlUSmallint; CharacterAttribute: PAnsiChar;
      BufferLength: SqlSmallint; StringLength: PSqlSmallint; NumericAttributePtr: PSqlLen): SqlReturn;

      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    ColAttributeW: function(StatementHandle: SqlHStmt; ColumnNumber: SqlUSmallint;
      FieldIdentifier: SqlUSmallint; CharacterAttribute: PWideChar;
      BufferLength: SqlSmallint; StringLength: PSqlSmallint; NumericAttributePtr: PSqlLen): SqlReturn;

       {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    ColumnsA: function(StatementHandle: SqlHStmt;
      CatalogName: PAnsiChar; NameLength1: SqlSmallint;
      SchemaName: PAnsiChar;  NameLength2: SqlSmallint;
      TableName: PAnsiChar;   NameLength3: SqlSmallint;
      ColumnName: PAnsiChar;  NameLength4: SqlSmallint): SqlReturn;

      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    ColumnsW: function(StatementHandle: SqlHStmt;
      CatalogName: PWideChar; NameLength1: SqlSmallint;
      SchemaName: PWideChar;  NameLength2: SqlSmallint;
      TableName: PWideChar;   NameLength3: SqlSmallint;
      ColumnName: PWideChar;  NameLength4: SqlSmallint): SqlReturn;

      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    ConnectA: function(ConnectionHandle: SqlHDbc;
      ServerName: PAnsiChar; NameLength1: SqlSmallint;
      UserName: PAnsiChar; NameLength2: SqlSmallint;
      Authentication: PAnsiChar; NameLength3: SqlSmallint): SqlReturn;

      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    ConnectW: function(ConnectionHandle: SqlHDbc;
      ServerName: PWideChar; NameLength1: SqlSmallint;
      UserName: PWideChar; NameLength2: SqlSmallint;
      Authentication: PWideChar; NameLength3: SqlSmallint): SqlReturn;

      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    CopyDesc: function(SourceDescHandle, TargetDescHandle: SqlHDesc): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    DataSourcesA: function(EnvironmentHandle: SqlHEnv; Direction: SqlUSmallint;
      ServerName: PAnsiChar;  BufferLength1: SqlSmallint; var NameLength1: SqlSmallint;
      Description: PAnsiChar; BufferLength2: SqlSmallint; var NameLength2: SqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    DataSourcesW: function(EnvironmentHandle: SqlHEnv; Direction: SqlUSmallint;
      ServerName: PWideChar;  BufferLength1: SqlSmallint; var NameLength1: SqlSmallint;
      Description: PWideChar; BufferLength2: SqlSmallint; var NameLength2: SqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    DescribeColA: function(StatementHandle: SqlHStmt; ColumnNumber: SqlUSmallint;
      ColumnName: PAnsiChar; BufferLength: SqlSmallint; var NameLength: SqlSmallint;
      var DataType: SqlSmallint; var ColumnSize: SqlULen; var DecimalDigits: SqlSmallint;
      var Nullable: SqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    DescribeColW: function(StatementHandle: SqlHStmt; ColumnNumber: SqlUSmallint;
      ColumnName: PWideChar; BufferLength: SqlSmallint; var NameLength: SqlSmallint;
      var DataType: SqlSmallint; var ColumnSize: SqlULen; var DecimalDigits: SqlSmallint;
      var Nullable: SqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    Disconnect: function(ConnectionHandle: SqlHDbc): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    EndTran: function(HandleType: SqlSmallint; Handle: SqlHandle;
      CompletionType: SqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    ErrorA: function(EnvironmentHandle: SqlHEnv; ConnectionHandle: SqlHDbc; StatementHandle: SqlHStmt;
      Sqlstate: PAnsiChar; var NativeError: SqlInteger;
      MessageText: PAnsiChar; BufferLength: SqlSmallint; var TextLength: SqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    ErrorW: function(EnvironmentHandle: SqlHEnv; ConnectionHandle: SqlHDbc; StatementHandle: SqlHStmt;
      Sqlstate: PWideChar; var NativeError: SqlInteger;
      MessageText: PWideChar; BufferLength: SqlSmallint; var TextLength: SqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    ExecDirectA: function(StatementHandle: SqlHStmt;
      StatementText: PAnsiChar; TextLength: SqlInteger): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    ExecDirectW: function(StatementHandle: SqlHStmt;
      StatementText: PWideChar; TextLength: SqlInteger): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    Execute: function(StatementHandle: SqlHStmt): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    Fetch: function(StatementHandle: SqlHStmt): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    FetchScroll: function(StatementHandle: SqlHStmt;
      FetchOrientation: SqlSmallint; FetchOffset: SqlLen): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    FreeConnect: function(ConnectionHandle: SqlHDbc): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    FreeEnv: function(EnvironmentHandle: SqlHEnv): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    FreeHandle: function(HandleType: SqlSmallint; Handle: SqlHandle): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    FreeStmt: function(StatementHandle: SqlHStmt; Option: SqlUSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    GetConnectAttrA: function(ConnectionHandle: SqlHDbc; Attribute: SqlInteger;
      ValuePtr: SqlPointer; BufferLength: SqlInteger; pStringLength: pSqlInteger): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    GetConnectAttrW: function(ConnectionHandle: SqlHDbc; Attribute: SqlInteger;
      ValuePtr: SqlPointer; BufferLength: SqlInteger; pStringLength: pSqlInteger): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    GetCursorNameA: function(StatementHandle: SqlHStmt;
      CursorName: PAnsiChar; BufferLength: SqlSmallint; var NameLength: SqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    GetCursorNameW: function(StatementHandle: SqlHStmt;
      CursorName: PWideChar; BufferLength: SqlSmallint; var NameLength: SqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    GetData: function(StatementHandle: SqlHStmt; ColumnNumber: SqlUSmallint;
      TargetType: SqlSmallint; TargetValue: SqlPointer; BufferLength: SqlLen;
      StrLen_or_Ind: PSqlLen): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    GetDescFieldA: function(DescriptorHandle: SqlHDesc; RecNumber: SqlSmallint;
      FieldIdentifier: SqlSmallint; Value: SqlPointer; BufferLength: SqlInteger;
      var StringLength: SqlInteger): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    GetDescFieldW: function(DescriptorHandle: SqlHDesc; RecNumber: SqlSmallint;
      FieldIdentifier: SqlSmallint; Value: SqlPointer; BufferLength: SqlInteger;
      var StringLength: SqlInteger): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    GetDescRecA: function(DescriptorHandle: SqlHDesc; RecNumber: SqlSmallint;
      Name: PAnsiChar; BufferLength: SqlSmallint; var StringLength: SqlSmallint;
      var _Type, SubType: SqlSmallint; var Length: SqlLen;
      var Precision, Scale, Nullable: SqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    GetDescRecW: function(DescriptorHandle: SqlHDesc; RecNumber: SqlSmallint;
      Name: PWideChar; BufferLength: SqlSmallint; var StringLength: SqlSmallint;
      var _Type, SubType: SqlSmallint; var Length: SqlLen;
      var Precision, Scale, Nullable: SqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    GetDiagFieldA: function(HandleType: SqlSmallint; Handle: SqlHandle;
      RecNumber, DiagIdentifier: SqlSmallint;
      DiagInfo: SqlPointer; BufferLength: SqlSmallint; var StringLength: SqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    GetDiagFieldW: function(HandleType: SqlSmallint; Handle: SqlHandle;
      RecNumber, DiagIdentifier: SqlSmallint;
      DiagInfo: SqlPointer; BufferLength: SqlSmallint; var StringLength: SqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    GetDiagRecA: function(HandleType: SqlSmallint; Handle: SqlHandle; RecNumber: SqlSmallint;
      Sqlstate: PAnsiChar; var NativeError: SqlInteger;
      MessageText: PAnsiChar; BufferLength: SqlSmallint; var TextLength: SqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    GetDiagRecW: function(HandleType: SqlSmallint; Handle: SqlHandle; RecNumber: SqlSmallint;
      Sqlstate: PWideChar; var NativeError: SqlInteger;
      MessageText: PWideChar; BufferLength: SqlSmallint; var TextLength: SqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    PrepareA: function(StatementHandle: SqlHStmt;
      StatementText: PAnsiChar; TextLength: SqlInteger): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    PrepareW: function(StatementHandle: SqlHStmt;
      StatementText: PWideChar; TextLength: SqlInteger): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    RowCount: function(StatementHandle: SqlHStmt; var RowCount: SqlLen): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    NumResultCols: function(StatementHandle: SqlHStmt; var ColumnCount: SqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    GetInfoA: function(ConnectionHandle: SqlHDbc; InfoType: SqlUSmallint;
      InfoValuePtr: SqlPointer; BufferLength: SqlSmallint; StringLengthPtr: PSqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    GetInfoW: function(ConnectionHandle: SqlHDbc; InfoType: SqlUSmallint;
      InfoValuePtr: SqlPointer; BufferLength: SqlSmallint; StringLengthPtr: PSqlSmallint): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    SetStmtAttrA: function(StatementHandle: SqlHStmt; Attribute: SqlInteger;
      Value: SqlPointer; StringLength: SqlInteger): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    SetStmtAttrW: function(StatementHandle: SqlHStmt; Attribute: SqlInteger;
      Value: SqlPointer; StringLength: SqlInteger): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    SetEnvAttr: function(EnvironmentHandle: SqlHEnv; Attribute: SqlInteger;
      ValuePtr: SqlPointer; StringLength: SqlInteger): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    SetConnectAttrA: function(ConnectionHandle: SqlHDbc; Attribute: SqlInteger;
      ValuePtr: SqlPointer; StringLength: SqlInteger): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
    SetConnectAttrW: function(ConnectionHandle: SqlHDbc; Attribute: SqlInteger;
      ValuePtr: SqlPointer; StringLength: SqlInteger): SqlReturn;
      {$ifdef MSWINDOWS} stdcall {$else} cdecl {$endif};
  end;

const
  ODBC_ENTRIES: array[0..55] of PChar =
    ('SQLAllocConnect','SQLAllocEnv','SQLAllocHandle','SQLAllocStmt',
     'SQLBindCol','SQLBindParam','SQLCancel','SQLCloseCursor',
     'SQLColAttribute','SQLColAttributeW','SQLColumns','SQLColumnsW',
     'SQLConnect','SQLConnectW','SQLCopyDesc','SQLDataSources','SQLDataSourcesW',
     'SQLDescribeCol','SQLDescribeColW','SQLDisconnect','SQLEndTran',
     'SQLError','SQLErrorW','SQLExecDirect','SQLExecDirectW','SQLExecute',
     'SQLFetch','SQLFetchScroll','SQLFreeConnect','SQLFreeEnv','SQLFreeHandle',
     'SQLFreeStmt','SQLGetConnectAttr','SQLGetConnectAttrW',
     'SQLGetCursorName','SQLGetCursorNameW','SQLGetData',
     'SQLGetDescField','SQLGetDescFieldW','SQLGetDescRec','SQLGetDescRecW',
     'SQLGetDiagField','SQLGetDiagFieldW','SQLGetDiagRec','SQLGetDiagRecW',
     'SQLPrepare','SQLPrepareW','SQLRowCount','SQLNumResultCols',
     'SQLGetInfo','SQLGetInfoW','SQLSetStmtAttr','SQLSetStmtAttrW','SQLSetEnvAttr',
     'SQLSetConnectAttr','SQLSetConnectAttrW');


{ -------------- TSQLDBODBC* classes and types implementing an ODBC library connection  }

type
  /// will implement properties shared by the ODBC library
  TSQLDBODBCConnectionProperties = class(TSQLDBConnectionProperties)
  protected
    /// get all table names of this ODBC database
    function SQLGetTableNames: RawUTF8; override;
    /// convert a textual column data type, as retrieved e.g. from SQLGetField,
    // into our internal primitive types
    function ColumnTypeNativeToDB(const aNativeType: RawUTF8; aScale: integer): TSQLDBFieldType; override;
    /// initialize fForeignKeys content with all foreign keys of this DB
    // - used by GetForeignKey method
    procedure GetForeignKeys; override;
  public
    /// initialize the properties
    // - only used parameter is aServerName, which should point to the ODBC
    // database file to be opened (one will be created if none exists)
    // - other parameters (DataBaseName, UserID, Password) are ignored
    constructor Create(const aServerName, aDatabaseName, aUserID, aPassWord: RawUTF8); override;
    /// create a new connection
    // - call this method if the shared MainConnection is not enough (e.g. for
    // multi-thread access)
    // - the caller is responsible of freeing this instance
    function NewConnection: TSQLDBConnection; override;
    /// convert an ISO-8601 encoded time and date into a date appropriate to
    // be pasted in the SQL request
    // - returns 'YYYY-MM-DD HH24:MI:SS' i.e. change the in-between 'T' into ' '
    function SQLIso8601ToDate(const Iso8601: RawUTF8): RawUTF8; override;
    /// retrieve the column/field layout of a specified table
    // - this overriden method will call PRAGMA table_info()
    // - used e.g. by GetFieldDefinitions
    procedure GetFields(const aTableName: RawUTF8; var Fields: TSQLDBColumnDefineDynArray); override;
  end;

  /// implements a direct connection to the ODBC library
  TSQLDBODBCConnection = class(TSQLDBConnection)
  protected
    function IsConnected: boolean; override;
  public
    /// release internal memory, handles and statement cache
    destructor Destroy; override;
    /// connect to the ODBC library, i.e. create the DB instance
    // - should raise an Exception on error
    procedure Connect; override;
    /// stop connection to the ODBC library, i.e. release the DB instance
    // - should raise an Exception on error
    procedure Disconnect; override;
    /// initialize a new SQL query statement for the given connection
    // - the caller should free the instance after use
    function NewStatement: TSQLDBStatement; override;
    /// begin a Transaction for this connection
    // - current implementation do not support nested transaction with those
    // methods: exception will be raised in such case
    procedure StartTransaction; override;
    /// commit changes of a Transaction for this connection
    // - StartTransaction method must have been called before
    procedure Commit; override;
    /// discard changes of a Transaction for this connection
    // - StartTransaction method must have been called before
    procedure Rollback; override;
  end;

  /// implements a statement using a ODBC connection
  TSQLDBODBCStatement = class(TSQLDBStatement)
  protected
    {{ retrieve the inlined value of a given parameter, e.g. 1 or 'name' }
    function GetParamValueAsText(Param: integer): RawUTF8; override;
  public
    {{ create a ODBC statement instance, from an existing ODBC connection
     - the Execute method can be called once per TSQLDBODBCStatement instance,
       but you can use the Prepare once followed by several ExecutePrepared methods
     - if the supplied connection is not of TOleDBConnection type, will raise
       an exception }
    constructor Create(aConnection: TSQLDBConnection); override;
    {{ release all associated memory and ODBC handles }
    destructor Destroy; override;

    {{ bind a NULL value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindNull(Param: Integer; IO: TSQLDBParamInOutType=paramIn); override;
    {{ bind an integer value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure Bind(Param: Integer; Value: Int64;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a double value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure Bind(Param: Integer; Value: double;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a TDateTime value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindDateTime(Param: Integer; Value: TDateTime;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a currency value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindCurrency(Param: Integer; Value: currency;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a UTF-8 encoded string to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextU(Param: Integer; const Value: RawUTF8;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a UTF-8 encoded buffer text (#0 ended) to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextP(Param: Integer; Value: PUTF8Char;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a UTF-8 encoded string to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextS(Param: Integer; const Value: string;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a UTF-8 encoded string to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextW(Param: Integer; const Value: WideString;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a Blob buffer to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindBlob(Param: Integer; Data: pointer; Size: integer;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a Blob buffer to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindBlob(Param: Integer; const Data: RawByteString;
      IO: TSQLDBParamInOutType=paramIn); overload; override;

    {{ Prepare an UTF-8 encoded SQL statement
     - parameters marked as ? will be bound later, before ExecutePrepared call
     - if ExpectResults is TRUE, then Step() and Column*() methods are available
       to retrieve the data rows
     - raise an ESQLDBException on any error }
    procedure Prepare(const aSQL: RawUTF8; ExpectResults: Boolean=false); overload; override;
    {{ Execute a prepared SQL statement
     - parameters marked as ? should have been already bound with Bind*() functions
     - raise an ESQLDBException on any error }
    procedure ExecutePrepared; override;

    {{ Access the next or first row of data from the SQL Statement result
     - return true on success, with data ready to be retrieved by Column*() methods
     - return false if no more row is available (e.g. if the SQL statement
      is not a SELECT but an UPDATE or INSERT command)
     - if SeekFirst is TRUE, will put the cursor on the first row of results
     - raise an ESQLDBException on any error }
    function Step(SeekFirst: boolean=false): boolean; override;
    {{ retrieve a column name of the current Row
     - Columns numeration (i.e. Col value) starts with 0
     - it's up to the implementation to ensure than all column names are unique }
    function ColumnName(Col: integer): RawUTF8; override;
    {{ returns the Column index of a given Column name
     - Columns numeration (i.e. Col value) starts with 0
     - returns -1 if the Column name is not found (via case insensitive search) }
    function ColumnIndex(const aColumnName: RawUTF8): integer; override;
    {{ the Column type of the current Row
     - ftCurrency type should be handled specificaly, for faster process and
     avoid any rounding issue, since currency is a standard OleDB type }
    function ColumnType(Col: integer): TSQLDBFieldType; override;
    {{ Reset the previous prepared statement }
    procedure Reset; override;
    {{ returns TRUE if the column contains NULL }
    function ColumnNull(Col: integer): boolean; override;
    {{ return a Column integer value of the current Row, first Col is 0 }
    function ColumnInt(Col: integer): Int64; override;
    {{ return a Column floating point value of the current Row, first Col is 0 }
    function ColumnDouble(Col: integer): double; override;
    {{ return a Column floating point value of the current Row, first Col is 0 }
    function ColumnDateTime(Col: integer): TDateTime; override;
    {{ return a Column currency value of the current Row, first Col is 0
     - should retrieve directly the 64 bit Currency content, to avoid
     any rounding/conversion error from floating-point types }
    function ColumnCurrency(Col: integer): currency; override;
    {{ return a Column UTF-8 encoded text value of the current Row, first Col is 0 }
    function ColumnUTF8(Col: integer): RawUTF8; override;
    {{ return a Column as a blob value of the current Row, first Col is 0
    - ColumnBlob() will return the binary content of the field is was not ftBlob,
      e.g. a 8 bytes RawByteString for a vtInt64/vtDouble/vtDate/vtCurrency,
      or a direct mapping of the RawUnicode  }
    function ColumnBlob(Col: integer): RawByteString; override;
    {{ append all columns values of the current Row to a JSON stream
     - will use WR.Expand to guess the expected output format
     - fast overriden implementation with no temporary variable 
     - BLOB field value is saved as Base64, in the '"\uFFF0base64encodedbinary"
       format and contains true BLOB data }
    procedure ColumnsToJSON(WR: TJSONWriter); override;
  end;

  
implementation

{ TSQLDBODBCConnectionProperties }

function TSQLDBODBCConnectionProperties.ColumnTypeNativeToDB(
  const aNativeType: RawUTF8; aScale: integer): TSQLDBFieldType;
const
  PCHARS: array[0..21] of PUTF8Char = (
    'TEXT COLLATE ISO8601','TIME','DATE', 'INT','BIGINT',
    'TEXT','CBLO','CHAR','NCHAR','VARCHAR','NVARCHAR',
    'DOUBLE','NUMBER','FLOAT', 'MONEY','CURR', 'NULL',
    'BLOB','VARRAW','RAW','LONG RAW','LONG VARRAW');
  TYPES: array[-1..high(PCHARS)] of TSQLDBFieldType = (
    ftUnknown, ftDate,ftDate,ftDate, ftInt64,ftInt64,
    ftUTF8,ftUTF8,ftUTF8,ftUTF8,ftUTF8,ftUTF8,
    ftDouble,ftDouble,ftDouble, ftCurrency,ftCurrency, ftNull,
    ftBlob,ftBlob,ftBlob,ftBlob,ftBlob);
begin
  result := TYPES[IdemPCharArray(pointer(aNativeType),PCHARS)];
end;

constructor TSQLDBODBCConnectionProperties.Create(const aServerName,
  aDatabaseName, aUserID, aPassWord: RawUTF8);
const
  ODBC_FIELDS: TSQLDBFieldTypeDefinition = (
  ' TEXT COLLATE SYSTEMNOCASE',' INTEGER',' FLOAT',' FLOAT',
  ' TEXT COLLATE ISO8601',' TEXT COLLATE SYSTEMNOCASE',' BLOB');
  // ftNull, ftInt64, ftDouble, ftCurrency, ftDate, ftUTF8, ftBlob
begin
  inherited Create(aServerName,aDatabaseName,aUserID,aPassWord);
  fSQLCreateField := ODBC_FIELDS;
  fSQLCreateFieldMax := 0; // ODBC doesn't expect any field length
end;

procedure TSQLDBODBCConnectionProperties.GetFields(
  const aTableName: RawUTF8; var Fields: TSQLDBColumnDefineDynArray);
var n, i: integer;
    F: TSQLDBColumnDefine;
    FA: TDynArray;
begin
  FA.Init(TypeInfo(TSQLDBColumnDefineDynArray),Fields,@n);
  FA.Compare := SortDynArrayAnsiStringI; // FA.Find() case insensitive
  fillchar(F,sizeof(F),0);
  with Execute(FormatUTF8('PRAGMA table_info(%)',[aTableName]),[]) do
  while Step do begin
    // cid,name,type,notnull,dflt_value,pk
    F.ColumnName := ColumnUTF8(1);
    F.ColumnTypeNative := ColumnUTF8(2);
    F.ColumnType := ColumnTypeNativeToDB(F.ColumnTypeNative,0);
    FA.Add(F);
  end;
  with Execute(FormatUTF8('PRAGMA index_list(%)',[aTableName]),[]) do
    while Step do
      // seq,name,unique
      with Execute(FormatUTF8('PRAGMA index_info(%)',[ColumnUTF8(1)]),[]) do
        while Step do begin
          F.ColumnName := ColumnUTF8(2); // seqno,cid,name
          i := FA.Find(F);
          if i>=0 then
            Fields[i].ColumnIndexed := true;
        end;
  SetLength(Fields,n);
end;

procedure TSQLDBODBCConnectionProperties.GetForeignKeys;
begin
  // do nothing (yet)
end;

function TSQLDBODBCConnectionProperties.NewConnection: TSQLDBConnection;
begin
  result := TSQLDBODBCConnection.Create(self);
end;

function TSQLDBODBCConnectionProperties.SQLGetTableNames: RawUTF8;
begin
  // TBD
end;

function TSQLDBODBCConnectionProperties.SQLIso8601ToDate(const Iso8601: RawUTF8): RawUTF8;
begin
  result := Iso8601;
  if length(result)>10 then
    result[11] := ' '; // 'T' -> ' '
end;


{ TSQLDBODBCConnection }

procedure TSQLDBODBCConnection.Commit;
begin
  inherited Commit;
  // TBD
end;

procedure TSQLDBODBCConnection.Connect;
var Log: ISynLog;
begin
  Log := SynDBLog.Enter;
  if self=nil then
    raise ESQLDBException.Create('Invalid Connect call');
  Disconnect; // force fTrans=fError=fServer=fContext=nil
  // TBD
end;

destructor TSQLDBODBCConnection.Destroy;
begin
  // TBD
  inherited;
end;

procedure TSQLDBODBCConnection.Disconnect;
begin
  // TBD
end;

function TSQLDBODBCConnection.IsConnected: boolean;
begin
  // TBD
//  result := (self<>nil) and (fDB<>nil);
end;

function TSQLDBODBCConnection.NewStatement: TSQLDBStatement;
begin
  result := TSQLDBODBCStatement.Create(self);
end;

procedure TSQLDBODBCConnection.Rollback;
begin
  inherited;
  // TBD
end;

procedure TSQLDBODBCConnection.StartTransaction;
begin
  inherited;
  // TBD
end;


{ TSQLDBODBCStatement }

procedure TSQLDBODBCStatement.Bind(Param: Integer; Value: double;
  IO: TSQLDBParamInOutType);
begin
  // TBD
{  if fBindShouldStoreValue and (cardinal(Param-1)<cardinal(fParamCount)) then
    fBindValues[Param-1] := DoubleToStr(Value,15);
  fStatement.Bind(Param,Value);}
end;

procedure TSQLDBODBCStatement.Bind(Param: Integer; Value: Int64;
  IO: TSQLDBParamInOutType);
begin
  // TBD
{  if fBindShouldStoreValue and (cardinal(Param-1)<cardinal(fParamCount)) then
    fBindValues[Param-1] := Int64ToUtf8(Value);
  fStatement.Bind(Param,Value); }
end;

procedure TSQLDBODBCStatement.BindBlob(Param: Integer; Data: pointer;
  Size: integer; IO: TSQLDBParamInOutType);
begin
  // TBD
{  if fBindShouldStoreValue and (cardinal(Param-1)<cardinal(fParamCount)) then
    fBindValues[Param-1] := '*BLOB*';
  fStatement.Bind(Param,Data,Size);}
end;

procedure TSQLDBODBCStatement.BindBlob(Param: Integer;
  const Data: RawByteString; IO: TSQLDBParamInOutType);
begin
  // TBD
//  fStatement.Bind(Param,pointer(Data),length(Data));
end;

procedure TSQLDBODBCStatement.BindCurrency(Param: Integer;
  Value: currency; IO: TSQLDBParamInOutType);
begin
  // TBD
{  if fBindShouldStoreValue and (cardinal(Param-1)<cardinal(fParamCount)) then
    fBindValues[Param-1] := Curr64ToStr(PInt64(@Value)^);
  fStatement.Bind(Param,Value);}
end;

procedure TSQLDBODBCStatement.BindDateTime(Param: Integer;
  Value: TDateTime; IO: TSQLDBParamInOutType);
begin
  // TBD
end;
{var tmp: RawUTF8;
begin
  tmp := DateTimeToIso8601(Value,True,'T');
  if fBindShouldStoreValue and (cardinal(Param-1)<cardinal(fParamCount)) then
    fBindValues[Param-1] := tmp;
  fStatement.Bind(Param,tmp);
end;}

procedure TSQLDBODBCStatement.BindNull(Param: Integer;
  IO: TSQLDBParamInOutType);
begin
  // TBD
end;

procedure TSQLDBODBCStatement.BindTextP(Param: Integer;
  Value: PUTF8Char; IO: TSQLDBParamInOutType);
begin
  // TBD
end;
{var Len: integer;
begin
  Len := StrLen(Value);
  if fBindShouldStoreValue and (cardinal(Param-1)<cardinal(fParamCount)) then
    SetString(fBindValues[Param-1],PAnsiChar(Value),Len);
  ODBC_check(fStatement.RequestDB,
    ODBC_bind_text(fStatement.Request,Param,pointer(Value),Len,
    SQLITE_TRANSIENT)); // make private copy of the data
end;}

procedure TSQLDBODBCStatement.BindTextS(Param: Integer;
  const Value: string; IO: TSQLDBParamInOutType);
begin
  BindTextU(Param,StringToUTF8(Value));
end;

procedure TSQLDBODBCStatement.BindTextU(Param: Integer;
  const Value: RawUTF8; IO: TSQLDBParamInOutType);
begin
  // TBD
end;
{begin
  if fBindShouldStoreValue and (cardinal(Param-1)<cardinal(fParamCount)) then
    fBindValues[Param-1] := Value;
  fStatement.Bind(Param,Value);
end;}

procedure TSQLDBODBCStatement.BindTextW(Param: Integer;
  const Value: WideString; IO: TSQLDBParamInOutType);
begin
  BindTextU(Param,WideStringToUTF8(Value));
end;

function TSQLDBODBCStatement.ColumnBlob(Col: integer): RawByteString;
begin
  // TBD
end;
{begin
  result := fStatement.FieldBlob(Col);
end;}

function TSQLDBODBCStatement.ColumnCurrency(Col: integer): currency;
begin
  // TBD
end;

function TSQLDBODBCStatement.ColumnDateTime(Col: integer): TDateTime;
begin
  // TBD
end;
{var Time: Iso8601;
begin
  case ColumnType(Col) of
  ftUTF8:
    result := Iso8601ToDateTime(fStatement.FieldUTF8(Col));
  ftInt64: begin
    Time.Value := fStatement.FieldInt(Col);
    result := Time.ToDateTime;
  end;
  else result := 0;
  end;
end;}

function TSQLDBODBCStatement.ColumnDouble(Col: integer): double;
begin
  // TBD
end;
{begin
  result := fStatement.FieldDouble(Col);
end;}

function TSQLDBODBCStatement.ColumnIndex(const aColumnName: RawUTF8): integer;
begin
  // TBD
end;
{begin
  result := fStatement.FieldIndex(aColumnName);
end;}

function TSQLDBODBCStatement.ColumnInt(Col: integer): Int64;
begin
  // TBD
end;
{begin
  result := fStatement.FieldInt(Col);
end;}

function TSQLDBODBCStatement.ColumnName(Col: integer): RawUTF8;
begin
  // TBD
end;
{begin
  result := fStatement.FieldName(Col);
end;}

function TSQLDBODBCStatement.ColumnNull(Col: integer): boolean;
begin
  // TBD
end;
{begin
  result := fStatement.FieldNull(Col);
end;}

procedure TSQLDBODBCStatement.ColumnsToJSON(WR: TJSONWriter);
begin
  // TBD
end;
{begin
  fStatement.FieldsToJSON(WR);
end;}

function TSQLDBODBCStatement.ColumnType(Col: integer): TSQLDBFieldType;
begin
  // TBD
end;
{begin
  case fStatement.FieldType(Col) of
  SQLITE_NULL:    result := ftNull;
  SQLITE_INTEGER: result := ftInt64;
  SQLITE_FLOAT:   result := ftDouble;
  SQLITE_TEXT:    result := ftUTF8;
  SQLITE_BLOB:    result := ftBlob;
  else            result := ftUnknown;
  end;
end;}

function TSQLDBODBCStatement.ColumnUTF8(Col: integer): RawUTF8;
begin
  // TBD
end;
{begin
  result := fStatement.FieldUTF8(Col);
end;}

constructor TSQLDBODBCStatement.Create(aConnection: TSQLDBConnection);
begin
  if not aConnection.InheritsFrom(TSQLDBODBCConnection) then
    raise ESQLDBException.CreateFmt('%s.Create expects a TSQLDBODBCConnection',[ClassName]);
  inherited Create(aConnection);
end;

destructor TSQLDBODBCStatement.Destroy;
begin
  // TBD
  inherited Destroy;
end;

procedure TSQLDBODBCStatement.ExecutePrepared;
begin
  // TBD
end;
{begin
  if not fExpectResults then
    // INSERT/UPDATE/DELETE (i.e. not SELECT) -> try to execute directly now
    repeat // Execute all steps of the first statement
    until fStatement.Step<>SQLITE_ROW;
end;}

function TSQLDBODBCStatement.GetParamValueAsText(Param: integer): RawUTF8;
begin
  // TBD
end;
{begin
  if not fBindShouldStoreValue or (cardinal(Param-1)>=cardinal(fParamCount)) then
    result := '' else
    result := fBindValues[Param-1];
end;}

procedure TSQLDBODBCStatement.Prepare(const aSQL: RawUTF8;
  ExpectResults: Boolean);
begin
  // TBD
end;
{begin
  inherited Prepare(aSQL,ExpectResults); // set fSQL + Connect if necessary
  fStatement.Prepare(TSQLDBODBCConnection(Connection).fDB.DB,aSQL);
  AfterPrepare;
end;}

procedure TSQLDBODBCStatement.Reset;
begin
  // TBD
end;
{begin
  fStatement.Reset;
  fStatement.BindReset;
end;}

function TSQLDBODBCStatement.Step(SeekFirst: boolean): boolean;
begin
  // TBD
end;
{begin
  if SeekFirst then
    fStatement.Reset;
  result := fStatement.Step=SQLITE_ROW;
end;}

end.