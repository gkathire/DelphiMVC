/// abstract database direct access classes
// - this unit is a part of the freeware Synopse mORMot framework,
// licensed under a MPL/GPL/LGPL tri-license; version 1.16
unit SynDB;

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

  Version 1.14
  - first public release, corresponding to SQLite3 Framework 1.14

  Version 1.15
  - SynDB unit extracted from previous SynOleDB.pas
  - TQueryValue.As* methods now handle NULL column as 0 or ''
  - added new TSQLDBRowVariantType custom variant type, allowing late binding
    access to row columns (not for Delphi 5) - see RowData method
  - fixed transaction handling in a safe abstract manner
  - TSQLDBStatement class now expects a prepared statement behavior, therefore
    TSQLDBStatementPrepared class has been merged into its parent class, and
    inherited classes have been renamed TSQLDBStatementWithParams[AndColumns]
  - new TSQLDBStatement.FetchAllAsJSON method for JSON retrieval as RawUTF8
  - exposed FetchAllAsJSON method for ISQLDBRows interface
  - made the code compatible with Delphi 5
  - new TSQLDBConnectionProperties.SQLIso8601ToDate virtual method
  - code refactoring for better metadata (database and table schemas) handling,
    including GetTableNames, GetFields, GetFieldDefinitions and GetForeignKey
    methods - will work with OleDB metadata and direct Oracle sys.all_* tables
  - new TSQLDBConnectionProperties.SQLCreate/SQLAddColumn/SQLAddIndex virtual
    methods (SQLCreate and SQLAddColumn will use the new protected SQLFieldCreate
    virtual method to retrieve the SQL field definition from protected
    fSQLCreateField[Max] properties) - as a result, SQL statement generation as
    requested for mORMot is now much more generic than previously
  - new overloaded TSQLDBStatement.Execute() method, able to mix % and ?
    parameters in the SQL statement
  - new TSQLDBStatement.BindNull() method
  - new TSQLDBConnectionProperties.NewThreadSafeStatementPrepared and
    TSQLDBConnection.NewStatementPrepared methods, able to be overriden to
    implement a SQL statement caching (used e.g. for SynDBSQLite3)
  - new TSQLDBConnection.ServerTimeStamp property, which will return the
    external database Server current date and time as TTimeLog/Int64 value
    (current implementation handle Oracle, MSSQL and MySQL database engines -
    with SQLite3, this will be the local PC time, just as for other DB engines)
  - new overloaded TSQLDBStatement.Bind() method, which can bind an array
    of const (i.e. an open list of Delphi arguments) to a statement
  - new overloaded TSQLDBStatement.Bind() and ColumnToVarData() methods, able
    to bind or retrieve values from a TVarData/TVarDataDynArray (used e.g.
    for direct access to/from SQLite3 virtual table in the SQLite3DB unit)
  - new ColumnTimeStamp method for TSQLDBStatement/ISQLDBRows, returning a
    TTimeLog/Int64 value for a date/time column

  Version 1.16
  - both TSQLDBStatement.FetchAllToJSON and FetchAllAsJSON methods now return
    the number of rows data fetched (excluding field names)

}

{$I Synopse.inc} // define HASINLINE USETYPEINFO CPU32 CPU64 OWNNORMTOUPPER

interface

/// if defined, a TQuery class will be defined to emulate the BDE TQuery class
{$define EMULATES_TQUERY}

uses
  Windows,
  SysUtils,
{$ifndef DELPHI5OROLDER}
  Variants,
{$endif}
  Classes,
  Contnrs,
  SynCommons;

  
{ -------------- TSQLDB* generic classes and types }

type
  /// generic Exception type, as used by the SynDB unit
  ESQLDBException = class(Exception);

  /// the handled field/parameter/column types by this unit
  // - this will map low-level database-level access types, not high-level
  // Delphi types as TSQLFieldType defined in SQLite3Commons
  // - for instance, it can be mapped to standard SQLite3 generic types, i.e.
  // NULL, INTEGER, REAL, TEXT, BLOB (with the addition of a ftCurrency and
  // ftDate type, for better support of most DB engines)
  // see @http://www.sqlite.org/datatype3.html
  // - the only string type handled here uses UTF-8 encoding (implemented
  // using our RawUTF8 type), for cross-Delphi true Unicode process
  TSQLDBFieldType =
    (ftUnknown, ftNull, ftInt64, ftDouble, ftCurrency, ftDate, ftUTF8, ftBlob);

  /// an array of RawUTF8, for each existing column type
  // - used e.g. by SQLCreate method
  // - the RowID definition will expect the ORM to create an unique identifier,
  // and send it with the INSERT statement (some databases, like Oracle, do not
  // support standard's IDENTITY attribute) - see http://troels.arvin.dk/db/rdbms
  // - for UTF-8 text, ftUTF8 will define the BLOB field, whereas ftNull will
  // expect to be formated with an expected field length in ColumnAttr
  // - the RowID definition will expect the ORM to create an unique identifier,
  // and send it with the INSERT statement (some databases, like Oracle, do not
  // support standard's IDENTITY attribute) - see http://troels.arvin.dk/db/rdbms
  TSQLDBFieldTypeDefinition = array[ftNull..ftBlob] of RawUTF8;

  /// the diverse type of bound parameters during a statement execution
  // - will be paramIn by default, which is the case 90% of time
  // - could be set to paramOut or paramInOut if must be refereshed after
  // execution (for calling a stored procedure expecting such parameters)
  TSQLDBParamInOutType =
    (paramIn, paramOut, paramInOut);

  /// used to define a field/column layout in a table schema
  // - for TSQLDBConnectionProperties.SQLCreate to describe the new table
  // - for TSQLDBConnectionProperties.GetFields to retrieve the table layout
  TSQLDBColumnDefine = packed record
    /// the Column name
    ColumnName: RawUTF8;
    /// the Column type, as retrieved from the database provider
    // - returned as plain text by GetFields method, to be used e.g. by
    // TSQLDBConnectionProperties.GetFieldDefinitions method
    // - SQLCreate will check for this value to override the default type
    ColumnTypeNative: RawUTF8;
    /// the Column type,
    // - should not be ftUnknown nor ftNull
    ColumnType: TSQLDBFieldType;
    /// the Column default width (in chars or bytes) of ftUTF8 or ftBlob
    // - can be set to value <0 for CBLOB or BLOB column type, i.e. for
    // a value without any maximal length
    ColumnLength: PtrInt;
    /// the Column data precision
    // - used e.g. for numerical values
    ColumnPrecision: PtrInt;
    /// the Column data scale
    // - used e.g. for numerical values
    ColumnScale: PtrInt;
    /// should be TRUE if the column is indexed
    ColumnIndexed: boolean;
  end;

  /// used to define the column layout of a table schema
  // - e.g. for TSQLDBConnectionProperties.GetFields
  TSQLDBColumnDefineDynArray = array of TSQLDBColumnDefine;
  
  /// used to define a field/column layout
  // - for TSQLDBConnectionProperties.SQLCreate to describe the table
  // - for TOleDBStatement.Execute/Column*() methods to map the IRowSet content
  TSQLDBColumnProperty = packed record
    /// the Column name
    ColumnName: RawUTF8;
    /// a general purpose integer value
    // - for SQLCreate: default width (in WideChars or Bytes) of ftUTF8 or ftBlob;
    // if set to 0, a CBLOB or BLOB column type will be created - note that
    // UTF-8 encoding is expected when calculating the maximum column byte size
    // for the CREATE TABLE statement (e.g. for Oracle 1333=4000/3 is used)
    // - for TOleDBStatement: the offset of this column in the IRowSet data,
    // starting with a DBSTATUSENUM, the data, then its length (for inlined
    // sftUTF8 and sftBlob only)
    // - for TSQLDBOracleStatement: contains an offset to this column values
    // inside fRowBuffer[] internal buffer
    ColumnAttr: PtrUInt;
    /// the Column type, used for storage
    // - for SQLCreate: should not be ftUnknown nor ftNull
    // - for TOleDBStatement: should not be ftUnknown
    ColumnType: TSQLDBFieldType;
    /// set if the Column must exists (i.e. should not be null)
    ColumnNonNullable: boolean;
    /// for TOleDBStatement: set if column was NOT defined as DBTYPE_BYREF
    // - which is the most common case, when column data < 4 KB
    // - for TSQLDBOracleStatement: set if column is an array of POCILobLocator
    ColumnValueInlined: boolean;
    // for TSQLDBOracleStatement: used to store the DefineByPos() TypeCode
    // - can be  SQLT_STR/SQLT_CLOB, SQLT_FLT, SQLT_INT, SQLT_DAT and SQLT_BLOB
    ColumnValueDBType: byte;
    // for TSQLDBOracleStatement: used to store one value size (in bytes)
    ColumnValueDBSize: cardinal;
  end;

  PSQLDBColumnProperty = ^TSQLDBColumnProperty;

  /// used to define a table/field column layout 
  TSQLDBColumnPropertyDynArray = array of TSQLDBColumnProperty;

  TSQLDBStatement = class;

{$ifndef DELPHI5OROLDER}
  /// a custom variant type used to have direct access to a result row content
  // - use ISQLDBRows.Data method to retrieve such a Variant
  TSQLDBRowVariantType = class(TSynInvokeableVariantType)
  protected
    procedure IntGet(var Dest: TVarData; const V: TVarData; Name: PAnsiChar); override;
    procedure IntSet(const V, Value: TVarData; Name: PAnsiChar); override;
  public
    /// clear the content
    procedure Clear(var V: TVarData); override;
    /// copy two record content
    procedure Copy(var Dest: TVarData; const Source: TVarData;
      const Indirect: Boolean); override;
  end;
{$endif}

  /// generic interface to access a SQL query result rows
  // - not all TSQLDBStatement methods are available, but only those to retrieve
  // data from a statement result: the purpose of this interface is to make
  // easy access to result rows, not provide all available features - therefore
  // you only have access to the Step() and Column*() methods
  ISQLDBRows = interface
    ['{11291095-9C15-4984-9118-974F1926DB9F}']
    {{ Access the next or first row of data from the SQL Statement result
     - return true on success, with data ready to be retrieved by Column*()
     - return false if no more row is available (e.g. if the SQL statement
      is not a SELECT but an UPDATE or INSERT command)
     - if SeekFirst is TRUE, will put the cursor on the first row of results
     - should raise an Exception on any error }
    function Step(SeekFirst: boolean=false): boolean; 
    {{ the column/field count of the current Row }
    function ColumnCount: integer;
    {{ the Column name of the current Row
     - Columns numeration (i.e. Col value) starts with 0
     - it's up to the implementation to ensure than all column names are unique }
    function ColumnName(Col: integer): RawUTF8;
    {{ returns the Column index of a given Column name
     - Columns numeration (i.e. Col value) starts with 0
     - returns -1 if the Column name is not found (via case insensitive search) }
    function ColumnIndex(const aColumnName: RawUTF8): integer;
    {{ the Column type of the current Row }
    function ColumnType(Col: integer): TSQLDBFieldType; overload;
    {{ return a Column integer value of the current Row, first Col is 0 }
    function ColumnInt(Col: integer): Int64; overload;
    {{ return a Column floating point value of the current Row, first Col is 0 }
    function ColumnDouble(Col: integer): double; overload;
    {{ return a Column floating point value of the current Row, first Col is 0 }
    function ColumnDateTime(Col: integer): TDateTime; overload;
    {{ return a column date and time value of the current Row, first Col is 0 }
    function ColumnTimeStamp(Col: integer): TTimeLog; overload;
    {{ return a Column currency value of the current Row, first Col is 0 }
    function ColumnCurrency(Col: integer): currency; overload;
    {{ return a Column UTF-8 encoded text value of the current Row, first Col is 0 }
    function ColumnUTF8(Col: integer): RawUTF8; overload;
    {{ return a Column text value as generic VCL string of the current Row, first Col is 0 }
    function ColumnString(Col: integer): string; overload; 
    {{ return a Column as a blob value of the current Row, first Col is 0 }
    function ColumnBlob(Col: integer): RawByteString; overload;
    {{ return a Column as a variant
     - a ftUTF8 TEXT content will be mapped into a generic WideString variant
       for pre-Unicode version of Delphi, and a generic UnicodeString (=string)
       since Delphi 2009: you may not loose any data during charset conversion
     - a ftBlob BLOB content will be mapped into a TBlobData AnsiString variant }
    function ColumnVariant(Col: integer): Variant; overload;
    {{ return a Column integer value of the current Row, first Col is 0 }
    function ColumnInt(const ColName: RawUTF8): Int64; overload;
    {{ return a Column floating point value of the current Row, first Col is 0 }
    function ColumnDouble(const ColName: RawUTF8): double; overload;
    {{ return a Column floating point value of the current Row, first Col is 0 }
    function ColumnDateTime(const ColName: RawUTF8): TDateTime; overload;
    {{ return a column date and time value of the current Row, first Col is 0 }
    function ColumnTimeStamp(const ColName: RawUTF8): TTimeLog; overload;
    {{ return a Column currency value of the current Row, first Col is 0 }
    function ColumnCurrency(const ColName: RawUTF8): currency; overload;
    {{ return a Column UTF-8 encoded text value of the current Row, first Col is 0 }
    function ColumnUTF8(const ColName: RawUTF8): RawUTF8; overload;
    {{ return a Column text value as generic VCL string of the current Row, first Col is 0 }
    function ColumnString(const ColName: RawUTF8): string; overload; 
    {{ return a Column as a blob value of the current Row, first Col is 0 }
    function ColumnBlob(const ColName: RawUTF8): RawByteString; overload;
    {{ return a Column as a variant }
    function ColumnVariant(const ColName: RawUTF8): Variant; overload;
    {{ return a Column as a variant
      - since a property getter can't be an overloaded method, we define one
      for the Column[] property }
    function GetColumnVariant(const ColName: RawUTF8): Variant;
    /// return the associated statement instance
    function Instance: TSQLDBStatement;
    {{ return a Column as a variant
      - this default property can be used to write simple code like this:
       ! procedure WriteFamily(const aName: RawUTF8);
       ! var I: ISQLDBRows;
       ! begin
       !   I := MyConnProps.Execute('select * from table where name=?',[aName]);
       !   while I.Step do
       !     writeln(I['FirstName'],' ',DateToStr(I['BirthDate']));
       ! end;
      - of course, using a variant and a column name will be a bit slower than
       direct access via the Column*() dedicated methods, but resulting code
       is fast in practice }
    property Column[const ColName: RawUTF8]: Variant read GetColumnVariant; default;
    // return all rows content as a JSON string 
    // - JSON data is retrieved with UTF-8 encoding
    // - if Expanded is true, JSON data is an array of objects, for direct use
    // with any Ajax or .NET client:
    // & [ {"col1":val11,"col2":"val12"},{"col1":val21,... ]
    // - if Expanded is false, JSON data is serialized (used in TSQLTableJSON)
    // & { "FieldCount":1,"Values":["col1","col2",val11,"val12",val21,..] }
    // - BLOB field value is saved as Base64, in the '"\uFFF0base64encodedbinary"'
    // format and contains true BLOB data
    // - if ReturnedRowCount points to an integer variable, it will be filled with
    // the number of row data returned (excluding field names)
    // - similar to corresponding TSQLRequest.Execute method in SQLite3 unit
    function FetchAllAsJSON(Expanded: boolean; ReturnedRowCount: PPtrInt=nil): RawUTF8;
{$ifndef DELPHI5OROLDER}
    /// create a TSQLDBRowVariantType able to access any field content via late binding
    // - i.e. you can use Data.Name to access the 'Name' column of the current row
    // - this Variant will point to the corresponding TSQLDBStatement instance,
    // so it's not necessary to retrieve its value for each row
    // - typical use is:
    // ! var Row: Variant;
    // ! (...)
    // !  with MyConnProps.Execute('select * from table where name=?',[aName]) do begin
    // !    Row := RowDaa;
    // !    while Step do
    // !      writeln(Row.FirstName,Row.BirthDate);
    // !  end;
    function RowData: Variant;
{$endif}
  end;

  {$M+} { published properties to be logged as JSON }

  TSQLDBConnection = class;

  /// abstract class used to set Database-related properties
  // - handle e.g. the Database server location and connection parameters (like
  // UserID and password)
  // - should also provide some Database-specific generic SQL statement creation
  // (e.g. how to create a Table), to be used e.g. by the mORMot layer
  TSQLDBConnectionProperties = class
  private
    function GetForeignKeysData: RawByteString;
    procedure SetForeignKeysData(const Value: RawByteString);
  protected
    fServerName: RawUTF8;
    fDatabaseName: RawUTF8;
    fPassWord: RawUTF8;
    fUserID: RawUTF8;
    fMainConnection: TSQLDBConnection;
    {$ifndef UNICODE}
    fVariantWideString: boolean;
    {$endif}
    fForeignKeys: TSynNameValue;
    fSQLCreateField: TSQLDBFieldTypeDefinition;
    fSQLCreateFieldMax: PtrUInt;
    fSQLGetServerTimeStamp: RawUTF8;
    function GetMainConnection: TSQLDBConnection;
    /// will be called at the end of constructor
    // - this default implementation will do nothing
    procedure SetInternalProperties; virtual;
    /// get all field/column names for a specified Table
    // - used by GetFieldDefinitions public method
    // - should return a SQL "SELECT" statement with the field names as first
    // column, a textual field type as 2nd column, then field length, then
    // numeric precision and scale as 3rd, 4th and 5th columns, and the index
    // count in 6th column
    // - this default implementation just returns nothing
    // - if this method is overriden, the ColumnTypeNativeToDB() method should
    // also be overriden in order to allow conversion from native column
    // type into the corresponding TSQLDBFieldType
    function SQLGetField(const aTableName: RawUTF8): RawUTF8; virtual;
    /// convert a textual column data type, as retrieved e.g. from SQLGetField,
    // into our internal primitive types
    // - default implementation will always return ftUTF8
    function ColumnTypeNativeToDB(const aNativeType: RawUTF8; aScale: integer): TSQLDBFieldType; virtual;
    /// get all table names
    // - used by GetTableNames public method
    // - should return a SQL "SELECT" statement with the table names as
    // first column (any other columns will be ignored)
    // - this default implementation just returns nothing
    function SQLGetTableNames: RawUTF8; virtual;
    /// should initialize fForeignKeys content with all foreign keys of this
    // database
    // - used by GetForeignKey method  
    procedure GetForeignKeys; virtual; abstract;
    /// will use fSQLCreateField[Max] to create the SQL column definition
    function SQLFieldCreate(const aField: TSQLDBColumnProperty): RawUTF8; virtual;
  public
    /// initialize the properties
    // - children may optionaly handle the fact that no UserID or Password
    // is supplied here, by displaying a corresponding Dialog box
    constructor Create(const aServerName, aDatabaseName, aUserID, aPassWord: RawUTF8);
      virtual;
    /// release related memory, and close MainConnection
    destructor Destroy; override;
    /// create a new connection
    // - call this method if the shared MainConnection is not enough (e.g. for
    // multi-thread access)
    // - the caller is responsible of freeing this instance
    function NewConnection: TSQLDBConnection; virtual; abstract;
    /// get a thread-safe connection
    // - this default implementation will return the MainConnection shared
    // instance, so the provider should be thread-safe by itself
    // - TSQLDBConnectionPropertiesThreadSafe will implement a per-thread
    // connection pool, via an internal TSQLDBConnection pool, per thread
    // if necessary (e.g. for OleDB, which expect one TOleDBConnection instance
    // per thread)
    function ThreadSafeConnection: TSQLDBConnection; virtual;
    /// create a new thread-safe statement
    // - this method will call ThreadSafeConnection.NewStatement 
    function NewThreadSafeStatement: TSQLDBStatement;
    /// create a new thread-safe statement from an internal cache (if any)
    // - will call ThreadSafeConnection.NewStatementPrepared
    // - this method should return nil in case of error, or a prepared statement
    // instance in case of success
    function NewThreadSafeStatementPrepared(const aSQL: RawUTF8;
       ExpectResults: Boolean): TSQLDBStatement; overload; 
    /// create a new thread-safe statement from an internal cache (if any)
    // - this method will call the NewThreadSafeStatementPrepared method
    function NewThreadSafeStatementPrepared(SQLFormat: PUTF8Char;
      const Args: array of const; ExpectResults: Boolean): TSQLDBStatement; overload;
    /// execute a SQL query, returning a statement interface instance to retrieve
    // the result rows
    // - will call NewThreadSafeStatement method to retrieve a thread-safe
    // statement instance, then run the corresponding Execute() method
    // - returns an ISQLDBRows to access any resulting rows (if
    // ExpectResults is TRUE), and provide basic garbage collection, as such:
    // ! procedure WriteFamily(const aName: RawUTF8);
    // ! var I: ISQLDBRows;
    // ! begin
    // !   I := MyConnProps.Execute('select * from table where name=?',[aName]);
    // !   while I.Step do
    // !     writeln(I['FirstName'],' ',DateToStr(I['BirthDate']));
    // ! end;
    // - if RowsVariant is set, you can use it to row column access via late
    // binding, as such:
    // ! procedure WriteFamily(const aName: RawUTF8);
    // ! var R: Variant;
    // ! begin
    // !   with MyConnProps.Execute('select * from table where name=?',[aName],@R) do
    // !   while Step do
    // !     writeln(R.FirstName,' ',DateToStr(R.BirthDate));
    // ! end;
    function Execute(const aSQL: RawUTF8; const Params: array of const
{$ifndef DELPHI5OROLDER}; RowsVariant: PVariant=nil{$endif}): ISQLDBRows;
    /// execute a SQL query, without returning any rows
    // - can be used to launch INSERT, DELETE or UPDATE statement, e.g.
    // - will call NewThreadSafeStatement method to retrieve a thread-safe
    // statement instance, then run the corresponding Execute() method
    // - return the number of modified rows (or 0 if the DB driver do not
    // give access to this value)
    function ExecuteNoResult(const aSQL: RawUTF8; const Params: array of const): integer;

    /// used to create a Table
    // - should return the SQL "CREATE" statement needed to create a table with
    // the specified field/column names and types
    // - a "RowID Int64 PRIMARY KEY" column is always added at first position,
    // and will expect the ORM to create an unique RowID value sent at INSERT
    // (could use "select max(RowID) from table" to retrieve the last value)   
    // - this default implementation will use internal fSQLCreateField and
    // fSQLCreateFieldMax protected values, which contains by default the
    // ANSI SQL Data Types and maximum 1000 inlined WideChars: inherited classes
    // may change the default fSQLCreateField* content or override this method 
    function SQLCreate(const aTableName: RawUTF8;
      const aFields: TSQLDBColumnPropertyDynArray): RawUTF8; virtual; 
    /// used to add a column to a Table
    // - should return the SQL "ALTER TABLE" statement needed to add a column to
    // an existing table
    // - this default implementation will use internal fSQLCreateField and
    // fSQLCreateFieldMax protected values, which contains by default the
    // ANSI SQL Data Types and maximum 1000 inlined WideChars: inherited classes
    // may change the default fSQLCreateField* content or override this method 
    function SQLAddColumn(const aTableName: RawUTF8;
      const aField: TSQLDBColumnProperty): RawUTF8; virtual;
    /// used to add an index to a Table
    // - should return the SQL "CREATE INDEX" statement needed to add an index
    // to the specified column names of an existing table
    // - index will expect UNIQUE values in the specified columns, if Unique
    // parameter is set to true
    // - this default implementation will return the standard SQL statement, i.e.
    // 'CREATE [UNIQUE] INDEX index_name ON table_name (column_name[s])'
    function SQLAddIndex(const aTableName: RawUTF8;
      const aFieldNames: array of RawUTF8; aUnique: boolean;
      const aIndexName: RawUTF8=''): RawUTF8; virtual;
    /// convert an ISO-8601 encoded time and date into a date appropriate to
    // be pasted in the SQL request
    // - this default implementation will return the quoted ISO-8601 value, i.e.
    // 'YYYY-MM-DDTHH:MM:SS' (as expected by Microsoft SQL server e.g.) 
    function SQLIso8601ToDate(const Iso8601: RawUTF8): RawUTF8; virtual; 
    /// retrieve the column/field layout of a specified table
    // - this default implementation will use protected SQLGetField virtual
    // method to retrieve the field names and properties
    // - used e.g. by GetFieldDefinitions
    // - will call ColumnTypeNativeToDB protected virtual method to guess the
    // each mORMot TSQLDBFieldType
    procedure GetFields(const aTableName: RawUTF8; var Fields: TSQLDBColumnDefineDynArray);  virtual;
    /// get all field/column definition for a specified Table
    // - call the GetFields method and retrieve the column field name and
    // type as 'Name [Type Length Precision Scale]'
    // - if WithForeignKeys is set, will add external foreign keys as '% tablename'
    procedure GetFieldDefinitions(const aTableName: RawUTF8;
      var Fields: TRawUTF8DynArray; WithForeignKeys: boolean);
    /// get all table names
    // - this default implementation will use protected SQLGetTableNames virtual
    // method to retrieve the table names
    procedure GetTableNames(var Tables: TRawUTF8DynArray); virtual;
    /// retrieve a foreign key for a specified table and column
    // - first time it is called, it will retrieve all foreign keys from the
    // remote database using virtual protected GetForeignKeys method into
    // the protected fForeignKeys list: this may be slow, depending on the
    // database access (more than 10 seconds waiting is possible)
    // - any further call will use this internal list, so response will be
    // immediate
    // - the whole foreign key list is shared by all connections
    function GetForeignKey(const aTableName, aColumnName: RawUTF8): RawUTF8;

    /// return a shared connection, corresponding to the given
    // - call the ThreadSafeConnection method instead e.g. for multi-thread
    // access, or NewThreadSafeStatement for direct retrieval of a new statement
    property MainConnection: TSQLDBConnection read GetMainConnection;
    /// the associated User Identifier, as specified at creation
    property UserID: RawUTF8 read fUserID;
    /// the associated User Password, as specified at creation
    property PassWord: RawUTF8 read fPassWord;
    /// can be used to store the fForeignKeys[] data in an external BLOB
    // - since GetForeignKeys is somewhat slow, could save a lot of time
    property ForeignKeysData: RawByteString read GetForeignKeysData write SetForeignKeysData;
  published { to be logged as JSON - no UserID nor Password for security :) }
    /// the associated server name, as specified at creation
    property ServerName: RawUTF8 read fServerName;
    /// the associated database name, as specified at creation
    property DatabaseName: RawUTF8 read fDatabaseName;
    {$ifndef UNICODE}
    /// set to true to force all variant conversion to WideString instead of
    // the default faster AnsiString, for pre-Unicode version of Delphi
    // - by default, the converstion to Variant will create an AnsiString kind
    // of variant: for pre-Unicode Delphi, avoiding WideString/OleStr content
    // will speed up the process a lot, if you are sure that the current
    // charset matchs the expected one (which is very likely)
    // - set this property to TRUE so that the converstion to Variant will
    // create a WideString kind of variant, to avoid any character data loss:
    // the access to the property will be slower, but you won't have any
    // potential data loss
    // - starting with Delphi 2009, the TEXT content will be stored as an
    // UnicodeString in the variant, so this property is not necessary
    // - the Variant conversion is mostly used for the TQuery wrapper, or for
    // the ISQLDBRows.Column[] property or ISQLDBRows.ColumnVariant() method;
    // this won't affect other Column*() methods, or JSON production
    property VariantStringAsWideString: boolean read fVariantWideString write fVariantWideString;
    {$endif}
  end;
  {$M-}

  TSQLDBConnectionPropertiesClass = class of TSQLDBConnectionProperties;

  /// abstract connection created from TSQLDBConnectionProperties
  // - more than one TSQLDBConnection instance can be run for the same
  // TSQLDBConnectionProperties
  TSQLDBConnection = class
  protected
    fProperties: TSQLDBConnectionProperties;
    fErrorMessage: string;
    fInfoMessage: string;
    fTransactionCount: integer;
    fServerTimeStampOffset: TTimeLog;
    function GetServerTimeStamp: TTimeLog; virtual; 
    function IsConnected: boolean; virtual; abstract;
    /// raise an exception
    procedure CheckConnection;
  public
    /// connect to a specified database engine
    constructor Create(aProperties: TSQLDBConnectionProperties); virtual;
    /// release memory and connection
    destructor Destroy; override;

    /// connect to the specified database
    // - should raise an Exception on error
    procedure Connect; virtual; abstract;
    /// stop connection to the specified database
    // - should raise an Exception on error
    procedure Disconnect; virtual; abstract;
    /// initialize a new SQL query statement for the given connection
    // - the caller should free the instance after use
    function NewStatement: TSQLDBStatement; virtual; abstract;
    /// initialize a new SQL query statement for the given connection
    // - this default implementation will call the NewStatement method
    // - but children may override this method to handle statement caching
    // - this method should return nil in case of error, or a prepared statement
    // instance in case of success
    function NewStatementPrepared(const aSQL: RawUTF8;
      ExpectResults: Boolean): TSQLDBStatement; virtual; 
    /// begin a Transaction for this connection
    // - this default implementation will check and set TransactionCount
    procedure StartTransaction; virtual; 
    /// commit changes of a Transaction for this connection
    // - StartTransaction method must have been called before
    // - this default implementation will check and set TransactionCount
    procedure Commit; virtual;
    /// discard changes of a Transaction for this connection
    // - StartTransaction method must have been called before
    // - this default implementation will check and set TransactionCount
    procedure Rollback; virtual;
    /// number of nested StartTransaction calls
    property TransactionCount: integer read fTransactionCount;
    /// the current Date and Time, as retrieved from the server
    // - this property will return the timestamp in TTimeLog / Iso8601 / Int64
    // after correction from the Server returned time-stamp (if any)
    // - default implementation will return the executable time, i.e. Iso8601Now
    property ServerTimeStamp: TTimeLog read GetServerTimeStamp;
  published { to be logged as JSON }
    /// the associated database properties
    property Properties: TSQLDBConnectionProperties read fProperties;
    /// returns TRUE if the connection was set
    property Connected: boolean read IsConnected;
    /// some information message, as retrieved during execution
    property LastErrorMessage: string read fErrorMessage;
    /// some information message, as retrieved during execution
    property InfoMessage: string read fInfoMessage;
  end;

  /// generic abstract class to implement a prepared SQL query
  // - inherited classes should implement the DB-specific connection in its
  // overriden methods, especially Bind*(), Prepare(), ExecutePrepared, Step()
  // and Column*() methods
  TSQLDBStatement = class(TInterfacedObject, ISQLDBRows)
  protected
    fConnection: TSQLDBConnection;
    fSQL: RawUTF8;
    fExpectResults: boolean;
    fParamCount: integer;
    fColumnCount: integer;
    fTotalRowsRetrieved: Integer;
    fCurrentRow: Integer;
    function GetSQLWithInlinedParams: RawUTF8;
    /// default implementation returns 0
    function GetUpdateCount: integer; virtual;
    /// raise an exception if Col is out of range according to fColumnCount
    procedure CheckCol(Col: integer); {$ifdef HASINLINE}inline;{$endif}
    {{ will set a Int64/Double/Currency/TDateTime/RawUTF8/TBlobData Dest variable
      from a given column value
     - internal conversion will use a temporary Variant and ColumnToVariant method
     - expects Dest to be of the exact type (e.g. Int64, not Integer) }
    function ColumnToTypedValue(Col: integer; DestType: TSQLDBFieldType; var Dest): TSQLDBFieldType;
    {{ retrieve the inlined value of a given parameter, e.g. 1 or 'name'
    - use ParamToVariant() virtual method }
    function GetParamValueAsText(Param: integer): RawUTF8; virtual; 
    {{ return a Column as a variant }
    function GetColumnVariant(const ColName: RawUTF8): Variant;
    /// return the associated statement instance for a ISQLDBRows interface
    function Instance: TSQLDBStatement;
  public
    {{ create a statement instance }
    constructor Create(aConnection: TSQLDBConnection); virtual;

    {{ bind a NULL value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindNull(Param: Integer; IO: TSQLDBParamInOutType=paramIn); virtual; abstract;
    {{ bind an integer value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure Bind(Param: Integer; Value: Int64;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {{ bind a double value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure Bind(Param: Integer; Value: double;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {{ bind a TDateTime value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindDateTime(Param: Integer; Value: TDateTime;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {{ bind a currency value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindCurrency(Param: Integer; Value: currency;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {{ bind a UTF-8 encoded string to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextU(Param: Integer; const Value: RawUTF8;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {{ bind a UTF-8 encoded buffer text (#0 ended) to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextP(Param: Integer; Value: PUTF8Char;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {{ bind a UTF-8 encoded string to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextS(Param: Integer; const Value: string;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {{ bind a UTF-8 encoded string to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextW(Param: Integer; const Value: WideString;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {{ bind a Blob buffer to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindBlob(Param: Integer; Data: pointer; Size: integer;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {{ bind a Blob buffer to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindBlob(Param: Integer; const Data: RawByteString;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract; 
    {{ bind a Variant value to a parameter
     - the leftmost SQL parameter has an index of 1 
     - will call all virtual Bind*() methods from the Data type
     - if DataIsBlob is TRUE, will call BindBlob(RawByteString(Data)) instead
       of BindTextW(WideString(Variant)) - used e.g. by TQuery.AsBlob/AsBytes }
    procedure BindVariant(Param: Integer; const Data: Variant; DataIsBlob: boolean;
      IO: TSQLDBParamInOutType=paramIn); virtual;
    {{ bind an array of TVarData values
     - TVarData handled types are varNull, varInt64, varDouble, varString
       (mapping a constant PUTF8Char), and varAny (BLOB with size = VLongs[0])
     - so this Param should not be used typecasted from a Variant
     - this default implementation will call corresponding Bind*() method }
    procedure Bind(const Params: TVarDataDynArray;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual;
    {{ bind an array of const values
     - parameters marked as ? should be specified as method parameter in Params[]
     - BLOB parameters could not be bound with this method, but need an explicit
       call to BindBlob() method
     - this default implementation will call corresponding Bind*() method }
    procedure Bind(const Params: array of const;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual;

    {{ Prepare an UTF-8 encoded SQL statement
     - parameters marked as ? will be bound later, before ExecutePrepared call
     - if ExpectResults is TRUE, then Step() and Column*() methods are available
       to retrieve the data rows
     - should raise an Exception on any error
     - this default implementation will just store aSQL content and the
       ExpectResults parameter, and connect to the remote server is was not
       already connected }
    procedure Prepare(const aSQL: RawUTF8; ExpectResults: Boolean); overload; virtual;
    {{ Execute a prepared SQL statement
     - parameters marked as ? should have been already bound with Bind*() functions
     - should raise an Exception on any error }
    procedure ExecutePrepared; virtual; abstract;
    {{ Reset the previous prepared statement
     - some drivers expect an explicit reset before binding parameters and
       executing the statement another time
     - this default implementation will just do nothing }
    procedure Reset; virtual;
    {{ Prepare and Execute an UTF-8 encoded SQL statement
     - parameters marked as ? should have been already bound with Bind*()
       functions above
     - if ExpectResults is TRUE, then Step() and Column*() methods are available
       to retrieve the data rows
     - should raise an Exception on any error
     - this method will call Prepare then ExecutePrepared methods }
    procedure Execute(const aSQL: RawUTF8; ExpectResults: Boolean); overload; 
    {{ Prepare and Execute an UTF-8 encoded SQL statement
     - parameters marked as ? should be specified as method parameter in Params[]
     - BLOB parameters could not be bound with this method, but need an explicit
       call to BindBlob() method
     - if ExpectResults is TRUE, then Step() and Column*() methods are available
       to retrieve the data rows
     - should raise an Exception on any error
     - this method will bind parameters, then call Excecute() virtual method }
    procedure Execute(const aSQL: RawUTF8; ExpectResults: Boolean;
      const Params: array of const); overload;
    {{ Prepare and Execute an UTF-8 encoded SQL statement
     - parameters marked as % will be replaced by Args[] value in the SQL text
     - parameters marked as ? should be specified as method parameter in Params[]
     - so could be used as such, mixing both % and ? parameters:
     ! Statement.Execute('SELECT % FROM % WHERE RowID=?',true,[FieldName,TableName],[ID])
     - BLOB parameters could not be bound with this method, but need an explicit
       call to BindBlob() method
     - if ExpectResults is TRUE, then Step() and Column*() methods are available
       to retrieve the data rows
     - should raise an Exception on any error
     - this method will bind parameters, then call Excecute() virtual method }
    procedure Execute(SQLFormat: PUTF8Char; ExpectResults: Boolean;
      const Args, Params: array of const); overload;
    {{ retrieve the parameter content, after SQL execution
     - the leftmost SQL parameter has an index of 1
     - to be used e.g. with stored procedures
     - the parameter should have been bound with IO=paramOut or IO=paramInOut
       if CheckIsOutParameter is TRUE
     - this implementation just check that Param is correct: overriden method
       should fill Value content }
    function ParamToVariant(Param: Integer; var Value: Variant;
      CheckIsOutParameter: boolean=true): TSQLDBFieldType; virtual;
    {{ Access the next or first row of data from the SQL Statement result
     - return true on success, with data ready to be retrieved by Column*()
     - return false if no more row is available (e.g. if the SQL statement
      is not a SELECT but an UPDATE or INSERT command)
     - if SeekFirst is TRUE, will put the cursor on the first row of results
     - should raise an Exception on any error }
    function Step(SeekFirst: boolean=false): boolean; virtual; abstract;

    {{ the column/field count of the current Row }
    function ColumnCount: integer;
    {{ the Column name of the current Row
     - Columns numeration (i.e. Col value) starts with 0
     - it's up to the implementation to ensure than all column names are unique }
    function ColumnName(Col: integer): RawUTF8; virtual; abstract;
    {{ returns the Column index of a given Column name
     - Columns numeration (i.e. Col value) starts with 0
     - returns -1 if the Column name is not found (via case insensitive search) }
    function ColumnIndex(const aColumnName: RawUTF8): integer; virtual; abstract;
    {{ the Column type of the current Row }
    function ColumnType(Col: integer): TSQLDBFieldType; virtual; abstract;
    {{ returns TRUE if the column contains NULL }
    function ColumnNull(Col: integer): boolean; virtual; abstract;
    {{ return a Column integer value of the current Row, first Col is 0 }
    function ColumnInt(Col: integer): Int64; overload; virtual; abstract;
    {{ return a Column floating point value of the current Row, first Col is 0 }
    function ColumnDouble(Col: integer): double; overload; virtual; abstract;
    {{ return a Column date and time value of the current Row, first Col is 0 }
    function ColumnDateTime(Col: integer): TDateTime; overload; virtual; abstract;
    {{ return a column date and time value of the current Row, first Col is 0
    - call ColumnDateTime or ColumnUTF8 to convert into Iso8601/Int64 time stamp
     from a TDateTime or text }
    function ColumnTimeStamp(Col: integer): TTimeLog; overload;
    {{ return a Column currency value of the current Row, first Col is 0 }
    function ColumnCurrency(Col: integer): currency; overload; virtual; abstract;
    {{ return a Column UTF-8 encoded text value of the current Row, first Col is 0 }
    function ColumnUTF8(Col: integer): RawUTF8; overload; virtual; abstract;
    {{ return a Column text value as generic VCL string of the current Row, first Col is 0
     - this default implementation will call ColumnUTF8 }
    function ColumnString(Col: integer): string; overload; virtual;
    {{ return a Column as a blob value of the current Row, first Col is 0 }
    function ColumnBlob(Col: integer): RawByteString; overload; virtual; abstract;
    {{ return a Column as a variant
     - this default implementation will call ColumnToVariant() method
     - a ftUTF8 TEXT content will be mapped into a generic WideString variant
       for pre-Unicode version of Delphi, and a generic UnicodeString (=string)
       since Delphi 2009: you may not loose any data during charset conversion
     - a ftBlob BLOB content will be mapped into a TBlobData AnsiString variant }
    function ColumnVariant(Col: integer): Variant; overload;
    {{ return a Column integer value of the current Row, first Col is 0 }
    function ColumnInt(const ColName: RawUTF8): Int64; overload;
    {{ return a Column floating point value of the current Row, first Col is 0 }
    function ColumnDouble(const ColName: RawUTF8): double; overload;
    {{ return a Column date and time value of the current Row, first Col is 0 }
    function ColumnDateTime(const ColName: RawUTF8): TDateTime; overload;
    {{ return a column date and time value of the current Row, first Col is 0
    - call ColumnDateTime or ColumnUTF8 to convert into Iso8601/Int64 time stamp
     from a TDateTime or text }
    function ColumnTimeStamp(const ColName: RawUTF8): TTimeLog; overload;
    {{ return a Column currency value of the current Row, first Col is 0 }
    function ColumnCurrency(const ColName: RawUTF8): currency; overload;
    {{ return a Column UTF-8 encoded text value of the current Row, first Col is 0 }
    function ColumnUTF8(const ColName: RawUTF8): RawUTF8; overload;
    {{ return a Column text value as generic VCL string of the current Row, first Col is 0 }
    function ColumnString(const ColName: RawUTF8): string; overload;
    {{ return a Column as a blob value of the current Row, first Col is 0 }
    function ColumnBlob(const ColName: RawUTF8): RawByteString; overload;
    {{ return a Column as a variant }
    function ColumnVariant(const ColName: RawUTF8): Variant; overload;
    {{ return a Column as a variant
     - this default implementation will call Column*() method above
     - a ftUTF8 TEXT content will be mapped into a generic WideString variant
       for pre-Unicode version of Delphi, and a generic UnicodeString (=string)
       since Delphi 2009: you may not loose any data during charset conversion
     - a ftBlob BLOB content will be mapped into a TBlobData AnsiString variant }
    function ColumnToVariant(Col: integer; var Value: Variant): TSQLDBFieldType; virtual;
    {{ return a Column as a TVarData value
     - TVarData handled types are varNull, varInt64, varDouble, varString
       (mapping a constant PUTF8Char), and varAny (BLOB with size = VLongs[0])
     - so this Value should not be used typecasted to a Variant
     - the specified Temp variable will be used for temporary storage of
       varString/varAny values
     - this default implementation will call corresponding Column*() method }
    function ColumnToVarData(Col: Integer; var Value: TVarData;
      var Temp: RawByteString): TSQLDBFieldType; virtual;
{$ifndef DELPHI5OROLDER}
    /// create a TSQLDBRowVariantType able to access any field content via late binding
    // - i.e. you can use Data.Name to access the 'Name' column of the current row
    // - this Variant will point to the corresponding TSQLDBStatement instance,
    // so it's not necessary to retrieve its value for each row
    // - typical use is:
    // ! var Row: Variant;
    // ! (...)
    // !  with MyConnProps.Execute('select * from table where name=?',[aName]) do begin
    // !    Row := RowDaa;
    // !    while Step do
    // !      writeln(Row.FirstName,Row.BirthDate);
    // !  end;
    function RowData: Variant; virtual;
{$endif}
    {{ append all columns values of the current Row to a JSON stream
     - will use WR.Expand to guess the expected output format
     - this default implementation will call Column*() methods above, but you
       should also implement a custom version with no temporary variable
     - BLOB field value is saved as Base64, in the '"\uFFF0base64encodedbinary"
       format and contains true BLOB data }
    procedure ColumnsToJSON(WR: TJSONWriter); virtual;
    // Append all rows content as a JSON stream
    // - JSON data is added to the supplied TStream, with UTF-8 encoding
    // - if Expanded is true, JSON data is an array of objects, for direct use
    // with any Ajax or .NET client:
    // & [ {"col1":val11,"col2":"val12"},{"col1":val21,... ]
    // - if Expanded is false, JSON data is serialized (used in TSQLTableJSON)
    // & { "FieldCount":1,"Values":["col1","col2",val11,"val12",val21,..] }
    // - BLOB field value is saved as Base64, in the '"\uFFF0base64encodedbinary"'
    // format and contains true BLOB data
    // - similar to corresponding TSQLRequest.Execute method in SQLite3 unit
    // - returns the number of row data returned (excluding field names)
    // - warning: TSQLRestServerStaticExternal.EngineRetrieve in SQLite3DB
    // expects the Expanded=true format to return '[{...}]'#10
    function FetchAllToJSON(JSON: TStream; Expanded: boolean): PtrInt;
    // return all rows content as a JSON string
    // - JSON data is retrieved with UTF-8 encoding
    // - if Expanded is true, JSON data is an array of objects, for direct use
    // with any Ajax or .NET client:
    // & [ {"col1":val11,"col2":"val12"},{"col1":val21,... ]
    // - if Expanded is false, JSON data is serialized (used in TSQLTableJSON)
    // & { "FieldCount":1,"Values":["col1","col2",val11,"val12",val21,..] }
    // - BLOB field value is saved as Base64, in the '"\uFFF0base64encodedbinary"'
    // format and contains true BLOB data
    // - if ReturnedRowCount points to an integer variable, it will be filled with
    // the number of row data returned (excluding field names)
    // - similar to corresponding TSQLRequest.Execute method in SQLite3 unit
    function FetchAllAsJSON(Expanded: boolean; ReturnedRowCount: PPtrInt=nil): RawUTF8;

    /// the associated database connection
    property Connection: TSQLDBConnection read fConnection;
    /// the prepared SQL statement, as supplied to Prepare() method
    property SQL: RawUTF8 read fSQL;
    /// the prepared SQL statement, with all '?' changed into the supplied
    // parameter values
    property SQLWithInlinedParams: RawUTF8 read GetSQLWithInlinedParams;
    /// the current row after Execute call, corresponding to Column*() methods
    // - contains 0 in case of no (more) available data, or a number >=1
    property CurrentRow: Integer read fCurrentRow;
    /// the total number of data rows retrieved by this instance
    // - is not reset when there is no more row of available data (Step returns
    // false), or when Step() is called with SeekFirst=true
    property TotalRowsRetrieved: Integer read fTotalRowsRetrieved;
    /// gets a number of updates made by latest executed statement
    property UpdateCount: Integer read GetUpdateCount;
  end;

  /// abstract connection created from TSQLDBConnectionProperties
  // - this overriden class will defined an hidden thread ID, to ensure
  // that one connection will be create per thread
  // - an Ole DB connection will inherit from this class
  TSQLDBConnectionThreadSafe = class(TSQLDBConnection)
  protected
    fThreadID: DWORD;
  end;

  /// connection properties which will implement an internal Thread-Safe
  // connection pool
  TSQLDBConnectionPropertiesThreadSafe = class(TSQLDBConnectionProperties)
  protected
    fConnectionPool: TObjectList;
    /// returns nil if none was defined yet
    function CurrentThreadConnection: TSQLDBConnection;
    /// returns -1 if none was defined yet
    function CurrentThreadConnectionIndex: Integer;
  public
    /// initialize the properties
    // - this overriden method will initialize the internal per-thread connection
    // pool
    constructor Create(const aServerName, aDatabaseName, aUserID, aPassWord: RawUTF8);
      override;
    /// release related memory, and all per-thread connections
    destructor Destroy; override;
    /// get a thread-safe connection
    // - this overriden implementation will define a per-thread TSQLDBConnection
    // connection pool, via an internal  pool
    function ThreadSafeConnection: TSQLDBConnection; override;
    /// you can call this method just before a thread is finished to ensure
    // that the associated Connection will be released
    // - could be used e.g. in a try...finally block inside a TThread.Execute
    // overriden method
    procedure EndCurrentThread;
  end;

  /// a structure used to store a standard binding parameter
  // - you can use your own internal representation of parameters
  // (TOleDBStatement use its own TOleDBStatementParam type), but
  // this type can be used to implement a generic parameter
  // - used e.g. by TSQLDBStatementWithParams as a dynamic array
  // (and its inherited TSQLDBOracleStatement)
  TSQLDBParam = packed record
    /// storage used for TEXT (ftUTF8) and BLOB (ftBlob) values
    // - ftBlob are stored as RawByteString
    // - ftUTF8 are stored as RawUTF8
    // - sometimes, may be ftInt64 or ftCurrency provided as text parameters
    VData: RawByteString;
    /// the column/parameter Value type
    VType: TSQLDBFieldType;
    /// define if parameter can be retrieved after a stored procedure execution
    VInOut: TSQLDBParamInOutType;
    /// used e.g. by TSQLDBOracleStatement
    VDBType: word;
    {$ifdef CPU64}
    // so that VInt64 will be 8 bytes aligned
    VFill: cardinal;
    {$endif}
    /// storage used for ftInt64, ftDouble, ftDate and ftCurrency value
    VInt64: Int64;
  end;

  PSQLDBParam = ^TSQLDBParam;

  /// dynamic array used to store standard binding parameters
  // - used e.g. by TSQLDBStatementWithParams (and its
  // inherited TSQLDBOracleStatement)
  TSQLDBParamDynArray = array of TSQLDBParam;

  /// generic abstract class handling prepared statements with binding
  // - will provide protected fields and methods for handling standard
  // TSQLDBParam parameters
  TSQLDBStatementWithParams = class(TSQLDBStatement)
  protected
    fParams: TSQLDBParamDynArray;
    fParam: TDynArray;
    function CheckParam(Param: Integer; NewType: TSQLDBFieldType;
      IO: TSQLDBParamInOutType): PSQLDBParam;
  public
    /// create a statement instance
    // - this overriden version will initialize the internal fParam* fields
    constructor Create(aConnection: TSQLDBConnection); override;
    {{ bind a NULL value to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure BindNull(Param: Integer; IO: TSQLDBParamInOutType=paramIn); override;
    {{ bind an integer value to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure Bind(Param: Integer; Value: Int64;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a double value to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure Bind(Param: Integer; Value: double;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a TDateTime value to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure BindDateTime(Param: Integer; Value: TDateTime;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a currency value to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure BindCurrency(Param: Integer; Value: currency;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a UTF-8 encoded string to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure BindTextU(Param: Integer; const Value: RawUTF8;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a UTF-8 encoded buffer text (#0 ended) to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextP(Param: Integer; Value: PUTF8Char;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a VCL string to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure BindTextS(Param: Integer; const Value: string;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind an OLE WideString to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure BindTextW(Param: Integer; const Value: WideString;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a Blob buffer to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure BindBlob(Param: Integer; Data: pointer; Size: integer;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ bind a Blob buffer to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure BindBlob(Param: Integer; const Data: RawByteString;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {{ retrieve the parameter content, after SQL execution
     - the leftmost SQL parameter has an index of 1
     - to be used e.g. with stored procedures
     - this overriden function will retrieve the value stored in the protected
       fParams[] array: the ExecutePrepared method should have updated its
       content as exepcted}
    function ParamToVariant(Param: Integer; var Value: Variant;
      CheckIsOutParameter: boolean=true): TSQLDBFieldType; override;
  end;

  /// generic abstract class handling prepared statements with binding
  // and column description
  // - will provide protected fields and methods for handling both TSQLDBParam
  // parameters and standard TSQLDBColumnProperty column description
  TSQLDBStatementWithParamsAndColumns = class(TSQLDBStatementWithParams)
  protected
    fColumns: TSQLDBColumnPropertyDynArray;
    fColumn: TDynArrayHashed;
  public
    /// create a statement instance
    // - this overriden version will initialize the internal fColumn* fields
    constructor Create(aConnection: TSQLDBConnection); override;
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
    {{ Reset the previous prepared statement
     - this overriden implementation will just do reset the internal fColumn[] }
    procedure Reset; override;
  end;

/// function helper logging some column truncation information text
procedure LogTruncatedColumn(const Col: TSQLDBColumnProperty);


{ -------------- native connection interfaces, without OleDB }

type
  /// access to a native library
  // - this generic class is to be used for any native connection using an
  // external library
  // - is used e.g. in SynDBOracle by TSQLDBOracleLib to access the OCI library,
  // or by SynDBODBC to access the ODBC library
  TSQLDBLib = class
  protected
    fHandle: HMODULE;
  public
    /// release associated memory and linked library
    destructor Destroy; override;
    /// the associated library handle
    property Handle: HMODULE read fHandle write fHandle;
  end;


{ -------------- Oracle specific functions - shared by SynOleDB and SynDBOracle }

const
  /// the Oracle column data types corresponding to our TSQLDBFieldType types
  ORA_FIELDS: TSQLDBFieldTypeDefinition = (
  ' NVARCHAR2(%)',' NUMBER(22)',' BINARY_DOUBLE',' NUMBER(19,4)',' DATE',' CBLOB',' BLOB');
  // ftNull, ftInt64, ftDouble, ftCurrency, ftDate, ftUTF8, ftBlob

  /// the Oracle SQL statement to retrieve the server date and time
  ORA_SERVERTIME = 'select sysdate from dual';

/// get all field/column names for a specified Table using Oracle SQL syntax
// - returns a SQL "SELECT" statement with the field names as first column,
// a textual field type as 2nd column, field type as the 3rd column,
// field length and precision as 4th and 5th columns, and the index count in 6th
// column
// - is made global, since may be used by both SynDBOracle and SynOleDB units
function OracleSQLGetField(const aTableName: RawUTF8): RawUTF8;

/// retrieve a mORMot field type from the native type as returned by
// OracleSQLGetField() function
function OracleColumnTypeNativeToDB(const aNativeType: RawUTF8; aScale: integer): TSQLDBFieldType;

/// get all table names using Oracle SQL syntax
// - should return a SQL "SELECT" statement with the table names as
// first column (any other columns will be ignored)
const
   OracleSQLGetTableNames= 'select owner||''.''||table_name name '+
     'from sys.all_tables order by owner, table_name';

/// convert an ISO-8601 encoded time and date into a date appropriate to
// be pasted in the SQL request
// - returns to_date('....','YYYY-MM-DD HH24:MI:SS') for Oracle
function OracleSQLIso8601ToDate(Iso8601: RawUTF8): RawUTF8; 


{$ifdef EMULATES_TQUERY}

{ -------------- TQuery TField TParam emulation classes and types }

type
  /// generic Exception type raised by the TQuery class
  ESQLQueryException = class(Exception);

  /// generic type used by TQuery / TQueryValue for BLOBs fields
  TBlobData = RawByteString;

  /// represent the use of parameters on queries or stored procedures
  // - same enumeration as with the standard DB unit from VCL
  TParamType = (ptUnknown, ptInput, ptOutput, ptInputOutput, ptResult);

  TQuery = class;

  /// pseudo-class handling a TQuery bound parameter or column value
  // - will mimic both TField and TParam classes as defined in standard DB unit,
  // by pointing both classes types to PQueryValue
  // - usage of an object instead of a class allow faster access via a
  // dynamic array (and our TDynArrayHashed wrapper) for fast property name
  // handling (via name hashing) and pre-allocation
  // - it is based on an internal Variant to store the parameter or column value
  TQueryValue = object
  protected
    /// fName should be the first property, i.e. the searched hashed value
    fName: string;
    fValue: Variant;
    fValueBlob: boolean;
    fParamType: TParamType;
    // =-1 if empty, =0 if eof, >=1 if cursor on row data
    fRowIndex: integer;
    fColumnIndex: integer;
    fQuery: TQuery;
    procedure CheckExists;
    procedure CheckValue;
    function GetIsNull: boolean;
    function GetDouble: double;
    function GetString: string;
    function GetAsWideString: SynUnicode;
    function GetCurrency: Currency;
    function GetDateTime: TDateTime;
    function GetVariant: Variant;
    function GetInteger: integer;
    function GetInt64: Int64;
    function GetBlob: TBlobData;
    function GetAsBytes: TBytes;
    function GetBoolean: Boolean;
    procedure SetDouble(const aValue: double);
    procedure SetString(const aValue: string);
    procedure SetAsWideString(const aValue: SynUnicode);
    procedure SetCurrency(const aValue: Currency);
    procedure SetDateTime(const aValue: TDateTime);
    procedure SetVariant(const aValue: Variant);
    procedure SetInteger(const aValue: integer);
    procedure SetInt64(const aValue: Int64);
    procedure SetBlob(const aValue: TBlobData);
    procedure SetAsBytes(const Value: TBytes);
    procedure SetBoolean(const aValue: Boolean);
    procedure SetBound(const aValue: Boolean);
  public
    /// set the column value to null
    procedure Clear;
    /// the associated (field) name
    property FieldName: string read fName;
    /// the associated (parameter) name
    property Name: string read fName;
    /// how to use this parameter on queries or stored procedures
    property ParamType: TParamType read fParamType write fParamType;
    /// returns TRUE if the stored Value is null
    property IsNull: Boolean read GetIsNull;
    /// just do nothing - here for compatibility reasons with Clear + Bound := true
    property Bound: Boolean write SetBound;
    /// access the Value as Integer
    property AsInteger: integer read GetInteger write SetInteger;
    /// access the Value as Int64
    // - note that under Delphi 5, Int64 is not handled: the Variant type
    // only handle integer types, in this Delphi version :(
    property AsInt64: Int64 read GetInt64 write SetInt64;
    /// access the Value as boolean
    property AsBoolean: Boolean read GetBoolean write SetBoolean;
    /// access the Value as String
    // - used in the VCL world for both TEXT and BLOB content (BLOB content
    // will only work in pre-Unicode Delphi version, i.e. before Delphi 2009)
    property AsString: string read GetString write SetString;
    /// access the Value as an unicode String
    // - will return a WideString before Delphi 2009, and an UnicodeString
    // for Unicode versions of the compiler (i.e. our SynUnicode type)
    property AsWideString: SynUnicode read GetAsWideString write SetAsWideString;
    /// access the BLOB Value as an AnsiString
    // - will work for all Delphi versions, including Unicode versions (i.e.
    // since Delphi 2009)
    // - for a BLOB parameter or column, you should use AsBlob or AsBlob 
    // properties instead of AsString (this later won't work after Delphi 2007)
    property AsBlob: TBlobData read GetBlob write SetBlob;
    /// access the BLOB Value as array of byte (TBytes)
     // - will work for all Delphi versions, including Unicode versions (i.e.
    // since Delphi 2009)
    // - for a BLOB parameter or column, you should use AsBlob or AsBlob
    // properties instead of AsString (this later won't work after Delphi 2007)
    property AsBytes: TBytes read GetAsBytes write SetAsBytes;
    /// access the Value as double
    property AsFloat: double read GetDouble write SetDouble;
    /// access the Value as TDateTime
    property AsDateTime: TDateTime read GetDateTime write SetDateTime;
    /// access the Value as TDate
    property AsDate: TDateTime read GetDateTime write SetDateTime;
    /// access the Value as TTime
    property AsTime: TDateTime read GetDateTime write SetDateTime;
    /// access the Value as Currency
    // - avoid any rounding conversion, as with AsFloat
    property AsCurrency: Currency read GetCurrency write SetCurrency;
    /// access the Value as Variant
    property AsVariant: Variant read GetVariant write SetVariant;
  end;

  /// a dynamic array of TQuery bound parameters or column values
  // - TQuery will use TDynArrayHashed for fast search
  TQueryValueDynArray = array of TQueryValue;

  /// pointer to TQuery bound parameter or column value
  PQueryValue = ^TQueryValue;

  /// pointer mapping the VCL DB TField class
  // - to be used e.g. with code using local TField instances in a loop
  TField = PQueryValue;

  /// pointer mapping the VCL DB TParam class
  // - to be used e.g. with code using local TParam instances
  TParam = PQueryValue;

  /// class mapping VCL DB TQuery for direct database process
  // - this class can mimic basic TQuery VCL methods, but won't need any BDE
  // installed, and will be faster for field and parameters access than the
  // standard TDataSet based implementation; in fact, OleDB replaces the BDE
  // or the DBExpress layer, or access directly to the client library
  // (e.g. for TSQLDBOracleConnectionProperties which calls oci.dll)
  // - it is able to run basic queries as such:
  // !  Q := TQuery.Create(aSQLDBConnection);
  // !  try
  // !    Q.SQL.Clear; // optional
  // !    Q.SQL.Add('select * from DOMAIN.TABLE');
  // !    Q.SQL.Add('  WHERE ID_DETAIL=:detail;');
  // !    Q.ParamByName('DETAIL').AsString := '123420020100000430015';
  // !    Q.Open;
  // !    Q.First;    // optional
  // !    while not Q.Eof do begin
  // !      assert(Q.FieldByName('id_detail').AsString='123420020100000430015');
  // !      Q.Next;
  // !    end;
  // !    Q.Close;    // optional
  // !  finally
  // !    Q.Free;
  // !  end;
  // - since there is no underlying TDataSet, you can't have read and write
  // access, or use the visual DB components of the VCL: it's limited to
  // direct emulation of low-level SQL as in the above code, with one-direction
  // retrieval (e.g. the Edit, Post, Append, Cancel, Prior, Locate, Lookup
  // methods do not exist within this class)
  // - this class is Unicode-ready even before Delphi 2009 (via the TQueryValue
  // AsWideString method), will natively handle Int64/TBytes field or parameter
  // data, and will have less overhead than the standard DB components of the VCL
  // - you should better use TSQLDBStatement instead of this wrapper, but
  // having such code-compatible TQuery replacement could make easier some
  // existing code upgrade (e.g. to avoid deploying the deprecated BDE, generate
  // smaller executable, access any database without paying a big fee,
  // avoid rewriting a lot of existing code lines of a big application...)
  TQuery = class
  protected
    fSQL: TStringList;
    fPrepared: TSQLDBStatement;
    fRowIndex: Integer;
    fConnection: TSQLDBConnection;
    fParams: TQueryValueDynArray;
    fResults: TQueryValueDynArray;
    fResult: TDynArrayHashed;
    fResultCount: integer;
    fParam: TDynArrayHashed;
    fParamCount: Integer;
    function GetIsEmpty: Boolean;
    function GetActive: Boolean;
    function GetFieldCount: integer;
    function GetParamCount: integer;
    function GetField(aIndex: integer): TField;
    function GetParam(aIndex: integer): TParam;
    function GetEof: boolean;
    function GetBof: Boolean;
    function GetRecordCount: integer;
    function GetSQLAsText: string;
    /// prepare and execute the SQL query
    procedure Execute(ExpectResults: Boolean);
  public
    /// initialize a query for the associated database connection
    constructor Create(aConnection: TSQLDBConnection);
    /// release internal memory and statements
    destructor Destroy; override;
    /// a do-nothing method, just available for compatibility purpose
    procedure Prepare;
    /// begin the SQL query, for a SELECT statement
    // - will parse the entered SQL statement, and bind parameters
    // - will then execute the SELECT statement, ready to use First/Eof/Next
    // methods, the returned rows being available via FieldByName methods
    procedure Open;
    /// begin the SQL query, for a non SELECT statement
    // - will parse the entered SQL statement, and bind parameters
    // - the query should be released with a call to Close before reopen
    procedure ExecSQL;
    /// after a successfull Open, will get the first row of results
    procedure First;
    /// after successfull Open and First, go the the next row of results
    procedure Next;
    /// after a successfull Open, will get the last row of results
    procedure Last;
    /// end the SQL query
    // - will release the SQL statement, results and bound parameters
    // - the query should be released with a call to Close before reopen
    procedure Close;
    /// access a SQL statement parameter, entered as :aParamName in the SQL
    // - if the requested parameter do not exist yet in the internal fParams
    // list, AND if CreateIfNotExisting=true, a new TQueryValue instance
    // will be created and registered
    function ParamByName(const aParamName: string; CreateIfNotExisting: boolean=true): TParam;
    /// retrieve a column value from the current opened SQL query row
    // - will raise an ESQLQueryException error in case of error, e.g. if no column
    // name matchs the supplied name
    function FieldByName(const aFieldName: string): TField;
    /// retrieve a column value from the current opened SQL query row
    // - will return nil in case of error, e.g. if no column name matchs the
    // supplied name
    function FindField(const aFieldName: string): TField;
    /// the associated database connection
    property Connection: TSQLDBConnection read fConnection;
    /// the SQL statement to be executed
    // - statement will be prepared and executed via Open or ExecSQL methods
    property SQL: TStringList read fSQL;
    /// the SQL statement with inlined bound parameters
    property SQLAsText: string read GetSQLAsText;
    /// equals true if there is some rows pending
    property Eof: Boolean read GetEof;
    /// equals true if on first row
    property Bof: Boolean read GetBof;
    /// returns 0 if no record was retrievd, 1 if there was some records
    // - not the exact count: just here for compatibility purpose with code
    // like   if aQuery.RecordCount>0 then ...
    property RecordCount: integer read GetRecordCount;
    /// equals true if there is no row returned
    property IsEmpty: Boolean read GetIsEmpty;
    /// equals true if the query is opened
    property Active: Boolean read GetActive;
    /// the number of columns in the current opened SQL query row
    property FieldCount: integer read GetFieldCount;
    /// the number of bound parameters in the current SQL statement
    property ParamCount: integer read GetParamCount;
    /// retrieve a column value from the current opened SQL query row
    // - will return nil in case of error, e.g. out of range index
    property Fields[aIndex: integer]: TField read GetField;
    /// retrieve a  bound parameters in the current SQL statement
    // - will return nil in case of error, e.g. out of range index
    property Params[aIndex: integer]: TParam read GetParam;
  end;

{$endif EMULATES_TQUERY}

var
  /// the TSynLog class used for logging for all our SynDB related units
  // - you may override it with TSQLLog, if available from SQLite3Commons
  // - since not all exceptions are handled specificaly by this unit, you
  // may better use a common TSynLog class for the whole application or module
  SynDBLog: TSynLogClass=TSynLog;


implementation

{$ifdef EMULATES_TQUERY}

{ TQueryValue }

procedure TQueryValue.CheckExists;
begin
  if @self=nil then
    raise ESQLQueryException.Create('Parameter/Field not existing');
end;

procedure TQueryValue.CheckValue;
begin
  CheckExists;
  if fQuery=nil then
    exit; // Params already have updated value
  if fQuery.fRowIndex<=0 then // =-1 if empty, =0 if eof, >=1 if row data
    raise ESQLQueryException.Create('TQuery not opened');
  if fRowIndex<>fQuery.fRowIndex then begin // get column value once per row
    fRowIndex := fQuery.fRowIndex;
    fQuery.fPrepared.ColumnToVariant(fColumnIndex,fValue);
  end;
end;

// in code below, most of the work should have been done by the Variants unit :)
// but since Delphi 5 does not handle varInt64 type, we had do handle it :(
// in all cases, our version should speed up process a little bit ;)

procedure TQueryValue.Clear;
begin
  fValue := Null;
end;

function TQueryValue.GetAsBytes: TBytes;
var tmp: TBlobData;
    L: integer;
begin
  CheckValue;
  if TVarData(fValue).VType<>varNull then
    tmp := TBlobData(fValue);
  L := length(tmp);
  Setlength(result,L);
  move(pointer(tmp)^,pointer(result)^,L);
end;

function TQueryValue.GetAsWideString: SynUnicode;
begin
  CheckValue;
  with TVarData(fValue) do
  case VType of
    varNull:     result := '';
    varInt64:    result := UTF8ToSynUnicode(Int64ToUtf8(VInt64));
  else Result := SynUnicode(fValue);
  end;
end;

function TQueryValue.GetBlob: TBlobData;
begin
  CheckValue;
  if TVarData(fValue).VType<>varNull then
    Result := TBlobData(fValue) else
    Result := '';
end;

function TQueryValue.GetBoolean: Boolean;
begin
  Result := GetInt64<>0;
end;

function TQueryValue.GetCurrency: Currency;
begin
  CheckValue;
  with TVarData(fValue) do
  case VType of
    varNull:     result := 0;
    varInteger:  result := VInteger;
    varInt64:    result := VInt64;
    varCurrency: result := VCurrency;
    varDouble:   result := VDouble;
    else result := fValue;
  end;
end;

function TQueryValue.GetDateTime: TDateTime;
begin
  CheckValue;
  Result := GetDouble;
end;

function TQueryValue.GetDouble: double;
begin
  CheckValue;
  with TVarData(fValue) do
  case VType of
    varNull:     result := 0;
    varInteger:  result := VInteger;
    varInt64:    result := VInt64;
    varCurrency: result := VCurrency;
    varDouble:   result := VDouble;
    else result := fValue;
  end;
end;

function TQueryValue.GetInt64: Int64;
begin
  CheckValue;
  with TVarData(fValue) do
  case VType of
    varNull:     result := 0;
    varInteger:  result := VInteger;
    varInt64:    result := VInt64;
    varCurrency: result := trunc(VCurrency);
    varDouble:   result := trunc(VDouble);
    else result := {$ifdef DELPHI5OROLDER}integer{$endif}(fValue);
  end;
end;

function TQueryValue.GetInteger: integer;
begin
  CheckValue;
  with TVarData(fValue) do
  case VType of
    varNull:     result := 0;
    varInteger:  result := VInteger;
    varInt64:    result := VInt64;
    varCurrency: result := trunc(VCurrency);
    varDouble:   result := trunc(VDouble);
    else result := fValue;
  end;
end;

function TQueryValue.GetIsNull: boolean;
begin
  CheckValue;
  result := TVarData(fValue).VType=varNull;
end;

function TQueryValue.GetString: string;
begin
  CheckValue;
  with TVarData(fValue) do
  case VType of
    varNull:     result := '';
    varInteger:  result := IntToString(VInteger);
    varInt64:    result := IntToString(VInt64);
    varCurrency: result := Curr64ToString(VInt64);
    varDouble:   result := DoubleToString(VDouble,15);
    varString:   result := string(AnsiString(VAny));
    {$ifdef UNICODE}varUString: result := UnicodeString(VAny);{$endif}
    varOleStr:   result := WideString(VAny);
    else result := fValue;
  end;
end;

function TQueryValue.GetVariant: Variant;
begin
  CheckValue;
  {$ifdef DELPHI5OROLDER}
  with TVarData(fValue) do // Delphi 5 need conversion to float to avoid overflow
  if VType=varInt64 then
    if (VInt64<low(Integer)) or (VInt64>high(Integer)) then
      result := VInt64*1.0 else
      result := integer(VInt64) else
  {$endif}
    result := fValue;
end;

procedure TQueryValue.SetAsBytes(const Value: TBytes);
var tmp: TBlobData;
begin
  CheckExists;
  System.SetString(tmp,PAnsiChar(Value),length(Value));
  fValue := tmp;
  fValueBlob := true;
end;

procedure TQueryValue.SetAsWideString(const aValue: SynUnicode);
begin
  CheckExists;
  fValue := aValue;
end;

procedure TQueryValue.SetBlob(const aValue: TBlobData);
begin
  CheckExists;
  fValue := aValue;
  fValueBlob := true;
end;

procedure TQueryValue.SetBoolean(const aValue: Boolean);
begin
  CheckExists;
  fValue := aValue;
end;

procedure TQueryValue.SetBound(const aValue: Boolean);
begin
  ; // just do nothing
end;

procedure TQueryValue.SetCurrency(const aValue: Currency);
begin
  CheckExists;
  fValue := aValue;
end;

procedure TQueryValue.SetDateTime(const aValue: TDateTime);
begin
  CheckExists;
  fValue := aValue;
end;

procedure TQueryValue.SetDouble(const aValue: double);
begin
  CheckExists;
  fValue := aValue;
end;

procedure TQueryValue.SetInt64(const aValue: Int64);
begin
  CheckExists;
{$ifdef DELPHI5OROLDER}
  VarClear(fValue);
  with TVarData(fValue) do begin
    VType := varInt64;
    VInt64 := aValue;
  end;
{$else}
  fValue := aValue;
{$endif}
end;

procedure TQueryValue.SetInteger(const aValue: integer);
begin
  CheckExists;
  fValue := aValue;
end;

procedure TQueryValue.SetString(const aValue: string);
begin
  CheckExists;
  fValue := aValue;
end;

procedure TQueryValue.SetVariant(const aValue: Variant);
begin
  CheckExists;
  fValue := aValue;
end;


{ TQuery }

procedure TQuery.Close;
begin
  try
    FreeAndNil(fPrepared);
  finally
    fSQL.Clear;
    fParam.Clear;
    fResult.Clear;
    fRowIndex := -1; // =-1 if empty
  end;
end;

constructor TQuery.Create(aConnection: TSQLDBConnection);
begin
  SynDBLog.Enter(self);
  inherited Create;
  fConnection := aConnection;
  fSQL := TStringList.Create;
  fParam.Init(TypeInfo(TQueryValueDynArray),fParams,nil,nil,nil,@fParamCount,true);
  fResult.Init(TypeInfo(TQueryValueDynArray),fResults,nil,nil,nil,@fResultCount,true);
end;

destructor TQuery.Destroy;
begin
  try
    Close;
  finally
    FreeAndNil(fSQL);
    inherited;
  end;
end;

procedure TQuery.Prepare;
begin
  // just available for compatibility purpose
end;

procedure TQuery.ExecSQL;
begin
  SynDBLog.Enter(self);
  Execute(false);
end;

function TQuery.FieldByName(const aFieldName: string): PQueryValue;
var i: integer;
begin
  if (self=nil) or (fRowIndex<=0) then // -1=empty, 0=eof, >=1 if row data
    raise ESQLQueryException.CreateFmt(
      'FieldByName("%s"): called on closed request',[aFieldName]);
  i := fResult.FindHashed(aFieldName);
  if i<0 then
    raise ESQLQueryException.CreateFmt(
      'FieldByName("%s"): unknown field name',[aFieldName]) else
    result := @fResults[i];
end;

function TQuery.FindField(const aFieldName: string): TField;
var i: integer;
begin
  result := nil;
  if (self=nil) or (fRowIndex<=0) then // -1=empty, 0=eof, >=1 if row data
    exit;
  i := fResult.FindHashed(aFieldName);
  if i>=0 then
    result := @fResults[i];
end;

procedure TQuery.First;
begin
  SynDBLog.Enter(self);
  if (self=nil) or (fPrepared=nil) then
    raise ESQLQueryException.Create('First: Invalid call');
  if fRowIndex<>1 then // perform only if cursor not already on first data row 
    if fPrepared.Step(true) then
      // cursor sucessfully set to 1st row  
      fRowIndex := 1 else
      // no row is available -> empty result
      fRowIndex := -1; // =-1 if empty, =0 if eof, >=1 if cursor on row data
end;

function TQuery.GetEof: boolean;
begin
  result := (Self=nil) or (fRowIndex<=0);
end;

function TQuery.GetRecordCount: integer;
begin
  if IsEmpty then
    result := 0 else
    result := 1;
end;

function TQuery.GetBof: Boolean;
begin
  result := (Self<>nil) and (fRowIndex=1);
end;

function TQuery.GetIsEmpty: Boolean;
begin
  result := (Self=nil) or (fRowIndex<0); // =-1 if empty, =0 if eof
end;

function TQuery.GetActive: Boolean;
begin
  result := (self<>nil) and (fPrepared<>nil);
end;

function TQuery.GetFieldCount: integer;
begin
  if IsEmpty then
    result := 0 else
    result := fResultCount;
end;

function TQuery.GetParamCount: integer;
begin
  if IsEmpty then
    result := 0 else
    result := fParamCount;
end;

function TQuery.GetField(aIndex: integer): TField;
begin
  if (Self=nil) or (fRowIndex<0) or (cardinal(aIndex)>=cardinal(fResultCount)) then
    result := nil else
    result := @fResults[aIndex];
end;

function TQuery.GetParam(aIndex: integer): TParam;
begin
  if (Self=nil) or (cardinal(aIndex)>=cardinal(fParamCount)) then
    result := nil else
    result := @fParams[aIndex];
end;

function TQuery.GetSQLAsText: string;
begin
  if (self=nil) or (fPrepared=nil) then
    result := '' else
    result := Utf8ToString(fPrepared.GetSQLWithInlinedParams);
end;

procedure TQuery.Next;
begin
  if (self=nil) or (fPrepared=nil) then
    raise ESQLQueryException.Create('Next: Invalid call');
  if fPrepared.Step(false) then
    inc(fRowIndex) else
    // no more row is available
    fRowIndex := 0;
end;

procedure TQuery.Last;
var i: integer;
begin
  if (self=nil) or (fPrepared=nil) then
    raise ESQLQueryException.Create('Next: Invalid call');
  while fPrepared.Step(false) do begin
    inc(fRowIndex);
    for i := 0 to fPrepared.ColumnCount-1 do begin
      fPrepared.ColumnToVariant(i,fResults[i].fValue);
      fResults[i].fRowIndex := fRowIndex;
    end;
  end;
end;

procedure TQuery.Open;
var i, h: integer;
    added: boolean;
    ColumnName: string;
begin
  SynDBLog.Enter(self);
  if fResultCount>0 then
    raise ESQLQueryException.Create('TQuery.Open without previous Close');
  Execute(true);
  for i := 0 to fPrepared.ColumnCount-1 do begin
    ColumnName := UTF8ToString(fPrepared.ColumnName(i));
    h := fResult.FindHashedForAdding(ColumnName,added);
    if not added then
      raise ESQLQueryException.CreateFmt('Duplicated column name "%s"',[ColumnName]);
    with fResults[h] do begin
      fQuery := self;
      fRowIndex := 0;
      fColumnIndex := i;
      fName := ColumnName;
    end;
  end;
  assert(fResultCount=fPrepared.ColumnCount);
  // always read the first row
  First;
end;

function TQuery.ParamByName(const aParamName: string;
  CreateIfNotExisting: boolean): PQueryValue;
var i: integer;
    added: boolean;
begin
  if CreateIfNotExisting then begin
    i := fParam.FindHashedForAdding(aParamName,added);
    result := @fParams[i];
    if added then
      result^.fName := aParamName;
  end else begin
    i := fParam.FindHashed(aParamName);
    if i>=0 then
      result := @fParams[i] else
      result := nil;
  end;
end;

procedure TQuery.Execute(ExpectResults: Boolean);
const
  DB2OLE: array[TParamType] of TSQLDBParamInOutType = (
     paramIn,  paramIn, paramOut, paramInOut,    paramIn);
 // ptUnknown, ptInput, ptOutput, ptInputOutput, ptResult
var req, new, tmp: RawUTF8;
    P, B: PAnsiChar;
    col, i: Integer;
begin
  SynDBLog.Enter(self);
  if (self=nil) or (fResultCount>0) or
     (fConnection=nil) or (fPrepared<>nil) then
    raise ESQLQueryException.Create('TQuery.Prepare called with no previous Close');
  fRowIndex := -1;
  for i := 0 to fParamCount-1 do
    fParams[i].fColumnIndex := 0; // reset SQL parameter index
  if Connection<>nil then
    fPrepared := Connection.NewStatement;
  if fPrepared=nil then
    raise ESQLQueryException.Create('Connection to DB failed');
  req := Trim(StringToUTF8(SQL.Text));
  P := pointer(req);
  if P=nil then
    ESQLQueryException.Create('No SQL statement');
  col := 0;
  repeat 
    B := P;
    while not (P^ in [':',#0]) do begin
      case P^ of
      '''':
        if P[1]<>'''' then begin
          repeat // ignore chars inside ' quotes
            inc(P);
          until P^ in ['''',#0];
          if P^=#0 then break;
        end;
      #1..#31:
        P^ := ' '; // convert #13/#10 into ' '
      end;
      inc(P);
    end;
    SetString(tmp,B,P-B);
    if P^=#0 then begin
      new := new+tmp;
      break;
    end;
    new := new+tmp+'?';
    inc(P); // jump ':'
    B := P;
    while P^ in ['A'..'Z','a'..'z','0'..'9','_'] do
      inc(P); // go to end of parameter name
    SetString(tmp,B,P-B);
    i := fParam.FindHashed(tmp);
    if i<0 then
      raise ESQLQueryException.CreateFmt('Parameter "%s" not bound for "%s"',[tmp,req]);
    inc(col);
    fParams[i].fColumnIndex := col;
  until P^=#0;
  fPrepared.Prepare(new,ExpectResults);
  for i := 0 to fParamCount-1 do // the leftmost SQL parameter has an index of 1
    try
      with fParams[i] do
      if fColumnIndex>0 then // leftmost SQL parameter has an index of 1
        fPrepared.BindVariant(fColumnIndex,fValue,fValueBlob,DB2OLE[ParamType]);
    except
      on E: Exception do
        raise ESQLQueryException.CreateFmt(
          'Error "%s" at binding value for parameter "%s" in "%s"',
          [E.Message,fParams[i].fName,UTF8ToString(fPrepared.SQLWithInlinedParams)]);
    end;
  fPrepared.ExecutePrepared;
end;

{$endif EMULATES_TQUERY}




{ TSQLDBConnection }

procedure TSQLDBConnection.CheckConnection;
begin
  if not Connected then
    raise ESQLDBException.CreateFmt('%s on %s/%s should be connected',
      [ClassName,Properties.ServerName,Properties.DataBaseName]);
end;

procedure TSQLDBConnection.Commit;
begin
  CheckConnection;
  if TransactionCount<=0 then
    raise ESQLDBException.CreateFmt('Invalid %s.Commit call',[ClassName]);
  dec(fTransactionCount);
end;

constructor TSQLDBConnection.Create(aProperties: TSQLDBConnectionProperties);
begin
  fProperties := aProperties;
end;

destructor TSQLDBConnection.Destroy;
begin
  try
    Disconnect;
  except
    on E: Exception do
      SynDBLog.Add.Log(sllError,E);
  end;
end;

function TSQLDBConnection.GetServerTimeStamp: TTimeLog;
begin
  result := Iso8601Now;
  if (fServerTimeStampOffset=0) and
     (fProperties.fSQLGetServerTimeStamp<>'') then begin
    with fProperties do
      fServerTimeStampOffset :=
        Execute(fSQLGetServerTimeStamp,[]).ColumnTimeStamp(0)-result;
      if fServerTimeStampOffset=0 then
        fServerTimeStampOffset := 1; // request server time only once
    end;
  inc(result,fServerTimeStampOffset);
end;

function TSQLDBConnection.NewStatementPrepared(const aSQL: RawUTF8;
  ExpectResults: Boolean): TSQLDBStatement;
begin
  try
    result := NewStatement;
    result.Prepare(aSQL,ExpectResults);
  except
    on Exception do
      FreeAndNil(result);
  end;
end;

procedure TSQLDBConnection.Rollback;
begin
  CheckConnection;
  if TransactionCount<=0 then
    raise ESQLDBException.CreateFmt('Invalid %s.Rollback call',[ClassName]);
  dec(fTransactionCount);
end;

procedure TSQLDBConnection.StartTransaction;
begin
  CheckConnection;
  inc(fTransactionCount);
end;


{ TSQLDBConnectionProperties }

constructor TSQLDBConnectionProperties.Create(const aServerName, aDatabaseName,
  aUserID, aPassWord: RawUTF8);
const ASCII_FIELDS: TSQLDBFieldTypeDefinition = (
  ' NVARCHAR(%)',' BIGINT',' DOUBLE',' NUMERIC(19,4)',' TIMESTAMP',' CBLOB',' BLOB');
  // ftNull, ftInt64, ftDouble, ftCurrency, ftDate, ftUTF8, ftBlob
begin
  fServerName := aServerName;
  fDatabaseName := aDatabaseName;
  fUserID := aUserID;
  fPassWord := aPassWord;
  fSQLCreateField := ASCII_FIELDS;
  fSQLCreateFieldMax := 1000;
  SetInternalProperties; // virtual method used to override default parameters
end;

destructor TSQLDBConnectionProperties.Destroy;
begin
  FreeAndNil(fMainConnection);
  inherited;
end;

function TSQLDBConnectionProperties.Execute(const aSQL: RawUTF8;
  const Params: array of const{$ifndef DELPHI5OROLDER}; RowsVariant: PVariant=nil{$endif}): ISQLDBRows;
var Query: TSQLDBStatement;
begin
  SynDBLog.Enter(self);
  Query := NewThreadSafeStatement;
  Query.Execute(aSQL,true,Params);
{$ifndef DELPHI5OROLDER}
  if RowsVariant<>nil then
    RowsVariant^ := Query.RowData;
{$endif}
  result := Query;
end;

function TSQLDBConnectionProperties.ExecuteNoResult(const aSQL: RawUTF8;
  const Params: array of const): integer;
begin
  SynDBLog.Enter(self);
  with NewThreadSafeStatement do
  try
    Execute(aSQL,false,Params);
    result := UpdateCount;
  finally
    Free;
  end;
end;

function TSQLDBConnectionProperties.GetMainConnection: TSQLDBConnection;
begin
  if self=nil then
    result := nil else begin
    if fMainConnection=nil then
      fMainConnection := NewConnection;
    result := fMainConnection;
  end;
end;

function TSQLDBConnectionProperties.ThreadSafeConnection: TSQLDBConnection;
begin
  result := MainConnection; // provider should be thread-safe
end;

function TSQLDBConnectionProperties.NewThreadSafeStatement: TSQLDBStatement;
begin
  result := ThreadSafeConnection.NewStatement;
end;

function TSQLDBConnectionProperties.NewThreadSafeStatementPrepared(
  const aSQL: RawUTF8; ExpectResults: Boolean): TSQLDBStatement;
begin
  result := ThreadSafeConnection.NewStatementPrepared(aSQL,ExpectResults);
end;

function TSQLDBConnectionProperties.NewThreadSafeStatementPrepared(
  SQLFormat: PUTF8Char; const Args: array of const; ExpectResults: Boolean): TSQLDBStatement;
begin
  result := NewThreadSafeStatementPrepared(FormatUTF8(SQLFormat,Args),ExpectResults);
end;

procedure TSQLDBConnectionProperties.SetInternalProperties;
begin
  // nothing to do yet
end;

procedure TSQLDBConnectionProperties.GetFieldDefinitions(const aTableName: RawUTF8;
  var Fields: TRawUTF8DynArray; WithForeignKeys: boolean);
const EXE_FMT1: PUTF8Char = '% [%'; // for Delphi 5
      EXE_FMT2: PUTF8Char = '% % % %]';
var F: TSQLDBColumnDefineDynArray;
    Ref: RawUTF8;
    i: integer;
begin
  GetFields(aTableName,F);
  SetLength(Fields,length(F));
  for i := 0 to high(F) do
  with F[i] do begin
    Fields[i] := FormatUTF8(EXE_FMT1,[ColumnName,ColumnTypeNative]);
    if (ColumnLength<>0) or (ColumnPrecision<>0) or (ColumnScale<>0) then
      Fields[i] := FormatUTF8(EXE_FMT2,[Fields[i],ColumnLength,ColumnPrecision,ColumnScale]) else
      Fields[i] := Fields[i]+']';
    if ColumnIndexed then
      Fields[i] := Fields[i]+' *';
    if WithForeignKeys then begin
      Ref := GetForeignKey(aTableName,ColumnName);
      if Ref<>'' then
        Fields[i] := Fields[i] +' % '+Ref;
    end;
  end;
end;

procedure TSQLDBConnectionProperties.GetFields(const aTableName: RawUTF8;
  var Fields: TSQLDBColumnDefineDynArray);
var SQL: RawUTF8;
    n: integer;
    F: TSQLDBColumnDefine;
    FA: TDynArray;
begin
  SQL := SQLGetField(aTableName);
  SetLength(Fields,0);
  if SQL='' then
    exit;
  FA.Init(TypeInfo(TSQLDBColumnDefineDynArray),Fields,@n);
  with Execute(SQL,[]) do
    while Step do begin
      F.ColumnName := ColumnUTF8(0);
      F.ColumnTypeNative := ColumnUTF8(1);
      F.ColumnLength := ColumnInt(2);
      F.ColumnPrecision := ColumnInt(3);
      F.ColumnScale := ColumnInt(4);
      F.ColumnType := ColumnTypeNativeToDB(F.ColumnTypeNative,F.ColumnScale);
      F.ColumnIndexed := ColumnInt(5)>0;
      FA.Add(F);
    end;
  SetLength(Fields,n);
end;

procedure TSQLDBConnectionProperties.GetTableNames(var Tables: TRawUTF8DynArray);
var SQL: RawUTF8;
    count: integer;
begin
  SetLength(Tables,0);
  SQL := SQLGetTableNames;
  if SQL<>'' then
    with Execute(SQL,[]) do begin
      count := 0;
      while Step do
        AddSortedRawUTF8(Tables,count,ColumnUTF8(0));
      SetLength(Tables,count);
    end;
end;

function TSQLDBConnectionProperties.SQLGetField(const aTableName: RawUTF8): RawUTF8;
begin
  result := ''; // won't retrieve anything with this default implementation
end;

function TSQLDBConnectionProperties.SQLGetTableNames: RawUTF8;
begin
  result := ''; // won't retrieve anything with this default implementation
end;

function TSQLDBConnectionProperties.ColumnTypeNativeToDB(
  const aNativeType: RawUTF8; aScale: integer): TSQLDBFieldType;
begin
  Result := ftUTF8;
end;

function TSQLDBConnectionProperties.GetForeignKey(const aTableName,
  aColumnName: RawUTF8): RawUTF8;
begin
  if not fForeignKeys.Initialized then begin
    fForeignKeys.Init(false);
    GetForeignKeys;
  end;
  result := fForeignKeys.Value(aTableName+'.'+aColumnName);
end;

function TSQLDBConnectionProperties.GetForeignKeysData: RawByteString;
begin
  if not fForeignKeys.Initialized then begin
    fForeignKeys.Init(false);
    GetForeignKeys;
  end;
  result := fForeignKeys.BlobData;
end;

procedure TSQLDBConnectionProperties.SetForeignKeysData(const Value: RawByteString);
begin
  if not fForeignKeys.Initialized then 
    fForeignKeys.Init(false);
  fForeignKeys.BlobData := Value;
end;

function TSQLDBConnectionProperties.SQLIso8601ToDate(const Iso8601: RawUTF8): RawUTF8;
begin
  result := ''''+Iso8601+'''';
end;

function TSQLDBConnectionProperties.SQLCreate(const aTableName: RawUTF8;
  const aFields: TSQLDBColumnPropertyDynArray): RawUTF8;
var i: integer;
    F: RawUTF8;
const EXE_FMT: PUTF8Char = 'CREATE TABLE % (RowID % PRIMARY KEY, %)'; // Delphi 5
begin
  result := '';
  if high(aFields)<0 then
    exit; // nothing to create
  for i := 0 to high(aFields) do begin
    F := SQLFieldCreate(aFields[i]);
    if i<>high(aFields) then
      F := F+',';
    result := result+F;
  end;
  result := FormatUTF8(EXE_FMT,[aTableName,fSQLCreateField[ftInt64],result]);
end;

function TSQLDBConnectionProperties.SQLFieldCreate(const aField: TSQLDBColumnProperty): RawUTF8;
begin
  if (aField.ColumnType=ftUTF8) and (aField.ColumnAttr-1<fSQLCreateFieldMax) then
    result := FormatUTF8(pointer(fSQLCreateField[ftNull]),[aField.ColumnAttr]) else
    result := fSQLCreateField[aField.ColumnType];
  if aField.ColumnNonNullable then
    result := result+' NOT NULL';
  result := aField.ColumnName+result;
end;

function TSQLDBConnectionProperties.SQLAddColumn(const aTableName: RawUTF8;
  const aField: TSQLDBColumnProperty): RawUTF8;
const EXE_FMT: PUTF8Char = 'ALTER TABLE % ADD %'; // Delphi 5
begin
  result := FormatUTF8(EXE_FMT,[aTableName,SQLFieldCreate(aField)]);
end;

function TSQLDBConnectionProperties.SQLAddIndex(const aTableName: RawUTF8;
  const aFieldNames: array of RawUTF8; aUnique: boolean;
  const aIndexName: RawUTF8): RawUTF8;
const EXE_FMT: PUTF8Char = 'CREATE %INDEX % ON %(%)'; // Delphi 5
var IndexName: RawUTF8;
begin
  result := '';
  if (self=nil) or (aTableName='') or (high(aFieldNames)<0) then
    exit;
  if aUnique then
    result := 'UNIQUE ';
  if aIndexName='' then
    IndexName := 'Index'+aTableName+RawUTF8ArrayToCSV(aFieldNames,'') else
    IndexName := aIndexName;
  result := FormatUTF8(EXE_FMT,
    [result,IndexName,aTableName,RawUTF8ArrayToCSV(aFieldNames,',')]);
end;


{ TSQLDBConnectionPropertiesThreadSafe }

constructor TSQLDBConnectionPropertiesThreadSafe.Create(const aServerName,
  aDatabaseName, aUserID, aPassWord: RawUTF8);
begin
  fConnectionPool := TObjectList.Create;
  inherited;
end;

function TSQLDBConnectionPropertiesThreadSafe.CurrentThreadConnection: TSQLDBConnection;
var i: integer;
begin
  i := CurrentThreadConnectionIndex;
  if i<0 then
    result := nil else
    result := fConnectionPool.List[i];
end;

function TSQLDBConnectionPropertiesThreadSafe.CurrentThreadConnectionIndex: Integer;
var ID: DWORD;
begin
  ID := GetCurrentThreadId;
  if self<>nil then
  for result := 0 to fConnectionPool.Count-1 do
    if TSQLDBConnectionThreadSafe(fConnectionPool.List[result]).fThreadID=ID then
      exit;
  result := -1;
end;

destructor TSQLDBConnectionPropertiesThreadSafe.Destroy;
begin
  FreeAndNil(fConnectionPool);
  inherited;
end;

procedure TSQLDBConnectionPropertiesThreadSafe.EndCurrentThread;
var i: integer;
begin
  i := CurrentThreadConnectionIndex;
  if i>=0 then
    fConnectionPool.Delete(i);
end;

function TSQLDBConnectionPropertiesThreadSafe.ThreadSafeConnection: TSQLDBConnection;
begin
  result := CurrentThreadConnection;
  if result<>nil then
    exit;
  result := NewConnection;
  (result as TSQLDBConnectionThreadSafe).fThreadID := GetCurrentThreadId;
  fConnectionPool.Add(result);
end;

{ TSQLDBStatement }

procedure TSQLDBStatement.Bind(const Params: TVarDataDynArray; IO: TSQLDBParamInOutType);
var p: integer;
begin
  if self<>nil then
  for p := 1 to length(Params) do
    with Params[p-1] do
    case VType of
      varNull:   BindNull(p,IO);
      varInt64:  Bind(p,VInt64,IO);
      varDouble: Bind(p,VDouble,IO);
      varString: BindTextP(p,PUTF8Char(VAny),IO);
      varAny:    BindBlob(p,VAny,VLongs[0],IO);
    end;
end;

procedure TSQLDBStatement.Bind(const Params: array of const;
  IO: TSQLDBParamInOutType);
var i: integer;
begin
  for i := 1 to high(Params)+1 do
  with Params[i-1] do // bind parameter index starts at 1
  case VType of
    vtString:     // expect WinAnsi String for ShortString
      BindTextU(i,WinAnsiToUtf8(@VString^[1],ord(VString^[0])),IO);
    vtAnsiString: // expect UTF-8 content only for AnsiString
      BindTextU(i,RawUTF8(VAnsiString),IO);
    vtPChar:      BindTextP(i,PUTF8Char(VPChar),IO);
    vtChar:       BindTextU(i,RawUTF8(VChar),IO);
    vtWideChar:   BindTextU(i,RawUnicodeToUtf8(@VWideChar,1),IO);
    vtPWideChar:  BindTextU(i,RawUnicodeToUtf8(VPWideChar,StrLenW(VPWideChar)),IO);
    vtWideString: BindTextW(i,WideString(VWideString),IO);
{$ifdef UNICODE}
    vtUnicodeString: BindTextS(i,string(VUnicodeString),IO);
{$endif}
    vtBoolean:    Bind(i,integer(VBoolean),IO);
    vtInteger:    Bind(i,VInteger,IO);
    vtInt64:      Bind(i,VInt64^,IO);
    vtCurrency:   BindCurrency(i,VCurrency^,IO);
    vtExtended:   Bind(i,VExtended^,IO);
  end;
end;

procedure TSQLDBStatement.BindVariant(Param: Integer; const Data: Variant;
  DataIsBlob: boolean; IO: TSQLDBParamInOutType);
begin
  case TVarData(Data).VType of
    varNull:
      BindNull(Param,IO);
    varSmallint, {$ifndef DELPHI5OROLDER}varShortInt, varWord,{$endif} varByte:
      Bind(Param,integer(Data),IO);
    varInteger:
      Bind(Param,TVarData(Data).VInteger,IO);
    varInt64:
      Bind(Param,TVarData(Data).VInt64,IO);
    varSingle:
      Bind(Param,double(Data),IO);
    varDouble:
      Bind(Param,TVarData(Data).VDouble,IO);
    varDate:
      BindDateTime(Param,TVarData(Data).VDate,IO);
    varCurrency:
      BindCurrency(Param,TVarData(Data).VCurrency,IO);
    else
    if DataIsBlob then
      // no conversion if was set via TQuery.AsBlob property e.g.
      BindBlob(Param,RawByteString(Data),IO) else
      // also use TEXT for any non native VType parameter
      BindTextW(Param,WideString(Data),IO);
  end;
end;

procedure TSQLDBStatement.CheckCol(Col: integer);
begin
  if (self=nil) or (cardinal(Col)>=cardinal(fColumnCount)) then
    raise ESQLDBException.CreateFmt('Invalid call to Column*(Col=%d)',[Col]);
end;

constructor TSQLDBStatement.Create(aConnection: TSQLDBConnection);
begin
  // SynDBLog.Enter(self);
  inherited Create;
  fConnection := aConnection;
end;

function TSQLDBStatement.ColumnCount: integer;
begin
  if self=nil then
    result := 0 else
    result := fColumnCount;
end;

function TSQLDBStatement.ColumnVariant(Col: integer): Variant;
begin
  ColumnToVariant(Col,result);
end;

function TSQLDBStatement.ColumnTimeStamp(Col: integer): TTimeLog;
begin
  case ColumnType(Col) of // will call GetCol() to check Col
    ftNull:  result := 0;
    ftInt64: result := ColumnInt(Col);
    ftDate:  PIso8601(@result)^.From(ColumnDateTime(Col));
    else     PIso8601(@result)^.From(ColumnUTF8(Col));
  end;
end;

function TSQLDBStatement.ColumnTimeStamp(const ColName: RawUTF8): TTimeLog;
begin
  result := ColumnTimeStamp(ColumnIndex(ColName));
end;

function TSQLDBFieldTypeToString(aType: TSQLDBFieldType): string;
var PS: PShortString;
begin
{$ifndef PUREPASCAL}
  if cardinal(aType)<=Cardinal(high(aType)) then begin
    PS := GetEnumName(TypeInfo(TSQLDBFieldType),ord(aType));
    result := Ansi7ToString(@PS^[3],ord(PS^[0])-2);
  end else
{$endif}
    result := IntToStr(ord(aType));
end;

procedure TSQLDBStatement.ColumnsToJSON(WR: TJSONWriter);
var col: integer;
    blob: RawByteString;
begin
  if WR.Expand then
    WR.Add('{');
  for col := 0 to fColumnCount-1 do begin
    if WR.Expand then
      WR.AddFieldName(ColumnName(col)); // add '"ColumnName":'
    if ColumnNull(col) then
      WR.AddShort('null') else
    case ColumnType(col) of
      ftNull:     WR.AddShort('null');
      ftInt64:    WR.Add(ColumnInt(col));
      ftDouble:   WR.Add(ColumnDouble(col));
      ftCurrency: WR.AddCurr64(ColumnCurrency(col));
      ftDate: begin
        WR.Add('"');
        WR.AddDateTime(ColumnDateTime(col));
        WR.Add('"');
      end;
      ftUTF8: begin
        WR.Add('"');
        WR.AddJSONEscape(pointer(ColumnUTF8(col)));
        WR.Add('"');
      end;
      ftBlob: begin
        blob := ColumnBlob(col);
        WR.WrBase64(pointer(blob),length(blob),true); // withMagic=true
      end;
      else raise ESQLDBException.CreateFmt('%s: Invalid ColumnType() %s',
        [ClassName,TSQLDBFieldTypeToString(ColumnType(col))]);
    end;
    WR.Add(',');
  end;
  WR.CancelLastComma; // cancel last ','
  if WR.Expand then
    WR.Add('}');
end;

function TSQLDBStatement.ColumnToVariant(Col: integer; var Value: Variant): TSQLDBFieldType;
begin
  result := ColumnType(Col); // will call GetCol() to check Col
  case result of
    ftNull:     Value := Null;
    ftInt64:    Value := {$ifdef DELPHI5OROLDER}integer{$endif}(ColumnInt(Col));
    ftDouble:   Value := ColumnDouble(Col);
    ftDate:     Value := ColumnDateTime(Col);
    ftCurrency: Value := ColumnCurrency(Col);
    ftBlob:     Value := ColumnBlob(Col);
    ftUTF8:     Value := UTF8ToSynUnicode(ColumnUTF8(Col));
    else raise ESQLDBException.CreateFmt('%s.ColumnToVariant: Invalid Type "%s"',
      [ClassName,TSQLDBFieldTypeToString(result)]);
  end;
end;

function TSQLDBStatement.ColumnToVarData(Col: Integer; var Value: TVarData;
  var Temp: RawByteString): TSQLDBFieldType;
// TVarData handled types are varNull, varInt64, varDouble, varString
// (mapping a constant PUTF8Char), and varAny (BLOB with size = VLongs[0])
const MAP: array[TSQLDBFieldType] of word = (
   varNull,varNull,varInt64,varDouble,varDouble,varString,varString,varAny);
// ftUnknown, ftNull, ftInt64, ftDouble, ftCurrency, ftDate, ftUTF8, ftBlob
begin
  result := ColumnType(Col); // will call GetCol() to check Col
  Value.VType := MAP[result];
  case result of
    ftInt64:    Value.VInt64  := ColumnInt(Col);
    ftCurrency: Value.VDouble := ColumnCurrency(Col);
    ftDouble:   Value.VDouble := ColumnDouble(Col);
    ftDate: begin // date time as TEXT (idem TSQLDBStatement.ColumnsToJSON)
      Temp := DateTimeToIso8601(ColumnDateTime(Col),True,'T');
      Value.VString := Pointer(Temp);
    end;
    ftUTF8: begin
      Temp := ColumnUTF8(Col);
      Value.VString := Pointer(Temp);
    end;
    ftBlob: begin
      Temp := ColumnBlob(Col);
      Value.VLongs[0] := length(Temp);
      Value.VAny := pointer(Temp);
    end;
  end;
end;

function TSQLDBStatement.ColumnToTypedValue(Col: integer;
  DestType: TSQLDBFieldType; var Dest): TSQLDBFieldType;
var Temp: Variant;
begin
  result := ColumnToVariant(Col,Temp); 
  case DestType of
  ftInt64:    {$ifdef DELPHI5OROLDER}integer{$else}Int64{$endif}(Dest) := Temp;
  ftDouble:   Double(Dest) := Temp;
  ftCurrency: Currency(Dest) := Temp;
  ftDate:     TDateTime(Dest) := Temp;
  ftUTF8:     RawUTF8(Dest) := StringToUTF8(Temp);
  ftBlob:     TBlobData(Dest) := TBlobData(Temp);
    else raise ESQLDBException.CreateFmt('%s.ColumnToTypedValue: Invalid Type "%s"',
      [ClassName,TSQLDBFieldTypeToString(result)]);
  end;
end;

function TSQLDBStatement.ParamToVariant(Param: Integer; var Value: Variant;
  CheckIsOutParameter: boolean=true): TSQLDBFieldType;
begin
  dec(Param); // start at #1
  if (self=nil) or (cardinal(Param)>=cardinal(fParamCount)) then
    raise ESQLDBException.CreateFmt('ParamToVariant(%d)',[Param]);
  // overriden method should fill Value with proper data
  result := ftUnknown;
end;

procedure TSQLDBStatement.Execute(const aSQL: RawUTF8; ExpectResults: Boolean);
begin
  Prepare(aSQL,ExpectResults);
  ExecutePrepared;
end;

function TSQLDBStatement.FetchAllToJSON(JSON: TStream; Expanded: boolean): PtrInt;
var W: TJSONWriter;
    col: integer;
begin
  result := 0;
  W := TJSONWriter.Create(JSON,Expanded,false);
  try
    // get col names and types
    SetLength(W.ColNames,ColumnCount);
    for col := 0 to ColumnCount-1 do
      W.ColNames[col] := ColumnName(col);
    W.AddColumns; // write or init field names for appropriate JSON Expand
    if Expanded then
      W.Add('[');
    // write rows data
    while Step do begin
      ColumnsToJSON(W);
      W.Add(',');
      inc(result);
    end;
    W.CancelLastComma; // cancel last ','
    W.Add(']');
    if not Expanded then
      W.Add('}');
    W.Add(#10);
    W.Flush;
  finally
    W.Free;
  end;
end;

function TSQLDBStatement.FetchAllAsJSON(Expanded: boolean; ReturnedRowCount: PPtrInt=nil): RawUTF8;
var Stream: TRawByteStringStream;
    RowCount: PtrInt;
begin
  Stream := TRawByteStringStream.Create;
  try
    RowCount := FetchAllToJSON(Stream,Expanded);
    if ReturnedRowCount<>nil then
      ReturnedRowCount^ := RowCount;
    result := Stream.DataString;
  finally
    Stream.Free;
  end;
end;

procedure TSQLDBStatement.Execute(const aSQL: RawUTF8;
  ExpectResults: Boolean; const Params: array of const);
begin
  Prepare(aSQL,ExpectResults);
  Bind(Params);
  ExecutePrepared;
end;

procedure TSQLDBStatement.Execute(SQLFormat: PUTF8Char;
  ExpectResults: Boolean; const Args, Params: array of const);
begin
  Execute(FormatUTF8(SQLFormat,Args),ExpectResults,Params);
end;

function TSQLDBStatement.GetUpdateCount: integer;
begin
  result := 0;
end;

function TSQLDBStatement.ColumnString(Col: integer): string;
begin
  Result := UTF8ToString(ColumnUTF8(Col));
end;

function TSQLDBStatement.ColumnString(const ColName: RawUTF8): string;
begin
  result := ColumnString(ColumnIndex(ColName));
end;

function TSQLDBStatement.ColumnBlob(const ColName: RawUTF8): RawByteString;
begin
  result := ColumnBlob(ColumnIndex(ColName));
end;

function TSQLDBStatement.ColumnCurrency(const ColName: RawUTF8): currency;
begin
  result := ColumnCurrency(ColumnIndex(ColName));
end;

function TSQLDBStatement.ColumnDateTime(const ColName: RawUTF8): TDateTime;
begin
  result := ColumnDateTime(ColumnIndex(ColName));
end;

function TSQLDBStatement.ColumnDouble(const ColName: RawUTF8): double;
begin
  result := ColumnDouble(ColumnIndex(ColName));
end;

function TSQLDBStatement.ColumnInt(const ColName: RawUTF8): Int64;
begin
  result := ColumnInt(ColumnIndex(ColName));
end;

function TSQLDBStatement.ColumnUTF8(const ColName: RawUTF8): RawUTF8;
begin
  result := ColumnUTF8(ColumnIndex(ColName));
end;

function TSQLDBStatement.ColumnVariant(const ColName: RawUTF8): Variant;
begin
  ColumnToVariant(ColumnIndex(ColName),result);
end;

function TSQLDBStatement.GetColumnVariant(const ColName: RawUTF8): Variant;
begin
  ColumnToVariant(ColumnIndex(ColName),result);
end;

function TSQLDBStatement.Instance: TSQLDBStatement;
begin
  Result := Self;
end;

function TSQLDBStatement.GetSQLWithInlinedParams: RawUTF8;
var P,B: PAnsiChar;
    tmp: RawUTF8;
    num: integer;
begin
  result := '';
  num := 0;
  P := PAnsiChar(fSQL); // P^ := ' ' below -> ensure unique
  if P<>nil then
  repeat
    B := P;
    while not (P^ in ['?',#0]) do begin
      case P^ of
      '''':
        if P[1]<>'''' then begin
          repeat // ignore chars inside ' quotes
            inc(P);
          until P^ in ['''',#0];
          if P^=#0 then break;
        end;
      #1..#31:
        P^ := ' '; // convert #13/#10 into ' '
      end;
      inc(P);
    end;
    SetString(tmp,B,P-B);
    if P^=#0 then begin
      result := result+tmp;
      exit;
    end;
    inc(num);
    result := result+tmp+GetParamValueAsText(num); // Params start at #1
    inc(P); // jump '?'
  until P^=#0;
end;

function TSQLDBStatement.GetParamValueAsText(Param: integer): RawUTF8;
var V: Variant;
begin
  if cardinal(Param-1)>=cardinal(fParamCount) then
    result := '???' else begin
    case ParamToVariant(Param,V,false) of
    ftUnknown: result := '???';
    ftNull:    result := 'NULL';
    ftDate:    result := DateTimeToIso8601Text(V);
    ftUTF8: begin
      result := RawUTF8(V);
      if length(result)>4096 then // truncate very long TEXT in log
        result := copy(result,1,4096)+'...';
      result := ''''+result+'''';
    end;
    ftBlob:    result := '*BLOB*';
    else       result := RawUTF8(V);
    end;
  end;
end;

{$ifndef DELPHI5OROLDER}
var
  SQLDBRowVariantType: TCustomVariantType = nil;

function TSQLDBStatement.RowData: Variant;
begin
  if SQLDBRowVariantType=nil then
    SQLDBRowVariantType := SynRegisterCustomVariantType(TSQLDBRowVariantType);
  VarClear(result);
  with TVarData(result) do begin
    VType := SQLDBRowVariantType.VarType;
    VPointer := self;
  end;
end;
{$endif}

procedure TSQLDBStatement.Prepare(const aSQL: RawUTF8;
  ExpectResults: Boolean);
begin
  fSQL := aSQL;
  fExpectResults := ExpectResults;
  if not fConnection.IsConnected then
    fConnection.Connect;
end;

procedure TSQLDBStatement.Reset;
begin
  // a do-nothing default method (used e.g. for OCI)
end;


{$ifndef DELPHI5OROLDER}

{ TSQLDBRowVariantType }

procedure TSQLDBRowVariantType.Clear(var V: TVarData);
begin
  SimplisticClear(V);
end;

procedure TSQLDBRowVariantType.Copy(var Dest: TVarData;
  const Source: TVarData; const Indirect: Boolean);
begin
  if Indirect then
    SimplisticCopy(Dest,Source,true) else
    Move(Source,Dest,sizeof(TVarData));
end;

procedure TSQLDBRowVariantType.IntGet(var Dest: TVarData;
  const V: TVarData; Name: PAnsiChar);
var Rows: TSQLDBStatement;
begin
  Rows := TSQLDBStatement(TVarData(V).VPointer);
  if Rows=nil then
    ESQLDBException.Create('Invalid SQLDBRowVariant call');
  Rows.ColumnToVariant(Rows.ColumnIndex(RawByteString(Name)),Variant(Dest));
end;

procedure TSQLDBRowVariantType.IntSet(const V, Value: TVarData;
  Name: PAnsiChar);
begin
  ESQLDBException.Create('SQLDBRowVariant is read-only');
end;

{$endif}

{ TSQLDBStatementWithParams }

function TSQLDBStatementWithParams.CheckParam(Param: Integer;
  NewType: TSQLDBFieldType; IO: TSQLDBParamInOutType): PSQLDBParam;
begin
  if self=nil then
    raise ESQLDBException.Create('Invalid Bind*() call');
  if (Param<=0) or (Param>64) then
    raise ESQLDBException.CreateFmt('Bind*(%d) should be 1..64',[Param]);
  if Param>fParamCount then
    fParam.Count := Param; // resize fParams[] dynamic array if necessary
  result := @fParams[Param-1];
  result^.VType := NewType;
  result^.VInOut := IO;
end;

constructor TSQLDBStatementWithParams.Create(aConnection: TSQLDBConnection);
begin
  inherited Create(aConnection);
  fParam.Init(TypeInfo(TSQLDBParamDynArray),fParams,@fParamCount);
end;

procedure TSQLDBStatementWithParams.Bind(Param: Integer; Value: double;
  IO: TSQLDBParamInOutType);
begin
  CheckParam(Param,ftDouble,IO)^.VInt64 := PInt64(@Value)^;
end;

procedure TSQLDBStatementWithParams.Bind(Param: Integer; Value: Int64;
  IO: TSQLDBParamInOutType);
begin
  CheckParam(Param,ftInt64,IO)^.VInt64 := Value;
end;

procedure TSQLDBStatementWithParams.BindBlob(Param: Integer;
  const Data: RawByteString; IO: TSQLDBParamInOutType);
begin
  CheckParam(Param,ftBlob,IO)^.VData := Data;
end;

procedure TSQLDBStatementWithParams.BindBlob(Param: Integer; Data: pointer;
  Size: integer; IO: TSQLDBParamInOutType);
begin
  SetString(CheckParam(Param,ftBlob,IO)^.VData,PAnsiChar(Data),Size);
end;

procedure TSQLDBStatementWithParams.BindCurrency(Param: Integer;
  Value: currency; IO: TSQLDBParamInOutType);
begin
  CheckParam(Param,ftCurrency,IO)^.VInt64 := PInt64(@Value)^;
end;

procedure TSQLDBStatementWithParams.BindDateTime(Param: Integer;
  Value: TDateTime; IO: TSQLDBParamInOutType);
begin
  CheckParam(Param,ftDate,IO)^.VInt64 := PInt64(@Value)^;
end;

procedure TSQLDBStatementWithParams.BindNull(Param: Integer;
  IO: TSQLDBParamInOutType);
begin
  CheckParam(Param,ftNull,IO);
end;

procedure TSQLDBStatementWithParams.BindTextS(Param: Integer;
  const Value: string; IO: TSQLDBParamInOutType);
begin
  CheckParam(Param,ftUTF8,IO)^.VData := StringToUTF8(Value);
end;

procedure TSQLDBStatementWithParams.BindTextU(Param: Integer;
  const Value: RawUTF8; IO: TSQLDBParamInOutType);
begin
  CheckParam(Param,ftUTF8,IO)^.VData := Value;
end;

procedure TSQLDBStatementWithParams.BindTextP(Param: Integer;
  Value: PUTF8Char; IO: TSQLDBParamInOutType);
begin
  SetString(CheckParam(Param,ftUTF8,IO)^.VData,PAnsiChar(Value),StrLen(Value));
end;

procedure TSQLDBStatementWithParams.BindTextW(Param: Integer;
  const Value: WideString; IO: TSQLDBParamInOutType);
begin
  CheckParam(Param,ftUTF8,IO)^.VData := RawUnicodeToUtf8(pointer(Value),length(Value));
end;

function TSQLDBStatementWithParams.ParamToVariant(Param: Integer;
  var Value: Variant; CheckIsOutParameter: boolean): TSQLDBFieldType;
begin
  inherited ParamToVariant(Param,Value); // raise exception if Param incorrect
  dec(Param); // start at #1
  if CheckIsOutParameter and (fParams[Param].VInOut=paramIn) then
    raise ESQLDBException.CreateFmt('%s.ParamToVariant expects an [In]Out parameter',[ClassName]);
  // OleDB provider should have already modified the parameter in-place, i.e.
  // in our fParams[] buffer, especialy for TEXT parameters (OleStr/WideString)
  // -> we have nothing to do but return the current value! :)
  with fParams[Param] do begin
    result := VType;
    case VType of
      ftInt64:     Value := {$ifdef DELPHI5OROLDER}integer{$endif}(VInt64);
      ftDouble:    Value := PDouble(@VInt64)^;
      ftCurrency:  Value := PCurrency(@VInt64)^;
      ftDate:      Value := PDateTime(@VInt64)^;
      ftUTF8:      Value := RawUTF8(VData);
      ftBlob:      Value := VData;
      else         Value := Null;
    end;
  end;
end;


{ TSQLDBStatementWithParamsAndColumns }

function TSQLDBStatementWithParamsAndColumns.ColumnIndex(const aColumnName: RawUTF8): integer;
begin
  result := fColumn.FindHashed(aColumnName);
end;

function TSQLDBStatementWithParamsAndColumns.ColumnName(Col: integer): RawUTF8;
begin
  CheckCol(Col);
  result := fColumns[Col].ColumnName;
end;

function TSQLDBStatementWithParamsAndColumns.ColumnType(Col: integer): TSQLDBFieldType;
begin
  CheckCol(Col);
  result := fColumns[Col].ColumnType;
end;

constructor TSQLDBStatementWithParamsAndColumns.Create(aConnection: TSQLDBConnection);
begin
  inherited Create(aConnection);
  fColumn.Init(TypeInfo(TSQLDBColumnPropertyDynArray),fColumns,nil,nil,nil,@fColumnCount,True);
end;

procedure TSQLDBStatementWithParamsAndColumns.Reset;
begin
  fColumn.Clear;
end;


procedure LogTruncatedColumn(const Col: TSQLDBColumnProperty);
begin
  {$ifdef DELPHI5OROLDER}
  SynDBLog.Add.Log(sllDB,'Truncated column '+Col.ColumnName);
  {$else}
  SynDBLog.Add.Log(sllDB,'Truncated column %',Col.ColumnName);
  {$endif}
end;

{ TSQLDBLib }

destructor TSQLDBLib.Destroy;
begin
  if Handle<>0 then
    FreeLibrary(Handle);
  inherited;
end;

{ shared Oracle functions, used by both SynDBOracle and SynOleDB }

function OracleSQLGetField(const aTableName: RawUTF8): RawUTF8;
const EXE_FMT: PUTF8Char =
  'select c.column_name, c.data_type, c.data_length, c.data_precision, c.data_scale, '+
  ' (select count(*) from sys.all_indexes a, sys.all_ind_columns b'+
  '  where a.table_owner=c.owner and a.table_name=c.table_name and b.column_name=c.column_name'+
  '  and a.owner=b.index_owner and a.index_name=b.index_name and'+
  '  a.table_owner=b.table_owner and a.table_name=b.table_name) index_count'+
  ' from sys.all_tab_columns c'+
  ' where c.owner like ''%'' and c.table_name like ''%'';';
var Owner, Table: RawUTF8;
begin
  Split(aTableName,'.',Owner,Table);
  result := FormatUTF8(EXE_FMT,[Owner,Table]);
end;

function OracleColumnTypeNativeToDB(const aNativeType: RawUTF8; aScale: integer): TSQLDBFieldType;
begin
  if PosEx('CHAR',aNativeType)>0 then
    result := ftUTF8 else
  if IdemPropNameU(aNativeType,'NUMBER') then
    case aScale of
         0: result := ftInt64;
      1..4: result := ftCurrency;
    else    result := ftDouble;
    end else
  if (PosEx('RAW',aNativeType)>0) or IdemPropNameU(aNativeType,'BLOB') or
     IdemPropNameU(aNativeType,'BFILE') then
    result := ftBlob else
  if IdemPChar(pointer(aNativeType),'BINARY_') or
     IdemPropNameU(aNativeType,'FLOAT') then
    result := ftDouble else
  if IdemPropNameU(aNativeType,'DATE') or
     IdemPChar(pointer(aNativeType),'TIMESTAMP') then
    result := ftDate else
    // all other types will be converted to text
    result := ftUTF8;
end;

function OracleSQLIso8601ToDate(Iso8601: RawUTF8): RawUTF8;
begin
  if length(Iso8601)>10 then
    Iso8601[11] := ' '; // 'T' -> ' '
  result := 'to_date('''+Iso8601+''',''YYYY-MM-DD HH24:MI:SS'')'; // from Iso8601
end;


initialization
  assert(SizeOf(TSQLDBColumnProperty)=sizeof(PTrUInt)*2+8);
  assert(SizeOf(TSQLDBParam)=sizeof(PTrUInt)*2+sizeof(Int64));
end.
