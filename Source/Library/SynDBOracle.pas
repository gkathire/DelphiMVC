/// Oracle DB direct access classes (via OCI)
// - this unit is a part of the freeware Synopse mORMot framework,
// licensed under a MPL/GPL/LGPL tri-license; version 1.16
unit SynDBOracle;

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

  Version 1.15
  - first public release, corresponding to mORMot Framework 1.15

  Version 1.16
  - LONG columns will be handled as ftUTF8 fields, truncated to 32 KB of text
    (fix error ORA-00932 at OCI client level)

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

{ -------------- Oracle Client Interface native connection  }

type
  /// execption type associated to the native Oracle Client Interface (OCI)
  ESQLDBOracle = class(Exception);

  POracleDate = ^TOracleDate;
  {$A-}
  /// memory structure used to store a date and time in native Oracle format
  // - follow the SQLT_DAT column type layout
  TOracleDate = object
  public
    Cent, Year, Month, Day, Hour, Min, Sec: byte;
    /// convert an Oracle date and time into Delphi TDateTime
    function ToDateTime: TDateTime;
    /// convert an Oracle date and time into its textual expanded ISO-8601
    // - will fill up to 21 characters, including double quotes
    function ToIso8601(Dest: PUTF8Char): integer;
    /// convert Delphi TDateTime into native Oracle date and time format
    procedure From(const aValue: TDateTime);
  end;
  {$A+}

  /// will implement properties shared by native Oracle Client Interface connections
  // - inherited from TSQLDBConnectionPropertiesThreadSafe so that the oci.dll
  // library is not initialized with OCI_THREADED: this could make the process
  // faster on multi-core CPU and a multi-threaded server application
  TSQLDBOracleConnectionProperties = class(TSQLDBConnectionPropertiesThreadSafe)
  protected
    fCodePage: cardinal;
    fBlobPrefetchSize: Integer;
    fStatementCacheSize: integer;
    fInternalBufferSize: integer;
    function GetClientVersion: RawUTF8;
    /// get all field/column names for a specified Oracle Table
    function SQLGetField(const aTableName: RawUTF8): RawUTF8; override;
    /// get all Oracle table names
    function SQLGetTableNames: RawUTF8; override;
    /// convert a textual column data type, as retrieved e.g. from SQLGetField,
    // into our internal primitive types
    function ColumnTypeNativeToDB(const aNativeType: RawUTF8; aScale: integer): TSQLDBFieldType; override;
    /// initialize fForeignKeys content with all foreign keys of this DB
    // - used by GetForeignKey method
    procedure GetForeignKeys; override;
  public
    /// initialize the OCI connection properties
    // - we don't need a database name parameter for Oracle connection
    // - you may specify the TNSName in aServerName, or a connection string
    // like '//host[:port]/[service_name]', e.g. '//sales-server:1523/sales'
    // - since the OCI client will make conversion when returning column data,
    // to avoid any truncate when retrieving VARCHAR2 or CHAR fields into the
    // internal fixed-sized buffer, you may specify here the exact database
    // code page, as existing on the server (e.g. CODEPAGE_US=1252 for default
    // WinAnsi western encoding)
    constructor Create(const aServerName, aUserID, aPassWord: RawUTF8; aCodePage: integer); reintroduce; virtual;
    /// create a new connection
    // - call this method if the shared MainConnection is not enough (e.g. for
    // multi-thread access)
    // - the caller is responsible of freeing this instance
    // - this overriden method will create an TSQLDBOracleConnection instance
    function NewConnection: TSQLDBConnection; override;
    /// convert an ISO-8601 encoded time and date into a date appropriate to
    // be pasted in the SQL request
    // - returns to_date('....','YYYY-MM-DD HH24:MI:SS') for Oracle
    function SQLIso8601ToDate(const Iso8601: RawUTF8): RawUTF8; override;
  published
    /// returns the Client version e.g. '11.2.0.1 at oci.dll'
    property ClientVersion: RawUTF8 read GetClientVersion;
    /// the code page used for the connection
    // - e.g. 1252 for default CODEPAGE_US
    // - connection is opened globaly as UTF-8, to match the internal encoding
    // of our units; but CHAR / NVARCHAR2 fields will use this code page encoding
    // to avoid any column truncation when retrieved from the server 
    property CodePage: cardinal read fCodePage;
    /// the size (in bytes) of the internal buffer used to retrieve rows in statements
    // - default is 128 KB, which gives very good results
    property InternalBufferSize: integer read fInternalBufferSize write fInternalBufferSize;
    /// the size (in bytes) of LOB prefecth
    // - is set to 4096 (4 KB) by default, but may be changed for tuned performance
    property BlobPrefetchSize: integer read fBlobPrefetchSize write fBlobPrefetchSize;
    /// the number of prepared statements cached by OCI on the Client side
    // - is set to 30 by default
    property StatementCacheSize: integer read fStatementCacheSize write fStatementCacheSize;
  end;
  
  /// implements a direct connection to the native Oracle Client Interface (OCI)
  TSQLDBOracleConnection = class(TSQLDBConnectionThreadSafe)
  protected
    fEnv: pointer;
    fError: pointer;
    fServer: pointer;
    fContext: pointer;
    fSession: pointer;
    fTrans: pointer;
    fOCICharSet: integer;
    function IsConnected: boolean; override;
    procedure STRToUTF8(P: PAnsiChar; var result: RawUTF8);
    {$ifndef UNICODE}
    procedure STRToAnsiString(P: PAnsiChar; var result: AnsiString);
    {$endif}
  public
    /// prepare a connection to a specified Oracle database server
    constructor Create(aProperties: TSQLDBConnectionProperties); override;
    /// release memory and connection
    destructor Destroy; override;
    /// connect to the specified Oracle database server
    // - should raise an Exception on error
    // - the connection will be globaly opened with UTF-8 encoding; for CHAR /
    // NVARCHAR2 fields, the TSQLDBOracleConnectionProperties.CodePage encoding
    // will be used instead, to avoid any truncation during data retrieval
    // - BlobPrefetchSize and StatementCacheSize fiel values of the associated
    // properties will be used to tune the opened connection
    procedure Connect; override;
    /// stop connection to the specified Oracle database server
    // - should raise an Exception on error
    procedure Disconnect; override;
    /// initialize a new SQL query statement for the given connection
    // - the caller should free the instance after use
    function NewStatement: TSQLDBStatement; override;
    /// begin a Transaction for this connection
    // - current implementation do not support nested transaction with those
    // methods: exception will be raised in such case
    // - by default, TSQLDBOracleStatement works in AutoCommit mode, unless
    // StartTransaction is called
    procedure StartTransaction; override;
    /// commit changes of a Transaction for this connection
    // - StartTransaction method must have been called before
    procedure Commit; override;
    /// discard changes of a Transaction for this connection
    // - StartTransaction method must have been called before
    procedure Rollback; override;
  end;

  /// implements a statement via the native Oracle Client Interface (OCI)
  // - those statements can be prepared on the Delphi side, but by default
  // we enabled the OCI-side statement cache, not to reinvent the wheel this
  // time
  TSQLDBOracleStatement = class(TSQLDBStatementWithParamsAndColumns)
  protected
    fStatement: pointer;
    fError: pointer;
    fRowCount: cardinal;
    fRowFetched: cardinal;
    fRowFetchedCurrent: cardinal;
    fRowFetchedEnded: boolean;
    fRowBuffer: TByteDynArray;
    fInternalBufferSize: cardinal;
    function GetUpdateCount: integer; override;
    procedure FreeHandles;
    procedure FetchTest(Status: integer);
    /// Col=0...fColumnCount-1
    function GetCol(Col: Integer; out Column: PSQLDBColumnProperty): pointer;
  public
    {{ create an OCI statement instance, from an existing OCI connection
     - the Execute method can be called once per TSQLDBOracleStatement instance,
       but you can use the Prepare once followed by several  ExecutePrepared methods
     - if the supplied connection is not of TOleDBConnection type, will raise
       an exception }
    constructor Create(aConnection: TSQLDBConnection); override;
    {{ release all associated memory and OCI handles }
    destructor Destroy; override;

    {{ Prepare an UTF-8 encoded SQL statement
     - parameters marked as ? will be bound later, before ExecutePrepared call
     - if ExpectResults is TRUE, then Step() and Column*() methods are available
       to retrieve the data rows
     - raise an ESQLDBOracle on any error }
    procedure Prepare(const aSQL: RawUTF8; ExpectResults: Boolean=false); overload; override;
    {{ Execute a prepared SQL statement
     - parameters marked as ? should have been already bound with Bind*() functions
     - raise an ESQLDBOracle on any error }
    procedure ExecutePrepared; override;

    {{ Access the next or first row of data from the SQL Statement result
     - return true on success, with data ready to be retrieved by Column*() methods
     - return false if no more row is available (e.g. if the SQL statement
      is not a SELECT but an UPDATE or INSERT command)
     - if SeekFirst is TRUE, will put the cursor on the first row of results
     - raise an ESQLDBOracle on any error }
    function Step(SeekFirst: boolean=false): boolean; override;
    {{ returns TRUE if the column contains NULL }
    function ColumnNull(Col: integer): boolean; override;
    {{ return a Column integer value of the current Row, first Col is 0 }
    function ColumnInt(Col: integer): Int64; override;
    {{ return a Column floating point value of the current Row, first Col is 0 }
    function ColumnDouble(Col: integer): double; override;
    {{ return a Column date and time value of the current Row, first Col is 0 }
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
    {{ return a Column as a variant
     - this implementation will retrieve the data with no temporary variable
       (since TQuery calls this method a lot, we tried to optimize it)
     - a ftUTF8 content will be mapped into a generic WideString variant
       for pre-Unicode version of Delphi, and a generic UnicodeString (=string)
       since Delphi 2009: you may not loose any data during charset conversion
     - a ftBlob content will be mapped into a TBlobData AnsiString variant }
    function ColumnToVariant(Col: integer; var Value: Variant): TSQLDBFieldType; override;
    {{ append all columns values of the current Row to a JSON stream
     - will use WR.Expand to guess the expected output format
     - fast overriden implementation with no temporary variable 
     - BLOB field value is saved as Base64, in the '"\uFFF0base64encodedbinary"
       format and contains true BLOB data }
    procedure ColumnsToJSON(WR: TJSONWriter); override;
  end;


implementation

{ TOracleDate }

// see http://download.oracle.com/docs/cd/B28359_01/appdev.111/b28395/oci03typ.htm#sthref389

function TOracleDate.ToDateTime: TDateTime;
begin
  result := EncodeDate((Cent-100)*100+Year-100,Month,Day);
  if (Hour<>0) and (Min<>0) and (Sec<>0) then
    result := result+EncodeTime(Hour-1,Min-1,Sec-1,0);
end;

function TOracleDate.ToIso8601(Dest: PUTF8Char): integer;
begin
  Dest^ := '"';
  DateToIso8601PChar(Dest+1,true,(Cent-100)*100+Year-100,Month,Day);
  if (Hour<>0) and (Min<>0) and (Sec<>0) then begin
    TimeToIso8601PChar(Dest+11,true,Hour-1,Min-1,Sec-1,'T');
    result := 21; // we use 'T' as TTextWriter.AddDateTime
  end else
    result := 12; // only date
  Dest[result-1] := '"';
end;

procedure TOracleDate.From(const aValue: TDateTime);
var Y,M,D, HH,MM,SS,MS: word;
begin
  DecodeDate(aValue,Y,M,D);
  DecodeTime(aValue,HH,MM,SS,MS);
  Cent := (Y div 100)+100;
  Year := (Y mod 100)+100;
  Month := M;
  Day := D;
  if (HH<>0) or (MM<>0) or (SS<>0) then begin
    Hour := HH+1;
    Min := MM+1;
    Sec := SS+1;
  end;
end;

{ Native OCI access interface }

type
  { Generic Oracle Types }
  sword   = Integer;
  eword   = Integer;
  uword   = LongInt;
  sb4     = Integer;
  ub4     = LongInt;
  sb2     = SmallInt;
  ub2     = Word;
  sb1     = ShortInt;
  ub1     = Byte;
  dvoid   = Pointer;
  text    = PAnsiChar;
  size_T  = Integer;

  pub1 = ^ub1;
  psb1 = ^sb1;
  pub2 = ^ub2;
  psb2 = ^sb2;
  pub4 = ^ub4;
  psb4 = ^sb4;

  { Handle Types }
  POCIHandle = Pointer;
  PPOCIHandle = ^Pointer;
  POCIEnv = POCIHandle;
  POCIServer = POCIHandle;
  POCIError = POCIHandle;
  POCISvcCtx = POCIHandle;
  POCIStmt = POCIHandle;
  POCIDefine = POCIHandle;
  POCISession = POCIHandle;
  POCIBind = POCIHandle;
  POCIDescribe = POCIHandle;
  POCITrans = POCIHandle;

  { Descriptor Types }
  POCIDescriptor = Pointer;
  PPOCIDescriptor = ^POCIDescriptor;
  POCISnapshot = POCIDescriptor;
  POCILobLocator = POCIDescriptor;
  POCIParam = POCIDescriptor;
  POCIRowid = POCIDescriptor;
  POCIComplexObjectComp = POCIDescriptor;
  POCIAQEnqOptions = POCIDescriptor;
  POCIAQDeqOptions = POCIDescriptor;
  POCIAQMsgProperties = POCIDescriptor;
  POCIAQAgent = POCIDescriptor;
  POCIDate = POCIDescriptor;
  POCIDateTime = POCIDescriptor;
  POCINumber = POCIDescriptor;
  POCIString = POCIDescriptor;

  OCIDuration = ub2;

const
  { OCI Handle Types }
  OCI_HTYPE_FIRST               = 1;
  OCI_HTYPE_ENV                 = 1;
  OCI_HTYPE_ERROR               = 2;
  OCI_HTYPE_SVCCTX              = 3;
  OCI_HTYPE_STMT                = 4;
  OCI_HTYPE_BIND                = 5;
  OCI_HTYPE_DEFINE              = 6;
  OCI_HTYPE_DESCRIBE            = 7;
  OCI_HTYPE_SERVER              = 8;
  OCI_HTYPE_SESSION             = 9;
  OCI_HTYPE_TRANS               = 10;
  OCI_HTYPE_COMPLEXOBJECT       = 11;
  OCI_HTYPE_SECURITY            = 12;
  OCI_HTYPE_SUBSCRIPTION        = 13;
  OCI_HTYPE_DIRPATH_CTX         = 14;
  OCI_HTYPE_DIRPATH_COLUMN_ARRAY = 15;
  OCI_HTYPE_DIRPATH_STREAM      = 16;
  OCI_HTYPE_PROC                = 17;
  OCI_HTYPE_LAST                = 17;

  { OCI Descriptor Types }
  OCI_DTYPE_FIRST               = 50;
  OCI_DTYPE_LOB                 = 50;
  OCI_DTYPE_SNAP                = 51;
  OCI_DTYPE_RSET                = 52;
  OCI_DTYPE_PARAM               = 53;
  OCI_DTYPE_ROWID               = 54;
  OCI_DTYPE_COMPLEXOBJECTCOMP   = 55;
  OCI_DTYPE_FILE                = 56;
  OCI_DTYPE_AQENQ_OPTIONS       = 57;
  OCI_DTYPE_AQDEQ_OPTIONS       = 58;
  OCI_DTYPE_AQMSG_PROPERTIES    = 59;
  OCI_DTYPE_AQAGENT             = 60;
  OCI_DTYPE_LOCATOR             = 61;
  OCI_DTYPE_DATETIME            = 62;
  OCI_DTYPE_INTERVAL            = 63;
  OCI_DTYPE_AQNFY_DESCRIPTOR    = 64;
  OCI_DTYPE_LAST                = 64;
  OCI_DTYPE_DATE                = 65;  { Date }
  OCI_DTYPE_TIME                = 66;  { Time }
  OCI_DTYPE_TIME_TZ             = 67;  { Time with timezone }
  OCI_DTYPE_TIMESTAMP           = 68;  { Timestamp }
  OCI_DTYPE_TIMESTAMP_TZ        = 69;  { Timestamp with timezone }
  OCI_DTYPE_TIMESTAMP_LTZ       = 70;  { Timestamp with local tz }

  { OCI Attributes Types }
  OCI_ATTR_FNCODE               = 1;   // the OCI function code
  OCI_ATTR_OBJECT               = 2;   // is the environment initialized in object mode
  OCI_ATTR_NONBLOCKING_MODE     = 3;   // non blocking mode
  OCI_ATTR_SQLCODE              = 4;   // the SQL verb
  OCI_ATTR_ENV                  = 5;   // the environment handle
  OCI_ATTR_SERVER               = 6;   // the server handle
  OCI_ATTR_SESSION              = 7;   // the user session handle
  OCI_ATTR_TRANS                = 8;   // the transaction handle
  OCI_ATTR_ROW_COUNT            = 9;   // the rows processed so far
  OCI_ATTR_SQLFNCODE            = 10;  // the SQL verb of the statement
  OCI_ATTR_PREFETCH_ROWS        = 11;  // sets the number of rows to prefetch
  OCI_ATTR_NESTED_PREFETCH_ROWS = 12;  // the prefetch rows of nested table
  OCI_ATTR_PREFETCH_MEMORY      = 13;  // memory limit for rows fetched
  OCI_ATTR_NESTED_PREFETCH_MEMORY = 14;// memory limit for nested rows
  OCI_ATTR_CHAR_COUNT           = 15;  // this specifies the bind and define size in characters
  OCI_ATTR_PDSCL                = 16;  // packed decimal scale
  OCI_ATTR_FSPRECISION          = OCI_ATTR_PDSCL; // fs prec for datetime data types
  OCI_ATTR_PDPRC                = 17;  // packed decimal format
  OCI_ATTR_LFPRECISION          = OCI_ATTR_PDPRC; // fs prec for datetime data types
  OCI_ATTR_PARAM_COUNT          = 18;  // number of column in the select list
  OCI_ATTR_ROWID                = 19;  // the rowid
  OCI_ATTR_CHARSET              = 20;  // the character set value
  OCI_ATTR_NCHAR                = 21;  // NCHAR type
  OCI_ATTR_USERNAME             = 22;  // username attribute
  OCI_ATTR_PASSWORD             = 23;  // password attribute
  OCI_ATTR_STMT_TYPE            = 24;  // statement type
  OCI_ATTR_INTERNAL_NAME        = 25;  // user friendly global name
  OCI_ATTR_EXTERNAL_NAME        = 26;  // the internal name for global txn
  OCI_ATTR_XID                  = 27;  // XOPEN defined global transaction id
  OCI_ATTR_TRANS_LOCK           = 28;  //
  OCI_ATTR_TRANS_NAME           = 29;  // string to identify a global transaction
  OCI_ATTR_HEAPALLOC            = 30;  // memory allocated on the heap
  OCI_ATTR_CHARSET_ID           = 31;  // Character Set ID
  OCI_ATTR_CHARSET_FORM         = 32;  // Character Set Form
  OCI_ATTR_MAXDATA_SIZE         = 33;  // Maximumsize of data on the server
  OCI_ATTR_CACHE_OPT_SIZE       = 34;  // object cache optimal size
  OCI_ATTR_CACHE_MAX_SIZE       = 35;  // object cache maximum size percentage
  OCI_ATTR_PINOPTION            = 36;  // object cache default pin option
  OCI_ATTR_ALLOC_DURATION       = 37;  // object cache default allocation duration
  OCI_ATTR_PIN_DURATION         = 38;  // object cache default pin duration
  OCI_ATTR_FDO                  = 39;  // Format Descriptor object attribute
  OCI_ATTR_POSTPROCESSING_CALLBACK = 40;  // Callback to process outbind data
  OCI_ATTR_POSTPROCESSING_CONTEXT = 41; // Callback context to process outbind data
  OCI_ATTR_ROWS_RETURNED        = 42;  // Number of rows returned in current iter - for Bind handles
  OCI_ATTR_FOCBK                = 43;  // Failover Callback attribute
  OCI_ATTR_IN_V8_MODE           = 44;  // is the server/service context in V8 mode
  OCI_ATTR_LOBEMPTY             = 45;  // empty lob ?
  OCI_ATTR_SESSLANG             = 46;  // session language handle

  OCI_ATTR_VISIBILITY           = 47;  // visibility
  OCI_ATTR_RELATIVE_MSGID       = 48;  // relative message id
  OCI_ATTR_SEQUENCE_DEVIATION   = 49;  // sequence deviation

  OCI_ATTR_CONSUMER_NAME        = 50;  // consumer name
  OCI_ATTR_DEQ_MODE             = 51;  // dequeue mode
  OCI_ATTR_NAVIGATION           = 52;  // navigation
  OCI_ATTR_WAIT                 = 53;  // wait
  OCI_ATTR_DEQ_MSGID            = 54;  // dequeue message id

  OCI_ATTR_PRIORITY             = 55;  // priority
  OCI_ATTR_DELAY                = 56;  // delay
  OCI_ATTR_EXPIRATION           = 57;  // expiration
  OCI_ATTR_CORRELATION          = 58;  // correlation id
  OCI_ATTR_ATTEMPTS             = 59;  // # of attempts
  OCI_ATTR_RECIPIENT_LIST       = 60;  // recipient list
  OCI_ATTR_EXCEPTION_QUEUE      = 61;  // exception queue name
  OCI_ATTR_ENQ_TIME             = 62;  // enqueue time (only OCIAttrGet)
  OCI_ATTR_MSG_STATE            = 63;  // message state (only OCIAttrGet)
                                       // NOTE: 64-66 used below
  OCI_ATTR_AGENT_NAME           = 64;  // agent name
  OCI_ATTR_AGENT_ADDRESS        = 65;  // agent address
  OCI_ATTR_AGENT_PROTOCOL       = 66;  // agent protocol

  OCI_ATTR_SENDER_ID            = 68;  // sender id
  OCI_ATTR_ORIGINAL_MSGID       = 69;  // original message id

  OCI_ATTR_QUEUE_NAME           = 70;  // queue name
  OCI_ATTR_NFY_MSGID            = 71;  // message id
  OCI_ATTR_MSG_PROP             = 72;  // message properties

  OCI_ATTR_NUM_DML_ERRORS       = 73;  // num of errs in array DML
  OCI_ATTR_DML_ROW_OFFSET       = 74;  // row offset in the array

  OCI_ATTR_DATEFORMAT           = 75;  // default date format string
  OCI_ATTR_BUF_ADDR             = 76;  // buffer address
  OCI_ATTR_BUF_SIZE             = 77;  // buffer size
  OCI_ATTR_DIRPATH_MODE         = 78;  // mode of direct path operation
  OCI_ATTR_DIRPATH_NOLOG        = 79;  // nologging option
  OCI_ATTR_DIRPATH_PARALLEL     = 80;  // parallel (temp seg) option
  OCI_ATTR_NUM_ROWS             = 81;  // number of rows in column array
                                       // NOTE that OCI_ATTR_NUM_COLS is a column
                                       // array attribute too.

  OCI_ATTR_COL_COUNT            = 82;  // columns of column array processed so far.
  OCI_ATTR_STREAM_OFFSET        = 83;  // str off of last row processed
  OCI_ATTR_SHARED_HEAPALLOC     = 84;  // Shared Heap Allocation Size

  OCI_ATTR_SERVER_GROUP         = 85;  // server group name

  OCI_ATTR_MIGSESSION           = 86;  // migratable session attribute

  OCI_ATTR_NOCACHE              = 87;  // Temporary LOBs

  OCI_ATTR_MEMPOOL_SIZE         = 88;  // Pool Size
  OCI_ATTR_MEMPOOL_INSTNAME     = 89;  // Instance name
  OCI_ATTR_MEMPOOL_APPNAME      = 90;  // Application name
  OCI_ATTR_MEMPOOL_HOMENAME     = 91;  // Home Directory name
  OCI_ATTR_MEMPOOL_MODEL        = 92;  // Pool Model (proc,thrd,both)
  OCI_ATTR_MODES                = 93;  // Modes

  OCI_ATTR_SUBSCR_NAME          = 94;  // name of subscription
  OCI_ATTR_SUBSCR_CALLBACK      = 95;  // associated callback
  OCI_ATTR_SUBSCR_CTX           = 96;  // associated callback context
  OCI_ATTR_SUBSCR_PAYLOAD       = 97;  // associated payload
  OCI_ATTR_SUBSCR_NAMESPACE     = 98;  // associated namespace

  OCI_ATTR_PROXY_CREDENTIALS    = 99;  // Proxy user credentials
  OCI_ATTR_INITIAL_CLIENT_ROLES = 100; // Initial client role list

  OCI_ATTR_UNK                  = 101; // unknown attribute
  OCI_ATTR_NUM_COLS             = 102; // number of columns
  OCI_ATTR_LIST_COLUMNS         = 103; // parameter of the column list
  OCI_ATTR_RDBA                 = 104; // DBA of the segment header
  OCI_ATTR_CLUSTERED            = 105; // whether the table is clustered
  OCI_ATTR_PARTITIONED          = 106; // whether the table is partitioned
  OCI_ATTR_INDEX_ONLY           = 107; // whether the table is index only
  OCI_ATTR_LIST_ARGUMENTS       = 108; // parameter of the argument list
  OCI_ATTR_LIST_SUBPROGRAMS     = 109; // parameter of the subprogram list
  OCI_ATTR_REF_TDO              = 110; // REF to the type descriptor
  OCI_ATTR_LINK                 = 111; // the database link name
  OCI_ATTR_MIN                  = 112; // minimum value
  OCI_ATTR_MAX                  = 113; // maximum value
  OCI_ATTR_INCR                 = 114; // increment value
  OCI_ATTR_CACHE                = 115; // number of sequence numbers cached
  OCI_ATTR_ORDER                = 116; // whether the sequence is ordered
  OCI_ATTR_HW_MARK              = 117; // high-water mark
  OCI_ATTR_TYPE_SCHEMA          = 118; // type's schema name
  OCI_ATTR_TIMESTAMP            = 119; // timestamp of the object
  OCI_ATTR_NUM_ATTRS            = 120; // number of sttributes
  OCI_ATTR_NUM_PARAMS           = 121; // number of parameters
  OCI_ATTR_OBJID                = 122; // object id for a table or view
  OCI_ATTR_PTYPE                = 123; // type of info described by
  OCI_ATTR_PARAM                = 124; // parameter descriptor
  OCI_ATTR_OVERLOAD_ID          = 125; // overload ID for funcs and procs
  OCI_ATTR_TABLESPACE           = 126; // table name space
  OCI_ATTR_TDO                  = 127; // TDO of a type
  OCI_ATTR_LTYPE                = 128; // list type
  OCI_ATTR_PARSE_ERROR_OFFSET   = 129; // Parse Error offset
  OCI_ATTR_IS_TEMPORARY         = 130; // whether table is temporary
  OCI_ATTR_IS_TYPED             = 131; // whether table is typed
  OCI_ATTR_DURATION             = 132; // duration of temporary table
  OCI_ATTR_IS_INVOKER_RIGHTS    = 133; // is invoker rights
  OCI_ATTR_OBJ_NAME             = 134; // top level schema obj name
  OCI_ATTR_OBJ_SCHEMA           = 135; // schema name
  OCI_ATTR_OBJ_ID               = 136; // top level schema object id
  OCI_ATTR_STMTCACHESIZE        = 176; // size of the stm cache
  OCI_ATTR_ROWS_FETCHED         = 197; // rows fetched in last call
  OCI_ATTR_DEFAULT_LOBPREFETCH_SIZE = 438; // default prefetch size

  { OCI Error Return Values }
  OCI_SUCCESS             = 0;
  OCI_SUCCESS_WITH_INFO   = 1;
  OCI_NO_DATA             = 100;
  OCI_ERROR               = -1;
  OCI_INVALID_HANDLE      = -2;
  OCI_NEED_DATA           = 99;
  OCI_STILL_EXECUTING     = -3123;
  OCI_CONTINUE            = -24200;
  OCI_PASSWORD_INFO       = 28002; // the password will expire within ... days

  { Generic Default Value for Modes, .... }
  OCI_DEFAULT     = $0;

  { OCI Init Mode }
  OCI_THREADED    = $1;
  OCI_OBJECT      = $2;
  OCI_EVENTS      = $4;
  OCI_SHARED      = $10;
  OCI_NO_UCB      = $40;
  OCI_NO_MUTEX    = $80;

  { fixed Client Character Set }
  OCI_CLIENT_CHARSET_UTF8 = $367;

  { OCI Credentials }
  OCI_CRED_RDBMS  = 1;
  OCI_CRED_EXT    = 2;
  OCI_CRED_PROXY  = 3;

  { OCI Authentication Mode }
  OCI_MIGRATE     = $0001;             // migratable auth context
  OCI_SYSDBA      = $0002;             // for SYSDBA authorization
  OCI_SYSOPER     = $0004;             // for SYSOPER authorization
  OCI_PRELIM_AUTH = $0008;             // for preliminary authorization

  { OCIPasswordChange }
  OCI_AUTH        = $08;               // Change the password but do not login

  { OCI Data Types }
  SQLT_CHR = 1;
  SQLT_NUM = 2;
  SQLT_INT = 3;
  SQLT_FLT = 4;
  SQLT_STR = 5;
  SQLT_VNU = 6;
  SQLT_PDN = 7;
  SQLT_LNG = 8;
  SQLT_VCS = 9;
  SQLT_NON = 10;
  SQLT_RID = 11;
  SQLT_DAT = 12;
  SQLT_VBI = 15;
  SQLT_BFLOAT = 21;
  SQLT_BDOUBLE = 22;
  SQLT_BIN = 23;
  SQLT_LBI = 24;
  _SQLT_PLI = 29;
  SQLT_UIN = 68;
  SQLT_SLS = 91;
  SQLT_LVC = 94;
  SQLT_LVB = 95;
  SQLT_AFC = 96;
  SQLT_AVC = 97;
  SQLT_CUR = 102;
  SQLT_RDD = 104;
  SQLT_LAB = 105;
  SQLT_OSL = 106;
  SQLT_NTY = 108;
  SQLT_REF = 110;
  SQLT_CLOB = 112;
  SQLT_BLOB = 113;
  SQLT_BFILEE = 114;
  SQLT_CFILEE = 115;
  SQLT_RSET = 116;
  SQLT_NCO = 122;
  SQLT_VST = 155;
  SQLT_ODT = 156;
  SQLT_DATE = 184;
  SQLT_TIME = 185;
  SQLT_TIME_TZ = 186;
  SQLT_TIMESTAMP = 187;
  SQLT_TIMESTAMP_TZ = 188;
  SQLT_INTERVAL_YM = 189;
  SQLT_INTERVAL_DS = 190;
  SQLT_TIMESTAMP_LTZ = 232;

  _SQLT_REC = 250;
  _SQLT_TAB = 251;
  _SQLT_BOL = 252;

  { OCI Statement Types }
  OCI_STMT_SELECT  = 1;   // select statement
  OCI_STMT_UPDATE  = 2;   // update statement
  OCI_STMT_DELETE  = 3;   // delete statement
  OCI_STMT_INSERT  = 4;   // Insert Statement
  OCI_STMT_CREATE  = 5;   // create statement
  OCI_STMT_DROP    = 6;   // drop statement
  OCI_STMT_ALTER   = 7;   // alter statement
  OCI_STMT_BEGIN   = 8;   // begin ... (pl/sql statement)
  OCI_STMT_DECLARE = 9;   // declare .. (pl/sql statement)

  { OCI Statement language }
  OCI_NTV_SYNTAX  = 1;    // Use what so ever is the native lang of server
  OCI_V7_SYNTAX   = 2;    // V7 language
  OCI_V8_SYNTAX   = 3;    // V8 language

  { OCI Statement Execute mode }
  OCI_BATCH_MODE        = $01;    // batch the oci statement for execution
  OCI_EXACT_FETCH       = $02;    // fetch the exact rows specified
  OCI_SCROLLABLE_CURSOR = $08;    // cursor scrollable
  OCI_DESCRIBE_ONLY     = $10;    // only describe the statement
  OCI_COMMIT_ON_SUCCESS = $20;    // commit, if successful execution
  OCI_NON_BLOCKING      = $40;    // non-blocking
  OCI_BATCH_ERRORS      = $80;    // batch errors in array dmls
  OCI_PARSE_ONLY        = $100;   // only parse the statement

  OCI_DATA_AT_EXEC    = $02;      // data at execute time
  OCI_DYNAMIC_FETCH   = $02;      // fetch dynamically
  OCI_PIECEWISE       = $04;      // piecewise DMLs or fetch

  { OCI Transaction modes }
  OCI_TRANS_NEW          = $00000001; // starts a new transaction branch
  OCI_TRANS_JOIN         = $00000002; // join an existing transaction
  OCI_TRANS_RESUME       = $00000004; // resume this transaction
  OCI_TRANS_STARTMASK    = $000000ff;

  OCI_TRANS_READONLY     = $00000100; // starts a readonly transaction
  OCI_TRANS_READWRITE    = $00000200; // starts a read-write transaction
  OCI_TRANS_SERIALIZABLE = $00000400; // starts a serializable transaction
  OCI_TRANS_ISOLMASK     = $0000ff00;

  OCI_TRANS_LOOSE        = $00010000; // a loosely coupled branch
  OCI_TRANS_TIGHT        = $00020000; // a tightly coupled branch
  OCI_TRANS_TYPEMASK     = $000f0000;

  OCI_TRANS_NOMIGRATE    = $00100000; // non migratable transaction
  OCI_TRANS_TWOPHASE     = $01000000; // use two phase commit

  { OCI pece wise fetch }
  OCI_ONE_PIECE       = 0; // one piece
  OCI_FIRST_PIECE     = 1; // the first piece
  OCI_NEXT_PIECE      = 2; // the next of many pieces
  OCI_LAST_PIECE      = 3; // the last piece

  { OCI fetch modes }
  OCI_FETCH_NEXT      = $02;  // next row
  OCI_FETCH_FIRST     = $04;  // first row of the result set
  OCI_FETCH_LAST      = $08;  // the last row of the result set
  OCI_FETCH_PRIOR     = $10;  // the previous row relative to current
  OCI_FETCH_ABSOLUTE  = $20;  // absolute offset from first
  OCI_FETCH_RELATIVE  = $40;  // offset relative to current

  {****************** Describe Handle Parameter Attributes *****************}

  { Attributes common to Columns and Stored Procs }
  OCI_ATTR_DATA_SIZE      = 1;    // maximum size of the data
  OCI_ATTR_DATA_TYPE      = 2;    // the SQL type of the column/argument
  OCI_ATTR_DISP_SIZE      = 3;    // the display size
  OCI_ATTR_NAME           = 4;    // the name of the column/argument
  OCI_ATTR_PRECISION      = 5;    // precision if number type
  OCI_ATTR_SCALE          = 6;    // scale if number type
  OCI_ATTR_IS_NULL        = 7;    // is it null ?
  OCI_ATTR_TYPE_NAME      = 8;    // name of the named data type or a package name for package private types
  OCI_ATTR_SCHEMA_NAME    = 9;    // the schema name
  OCI_ATTR_SUB_NAME       = 10;   // type name if package private type
  OCI_ATTR_POSITION       = 11;   // relative position of col/arg in the list of cols/args

  { complex object retrieval parameter attributes }
  OCI_ATTR_COMPLEXOBJECTCOMP_TYPE         = 50;
  OCI_ATTR_COMPLEXOBJECTCOMP_TYPE_LEVEL   = 51;
  OCI_ATTR_COMPLEXOBJECT_LEVEL            = 52;
  OCI_ATTR_COMPLEXOBJECT_COLL_OUTOFLINE   = 53;

  { Only Columns }
  OCI_ATTR_DISP_NAME                 = 100;  // the display name

  { Only Stored Procs }
  OCI_ATTR_OVERLOAD                  = 210;  // is this position overloaded
  OCI_ATTR_LEVEL                     = 211;  // level for structured types
  OCI_ATTR_HAS_DEFAULT               = 212;  // has a default value
  OCI_ATTR_IOMODE                    = 213;  // in, out inout
  OCI_ATTR_RADIX                     = 214;  // returns a radix
  OCI_ATTR_NUM_ARGS                  = 215;  // total number of arguments

  { only named type attributes }
  OCI_ATTR_TYPECODE                  = 216;   // object or collection
  OCI_ATTR_COLLECTION_TYPECODE       = 217;   // varray or nested table
  OCI_ATTR_VERSION                   = 218;   // user assigned version
  OCI_ATTR_IS_INCOMPLETE_TYPE        = 219;   // is this an incomplete type
  OCI_ATTR_IS_SYSTEM_TYPE            = 220;   // a system type
  OCI_ATTR_IS_PREDEFINED_TYPE        = 221;   // a predefined type
  OCI_ATTR_IS_TRANSIENT_TYPE         = 222;   // a transient type
  OCI_ATTR_IS_SYSTEM_GENERATED_TYPE  = 223;   // system generated type
  OCI_ATTR_HAS_NESTED_TABLE          = 224;   // contains nested table attr
  OCI_ATTR_HAS_LOB                   = 225;   // has a lob attribute
  OCI_ATTR_HAS_FILE                  = 226;   // has a file attribute
  OCI_ATTR_COLLECTION_ELEMENT        = 227;   // has a collection attribute
  OCI_ATTR_NUM_TYPE_ATTRS            = 228;   // number of attribute types
  OCI_ATTR_LIST_TYPE_ATTRS           = 229;   // list of type attributes
  OCI_ATTR_NUM_TYPE_METHODS          = 230;   // number of type methods
  OCI_ATTR_LIST_TYPE_METHODS         = 231;   // list of type methods
  OCI_ATTR_MAP_METHOD                = 232;   // map method of type
  OCI_ATTR_ORDER_METHOD              = 233;   // order method of type

  { only collection element }
  OCI_ATTR_NUM_ELEMS                 = 234;   // number of elements

  { only type methods }
  OCI_ATTR_ENCAPSULATION             = 235;   // encapsulation level
  OCI_ATTR_IS_SELFISH                = 236;   // method selfish
  OCI_ATTR_IS_VIRTUAL                = 237;   // virtual
  OCI_ATTR_IS_INLINE                 = 238;   // inline
  OCI_ATTR_IS_CONSTANT               = 239;   // constant
  OCI_ATTR_HAS_RESULT                = 240;   // has result
  OCI_ATTR_IS_CONSTRUCTOR            = 241;   // constructor
  OCI_ATTR_IS_DESTRUCTOR             = 242;   // destructor
  OCI_ATTR_IS_OPERATOR               = 243;   // operator
  OCI_ATTR_IS_MAP                    = 244;   // a map method
  OCI_ATTR_IS_ORDER                  = 245;   // order method
  OCI_ATTR_IS_RNDS                   = 246;   // read no data state method
  OCI_ATTR_IS_RNPS                   = 247;   // read no process state
  OCI_ATTR_IS_WNDS                   = 248;   // write no data state method
  OCI_ATTR_IS_WNPS                   = 249;   // write no process state

  OCI_ATTR_DESC_PUBLIC               = 250;   // public object

  { Object Cache Enhancements : attributes for User Constructed Instances }
  OCI_ATTR_CACHE_CLIENT_CONTEXT      = 251;
  OCI_ATTR_UCI_CONSTRUCT             = 252;
  OCI_ATTR_UCI_DESTRUCT              = 253;
  OCI_ATTR_UCI_COPY                  = 254;
  OCI_ATTR_UCI_PICKLE                = 255;
  OCI_ATTR_UCI_UNPICKLE              = 256;
  OCI_ATTR_UCI_REFRESH               = 257;

  { for type inheritance }
  OCI_ATTR_IS_SUBTYPE                = 258;
  OCI_ATTR_SUPERTYPE_SCHEMA_NAME     = 259;
  OCI_ATTR_SUPERTYPE_NAME            = 260;

  { for schemas }
  OCI_ATTR_LIST_OBJECTS              = 261;   // list of objects in schema

  { for database }
  OCI_ATTR_NCHARSET_ID               = 262;   // char set id
  OCI_ATTR_LIST_SCHEMAS              = 263;   // list of schemas
  OCI_ATTR_MAX_PROC_LEN              = 264;   // max procedure length
  OCI_ATTR_MAX_COLUMN_LEN            = 265;   // max column name length
  OCI_ATTR_CURSOR_COMMIT_BEHAVIOR    = 266;   // cursor commit behavior
  OCI_ATTR_MAX_CATALOG_NAMELEN       = 267;   // catalog namelength
  OCI_ATTR_CATALOG_LOCATION          = 268;   // catalog location
  OCI_ATTR_SAVEPOINT_SUPPORT         = 269;   // savepoint support
  OCI_ATTR_NOWAIT_SUPPORT            = 270;   // nowait support
  OCI_ATTR_AUTOCOMMIT_DDL            = 271;   // autocommit DDL
  OCI_ATTR_LOCKING_MODE              = 272;   // locking mode

  OCI_ATTR_CACHE_ARRAYFLUSH          = $40;
  OCI_ATTR_OBJECT_NEWNOTNULL         = $10;
  OCI_ATTR_OBJECT_DETECTCHANGE       = $20;

  { Piece Information }
  OCI_PARAM_IN                       = $01;  // in parameter
  OCI_PARAM_OUT                      = $02;  // out parameter

  { LOB Buffering Flush Flags }
  OCI_LOB_BUFFER_FREE     = 1;
  OCI_LOB_BUFFER_NOFREE   = 2;

  { FILE open modes }
  OCI_FILE_READONLY   = 1;    // readonly mode open for FILE types
  { LOB open modes }
  OCI_LOB_READONLY    = 1;    // readonly mode open for ILOB types
  OCI_LOB_READWRITE   = 2;    // read write mode open for ILOBs

  { CHAR/NCHAR/VARCHAR2/NVARCHAR2/CLOB/NCLOB char set "form" information }
  SQLCS_IMPLICIT = 1;     // for CHAR, VARCHAR2, CLOB w/o a specified set
  SQLCS_NCHAR    = 2;     // for NCHAR, NCHAR VARYING, NCLOB
  SQLCS_EXPLICIT = 3;     // for CHAR, etc, with "CHARACTER SET ..." syntax
  SQLCS_FLEXIBLE = 4;     // for PL/SQL "flexible" parameters
  SQLCS_LIT_NULL = 5;     // for typecheck of NULL and empty_clob() lits


{ TSQLDBOracleLib }

const
  OCI_ENTRIES: array[0..28] of PChar = (
    'OCIClientVersion', 'OCIEnvNlsCreate', 'OCIHandleAlloc', 'OCIHandleFree',
    'OCIServerAttach', 'OCIServerDetach', 'OCIAttrGet', 'OCIAttrSet',
    'OCISessionBegin', 'OCISessionEnd', 'OCIErrorGet', 'OCIStmtPrepare',
    'OCIStmtExecute', 'OCIStmtFetch', 'OCIBindByPos', 'OCIParamGet',
    'OCITransStart', 'OCITransRollback', 'OCITransCommit', 'OCIDescriptorAlloc',
    'OCIDescriptorFree', 'OCIDateTimeConstruct', 'OCIDateTimeGetDate',
    'OCIDefineByPos', 'OCILobGetLength', 'OCILobOpen', 'OCILobRead', 'OCILobClose',
    'OCINlsCharSetNameToId');

type
  /// direct access to the native Oracle Client Interface (OCI)
  TSQLDBOracleLib = class(TSQLDBLib)
  protected
    fLibraryPath: TFileName;
    procedure HandleError(Status: Integer; ErrorHandle: POCIError;
      InfoRaiseException: Boolean=false; LogLevelNoRaise: TSynLogInfo=sllNone);
    procedure RetrieveVersion;
  public
    ClientVersion: function(var major_version, minor_version,
      update_num, patch_num, port_update_num: sword): sword; cdecl;
    EnvNlsCreate: function(var envhpp: pointer; mode: ub4; ctxp: Pointer;
      malocfp: Pointer; ralocfp: Pointer; mfreefp: Pointer; xtramemsz: size_T;
      usrmempp: PPointer; charset, ncharset: ub2): sword; cdecl;
    HandleAlloc: function(parenth: POCIHandle; var hndlpp: pointer;
      atype: ub4; xtramem_sz: size_T=0; usrmempp: PPointer=nil): sword; cdecl;
    HandleFree: function(hndlp: Pointer; atype: ub4): sword; cdecl;
    ServerAttach: function(srvhp: POCIServer; errhp: POCIError; dblink: text;
      dblink_len: sb4; mode: ub4): sword; cdecl;
    ServerDetach: function(srvhp: POCIServer; errhp: POCIError;
      mode: ub4): sword; cdecl;
    AttrGet: function(trgthndlp: POCIHandle; trghndltyp: ub4;
      attributep: Pointer; sizep: Pointer; attrtype: ub4;
      errhp: POCIError): sword; cdecl;
    AttrSet: function(trgthndlp: POCIHandle; trghndltyp: ub4;
      attributep: Pointer; size: ub4; attrtype: ub4; errhp: POCIError): sword; cdecl;
    SessionBegin: function(svchp: POCISvcCtx; errhp: POCIError;
      usrhp: POCISession; credt: ub4; mode: ub4): sword; cdecl;
    SessionEnd: function(svchp: POCISvcCtx; errhp: POCIError;
      usrhp: POCISession; mode: ub4): sword; cdecl;
    ErrorGet: function(hndlp: Pointer; recordno: ub4; sqlstate: text;
      var errcodep: sb4; bufp: text; bufsiz: ub4; atype: ub4): sword; cdecl;
    StmtPrepare: function(stmtp: POCIStmt; errhp: POCIError; stmt: text;
      stmt_len: ub4; language:ub4; mode: ub4):sword; cdecl;
    StmtExecute: function(svchp: POCISvcCtx; stmtp: POCIStmt;
      errhp: POCIError; iters: ub4; rowoff: ub4; snap_in: POCISnapshot;
      snap_out: POCISnapshot; mode: ub4): sword; cdecl;
    StmtFetch: function(stmtp: POCIStmt; errhp: POCIError; nrows: ub4;
      orientation: ub2; mode: ub4): sword; cdecl;
    BindByPos: function(stmtp: POCIStmt; var bindpp: POCIBind;
      errhp: POCIError; position: ub4; valuep: Pointer; value_sz: sb4; dty: ub2;
      indp: Pointer; alenp: Pointer; rcodep: Pointer; maxarr_len: ub4;
      curelep: Pointer; mode: ub4): sword; cdecl;
    ParamGet: function(hndlp: Pointer; htype: ub4; errhp: POCIError;
      var parmdpp: Pointer; pos: ub4): sword; cdecl;
    TransStart: function(svchp: POCISvcCtx; errhp: POCIError; timeout: word;
      flags: ub4): sword; cdecl;
    TransRollback: function(svchp:POCISvcCtx; errhp:POCIError;
      flags: ub4): sword; cdecl;
    TransCommit: function(svchp: POCISvcCtx; errhp: POCIError;
      flags: ub4) :sword; cdecl;
    DescriptorAlloc: function(parenth: POCIEnv; var descpp: pointer;
      htype: ub4; xtramem_sz: integer; usrmempp: Pointer): sword; cdecl;
    DescriptorFree: function(descp: Pointer; htype: ub4): sword; cdecl;
    DateTimeConstruct: function(hndl: POCIEnv; err: POCIError;
      datetime: POCIDateTime; year: sb2; month: ub1; day: ub1; hour: ub1;
      min: ub1; sec: ub1; fsec: ub4; timezone: text;
      timezone_length: size_t): sword; cdecl;
    DateTimeGetDate: function(hndl: POCIEnv; err: POCIError;
      const date: POCIDateTime; var year: sb2; var month: ub1;
      var day: ub1): sword; cdecl;
    DefineByPos: function(stmtp: POCIStmt; var defnpp: POCIDefine;
      errhp: POCIError; position: ub4; valuep: Pointer; value_sz: sb4; dty: ub2;
      indp: Pointer; rlenp: Pointer; rcodep: Pointer; mode: ub4): sword; cdecl;
    LobGetLength: function(svchp: POCISvcCtx; errhp: POCIError;
      locp: POCILobLocator; var lenp: ub4): sword; cdecl;
    LobOpen: function(svchp: POCISvcCtx; errhp: POCIError;
      locp: POCILobLocator; mode: ub1): sword; cdecl;
    LobRead: function(svchp: POCISvcCtx; errhp: POCIError;
      locp: POCILobLocator; var amtp: ub4; offset: ub4; bufp: Pointer; bufl: ub4;
      ctxp: Pointer=nil; cbfp: Pointer=nil; csid: ub2=0; csfrm: ub1=SQLCS_IMPLICIT): sword; cdecl;
    LobClose: function(svchp: POCISvcCtx; errhp: POCIError;
      locp: POCILobLocator): sword; cdecl;
    NlsCharSetNameToID: function(env: POCIEnv; name: PAnsiChar): sword; cdecl;
  public
    // the client verion numbers
    major_version, minor_version, update_num, patch_num, port_update_num: sword;
    /// load the oci.dll library
    constructor Create;
    /// retrieve the client version as '11.2.0.1 at oci.dll'
    function ClientRevision: RawUTF8;
    /// retrieve the OCI charset ID from a Windows Code Page
    // - will only handle most known Windows Code Page
    // - will use 'WE8MSWIN1252' (CODEPAGE_US) if the Code Page is unknown
    function CodePageToCharSet(env: pointer; aCodePage: integer): integer;
    /// raise an exception on error
    procedure Check(Status: Integer; ErrorHandle: POCIError;
      InfoRaiseException: Boolean=false; LogLevelNoRaise: TSynLogInfo=sllNone);
      {$ifdef HASINLINE} inline; {$endif}
    /// retrieve some BLOB content
    function BlobFromDescriptor(svchp: POCISvcCtx; errhp: POCIError;
      locp: POCIDescriptor): RawByteString;
  end;


procedure TSQLDBOracleLib.RetrieveVersion;
begin
  if major_version=0 then
    ClientVersion(major_version, minor_version,
      update_num, patch_num, port_update_num);
end;

function TSQLDBOracleLib.BlobFromDescriptor(svchp: POCISvcCtx; errhp: POCIError;
  locp: POCIDescriptor): RawByteString;
var Len, Read: ub4;
begin
  Check(LobOpen(svchp,errhp,locp,OCI_LOB_READONLY),errhp);
  try
    Len := 0;
    Check(LobGetLength(svchp,errhp,locp,Len),errhp);
    SetString(result,nil,Len);
    if Len>0 then begin
      Read := Len;
      Check(LobRead(svchp,errhp,locp,Read,1,pointer(result),Read),errhp);
      if Read<>Len then
        raise ESQLDBOracle.Create('LOB read error');
    end;
  finally
    Check(LobClose(svchp,errhp,locp),errhp);
  end;
end;

procedure TSQLDBOracleLib.HandleError(Status: Integer; ErrorHandle: POCIError;
  InfoRaiseException: Boolean; LogLevelNoRaise: TSynLogInfo);
var msg: array[byte] of AnsiChar;
    L, ErrNum: integer;
begin
  msg[0] := #0;
  case Status of
    OCI_ERROR, OCI_SUCCESS_WITH_INFO: begin
      ErrorGet(ErrorHandle,1,nil,ErrNum,msg,sizeof(msg),OCI_HTYPE_ERROR);
      L := StrLen(msg)-1;
      if (L>=0) and (msg[L]<' ') then
        msg[L] := #0; // trim right #10
      if (Status=OCI_SUCCESS_WITH_INFO) and not InfoRaiseException then
        LogLevelNoRaise := sllError;
    end;
    OCI_NEED_DATA:
      msg := 'OCI_NEED_DATA';
    OCI_NO_DATA:
      msg := 'OCI_NO_DATA';
    OCI_INVALID_HANDLE:
      msg := 'OCI_INVALID_HANDLE';
    OCI_STILL_EXECUTING:
      msg := 'OCI_STILL_EXECUTING';
    OCI_CONTINUE:
      msg := 'OCI_CONTINUE';
  end;
  if LogLevelNoRaise<>sllNone then
    {$ifdef DELPHI5OROLDER}
    SynDBLog.Add.Log(LogLevelNoRaise,RawUTF8(msg)) else
    {$else}
    SynDBLog.Add.Log(LogLevelNoRaise,PWinAnsiChar(@msg),'') else
    {$endif}
    raise ESQLDBOracle.Create(string(msg));
end;

procedure TSQLDBOracleLib.Check(Status: Integer; ErrorHandle: POCIError;
  InfoRaiseException: Boolean; LogLevelNoRaise: TSynLogInfo);
begin
  if Status<>OCI_SUCCESS then
    HandleError(Status,ErrorHandle,InfoRaiseException,LogLevelNoRaise);
end;

function TSQLDBOracleLib.ClientRevision: RawUTF8;
const EXE_FMT: PUTF8Char = '%.%.%.% at %';
begin
  if self=nil then
    result := '' else begin
    RetrieveVersion;
    result := FormatUTF8(EXE_FMT,[major_version,minor_version,update_num,patch_num,fLibraryPath]);
  end;
end;

function TSQLDBOracleLib.CodePageToCharSet(env: pointer;
  aCodePage: integer): integer;
var ocp: PAnsiChar;
begin
  // http://download.oracle.com/docs/cd/B19306_01/server.102/b14225/applocaledata.htm#i635016
  case aCodePage of
    874:  ocp := 'TH8TISASCII';
    932:  ocp := 'JA16SJIS';
    949:  ocp := 'KO16MSWIN949';
    936:  ocp := 'ZHS16CGB231280';
    1250: ocp := 'EE8MSWIN1250';
    1251: ocp := 'CL8MSWIN1251';
    1253: ocp := 'EL8MSWIN1253';
    1254: ocp := 'TR8MSWIN1254';
    1255: ocp := 'IW8MSWIN1255';
    1256: ocp := 'AR8MSWIN1256';
    1257: ocp := 'BLT8MSWIN1257';
    1258: ocp := 'VN8MSWIN1258';
    CP_UTF8: begin
      result := OCI_CLIENT_CHARSET_UTF8; // we know UTF-8 ID
      exit;
    end;
    else ocp := 'WE8MSWIN1252'; // default is MS Windows Code Page 1252
  end;
  result := NlsCharSetNameToID(env,ocp);
  if result=0 then
    result := 178; // hard-coded WE8MSWIN1252 value
end;

constructor TSQLDBOracleLib.Create;
var P: PPointer;
    i: integer;
    orhome: array[byte] of Char;
begin
  fLibraryPath := 'oci.dll';
  fHandle := SafeLoadLibrary(fLibraryPath);
  if fHandle=0 then begin
    i := GetEnvironmentVariable('ORACLE_HOME',orhome,sizeof(orhome));
    if i<>0 then begin
      if orhome[i-1]<>'\' then begin
        orhome[i] := '\';
        inc(i);
      end;
      SetString(fLibraryPath,orhome,i);
      fLibraryPath := fLibraryPath+'bin\oci.dll';
      fHandle := SafeLoadLibrary(fLibraryPath);
    end;
  end;
  if fHandle=0 then
    raise ESQLDBOracle.Create('Unable to find Oracle Client Interface (oci.dll)');
  P := @@ClientVersion;
  for i := 0 to High(OCI_ENTRIES) do begin
    P^ := GetProcAddress(fHandle,OCI_ENTRIES[i]);
    if P^=nil then begin
      FreeLibrary(fHandle);
      fHandle := 0;
      raise ESQLDBOracle.CreateFmt('Invalid oci.dll: missing %s',[OCI_ENTRIES[i]]);
    end;
    inc(P);
  end;
end;

var
  OCI: TSQLDBOracleLib = nil;


{ TSQLDBOracleConnectionProperties }

function TSQLDBOracleConnectionProperties.ColumnTypeNativeToDB(
  const aNativeType: RawUTF8; aScale: integer): TSQLDBFieldType;
begin
  result := OracleColumnTypeNativeToDB(aNativeType,aScale);
end;

constructor TSQLDBOracleConnectionProperties.Create(const aServerName,
  aUserID, aPassWord: RawUTF8; aCodePage: integer);
begin
  inherited Create(aServerName,'',aUserID,aPassWord);
  if OCI=nil then begin
    OCI := TSQLDBOracleLib.Create;
    GarbageCollector.Add(OCI);
  end;
  fCodePage := aCodePage;
  fBlobPrefetchSize := 4096;
  fStatementCacheSize := 30; // default is 20
  fInternalBufferSize := 128*1024; // 128 KB
  fSQLCreateField := ORA_FIELDS;
  fSQLCreateFieldMax := 1333; // =4000/3 since WideChar is up to 3 bytes in UTF-8
  fSQLGetServerTimeStamp := ORA_SERVERTIME;
end;

function TSQLDBOracleConnectionProperties.GetClientVersion: RawUTF8;
begin
  result := OCI.ClientRevision;
end;

procedure TSQLDBOracleConnectionProperties.GetForeignKeys;
begin
  with Execute(
    'select b.owner||''.''||b.table_name||''.''||b.column_name col,'+
    '       c.owner||''.''||c.table_name||''.''||c.column_name ref'+
    '  from all_cons_columns b, all_cons_columns c, all_constraints a'+
    ' where b.constraint_name=a.constraint_name and a.owner=b.owner '+
       'and b.position=c.position and c.constraint_name=a.r_constraint_name '+
       'and c.owner=a.r_owner and a.constraint_type = ''R''',[]) do
   while Step do
     fForeignKeys.Add(ColumnUTF8(0),ColumnUTF8(1));
end;

function TSQLDBOracleConnectionProperties.NewConnection: TSQLDBConnection;
begin
  result := TSQLDBOracleConnection.Create(self);
end;

function TSQLDBOracleConnectionProperties.SQLGetField(const aTableName: RawUTF8): RawUTF8;
begin
  result := OracleSQLGetField(aTableName);
end;

function TSQLDBOracleConnectionProperties.SQLGetTableNames: RawUTF8;
begin
  result := OracleSQLGetTableNames;
end;

function TSQLDBOracleConnectionProperties.SQLIso8601ToDate(
  const Iso8601: RawUTF8): RawUTF8;
begin
  result := OracleSQLIso8601ToDate(Iso8601);
end;

{ TSQLDBOracleConnection }

procedure TSQLDBOracleConnection.Commit;
begin
  inherited;
  if fTrans=nil then
    raise ESQLDBOracle.Create('Invalid Commit call');
  OCI.Check(OCI.TransCommit(fContext,fError,OCI_DEFAULT),fError);
end;

procedure TSQLDBOracleConnection.Connect;
var Log: ISynLog;
    Props: TSQLDBOracleConnectionProperties;
begin
  Log := SynDBLog.Enter(self);
  if self=nil then
    raise ESQLDBOracle.Create('Invalid Connect call');
  Disconnect; // force fTrans=fError=fServer=fContext=nil
  with OCI do
  try
    if fEnv=nil then
      // will use UTF-8 encoding by default, in a mono-thread basis
      EnvNlsCreate(fEnv,OCI_DEFAULT,nil,nil,nil,nil,0,nil,
        OCI_CLIENT_CHARSET_UTF8,OCI_CLIENT_CHARSET_UTF8);
    Props := Properties as TSQLDBOracleConnectionProperties;
    if fOCICharSet=0 then
      // retrieve the charset to be used for inlined CHAR / VARCHAR2 fields
      fOCICharSet := CodePageToCharSet(fEnv,Props.CodePage);
    HandleAlloc(fEnv,fError,OCI_HTYPE_ERROR);
    HandleAlloc(fEnv,fServer,OCI_HTYPE_SERVER);
    HandleAlloc(fEnv,fContext,OCI_HTYPE_SVCCTX);
    Check(ServerAttach(fServer,fError,pointer(Props.ServerName),
      length(Props.ServerName),0),fError);
    // we don't catch all errors here, since Client may ignore unhandled ATTR
    AttrSet(fContext,OCI_HTYPE_SVCCTX,fServer,0,OCI_ATTR_SERVER,fError);
    HandleAlloc(fEnv,fSession,OCI_HTYPE_SESSION);
    AttrSet(fSession,OCI_HTYPE_SESSION,pointer(Props.UserID),
      length(Props.UserID),OCI_ATTR_USERNAME,fError);
    AttrSet(fSession,OCI_HTYPE_SESSION,pointer(Props.Password),
      length(Props.Password),OCI_ATTR_PASSWORD,fError);
    AttrSet(fSession,OCI_HTYPE_SESSION,@Props.fBlobPrefetchSize,0,
      OCI_ATTR_DEFAULT_LOBPREFETCH_SIZE,fError);
    Check(SessionBegin(fContext,fError,fSession,OCI_CRED_RDBMS,OCI_DEFAULT),fError);
    AttrSet(fContext,OCI_HTYPE_SVCCTX,fSession,0,OCI_ATTR_SESSION,fError);
    HandleAlloc(fEnv,fTrans,OCI_HTYPE_TRANS);
    AttrSet(fContext,OCI_HTYPE_SVCCTX,fTrans,0,OCI_ATTR_TRANS,fError);
    AttrSet(fContext,OCI_HTYPE_SVCCTX,@Props.fStatementCacheSize,0,
      OCI_ATTR_STMTCACHESIZE,fError);
    //Check(TransStart(fContext,fError,0,OCI_DEFAULT),fError);
  except
    on E: Exception do begin
      Log.Log(sllError,E);
      Disconnect; // clean up on fail
      raise;
    end;
  end;
end;

constructor TSQLDBOracleConnection.Create(aProperties: TSQLDBConnectionProperties);
var Log: ISynLog;
begin
  Log := SynDBLog.Enter(self);
  if not aProperties.InheritsFrom(TSQLDBOracleConnectionProperties) then
    raise ESQLDBException.CreateFmt('Invalid %s.Create',[ClassName]);
  Log.Log(sllDB,aProperties);
  OCI.RetrieveVersion;
  inherited;
end;

destructor TSQLDBOracleConnection.Destroy;
begin
  inherited Destroy;
  if (OCI<>nil) and (fEnv<>nil) then
    OCI.HandleFree(fEnv,OCI_HTYPE_ENV);
end;

procedure TSQLDBOracleConnection.Disconnect;
begin
  if (self<>nil) and (fError<>nil) and (OCI<>nil) then
  with OCI do begin
    SynDBLog.Enter(self);
    if fTrans<>nil then begin
      // close any opened session
      HandleFree(fTrans,OCI_HTYPE_TRANS);
      fTrans := nil;
      Check(SessionEnd(fContext,fError,fSession,OCI_DEFAULT),fError,false,sllError);
      Check(ServerDetach(fServer,fError,OCI_DEFAULT),fError,false,sllError);
    end;
    HandleFree(fSession,OCI_HTYPE_SESSION);
    HandleFree(fContext,OCI_HTYPE_SVCCTX);
    HandleFree(fServer,OCI_HTYPE_SERVER);
    HandleFree(fError,OCI_HTYPE_ERROR);
    fSession := nil;
    fContext := nil;
    fServer := nil;
    fError := nil;
  end;
end;

function TSQLDBOracleConnection.IsConnected: boolean;
begin
  result := (self<>nil) and (fTrans<>nil);
end;

function TSQLDBOracleConnection.NewStatement: TSQLDBStatement;
begin
  result := TSQLDBOracleStatement.Create(self);
end;

procedure TSQLDBOracleConnection.Rollback;
begin
  inherited;
  if fTrans=nil then
    raise ESQLDBOracle.Create('Invalid RollBack call');
  OCI.Check(OCI.TransRollback(fContext,fError,OCI_DEFAULT),fError);
end;

procedure TSQLDBOracleConnection.StartTransaction;
begin
  inherited;
  if fTrans=nil then
    raise ESQLDBOracle.Create('Invalid StartTransaction call');
  if TransactionCount>0 then
    raise ESQLDBOracle.Create('Oracle do not provide nested transactions');
  // nothing to do: Oracle creates implicit transactions, and we'll handle
  // AutoCommit in TSQLDBOracleStatement.ExecutePrepared if TransactionCount=0
  // OCI.Check(OCI.TransStart(fContext,fError,0,OCI_DEFAULT),fError);
end;

procedure TSQLDBOracleConnection.STRToUTF8(P: PAnsiChar; var result: RawUTF8);
var L: integer;
begin
  L := StrLen(PUTF8Char(P));
  if (L=0) or (fOCICharSet=OCI_CLIENT_CHARSET_UTF8) then
    SetString(result,P,L) else
    AnsiCharToUTF8(P,L,result,TSQLDBOracleConnectionProperties(Properties).fCodePage);
end;

{$ifndef UNICODE}
procedure TSQLDBOracleConnection.STRToAnsiString(P: PAnsiChar; var result: AnsiString);
procedure FromUTF8(P: PAnsiChar; var result: AnsiString);
var tmp: RawUTF8;
begin
  StrToUTF8(P,tmp);
  result := UTF8ToString(tmp);
end;
var L: integer;
begin
  L := StrLen(PUTF8Char(P));
  with TSQLDBOracleConnectionProperties(Properties) do
  if (L=0) or (fCodePage=GetACP) then
    SetString(result,P,L) else
    FromUTF8(P,result);
end;
{$endif}


{ TSQLDBOracleStatement }

function TSQLDBOracleStatement.ColumnBlob(Col: integer): RawByteString;
var C: PSQLDBColumnProperty;
    V: PPOCIDescriptor;
begin
  V := GetCol(Col,C);
  if V=nil then // column is NULL
    result := '' else
    if C^.ColumnType=ftBlob then
      if C^.ColumnValueInlined then
        SetString(result,PAnsiChar(V),C^.ColumnValueDBSize) else
        // conversion from POCILobLocator
        with TSQLDBOracleConnection(Connection) do 
          result := OCI.BlobFromDescriptor(fContext,fError,V^) else
      // need conversion to destination type
      ColumnToTypedValue(Col,ftBlob,result);
end;

function TSQLDBOracleStatement.ColumnCurrency(Col: integer): currency;
var C: PSQLDBColumnProperty;
    V: PUTF8Char;
begin
  V := GetCol(Col,C);
  if V=nil then // column is NULL
    result := 0 else
    if C^.ColumnType=ftCurrency then  // encoded as SQLT_STR
      PInt64(@result)^ := StrToCurr64(V) else
      ColumnToTypedValue(Col,ftCurrency,result);
end;

function TSQLDBOracleStatement.ColumnDateTime(Col: integer): TDateTime;
var C: PSQLDBColumnProperty;
    V: POracleDate;
begin
  V := GetCol(Col,C);
  if V=nil then // column is NULL
    result := 0 else
    if C^.ColumnType=ftDate then
      // types match -> fast direct retrieval
      result := V^.ToDateTime else
      // need conversion to destination type
      ColumnToTypedValue(Col,ftDate,result);
end;

function TSQLDBOracleStatement.ColumnDouble(Col: integer): double;
var C: PSQLDBColumnProperty;
    V: PDouble;
begin
  V := GetCol(Col,C);
  if V=nil then // column is NULL
    result := 0 else
    if C^.ColumnType=ftDouble then
      // types match -> fast direct retrieval
      result := V^ else
      // need conversion to destination type
      ColumnToTypedValue(Col,ftDouble,result);
end;

function TSQLDBOracleStatement.ColumnInt(Col: integer): Int64;
var C: PSQLDBColumnProperty;
    V: pointer;
begin
  V := GetCol(Col,C);
  if V=nil then // column is NULL
    result := 0 else
    if C^.ColumnType=ftInt64 then
      if C^.ColumnValueDBType=SQLT_INT then
        result := PInt64(V)^ else
        result := GetInt64(V) else
      ColumnToTypedValue(Col,ftInt64,result);
end;

function TSQLDBOracleStatement.ColumnNull(Col: integer): boolean;
var C: PSQLDBColumnProperty;
begin
  result := GetCol(Col,C)=nil;
end;

procedure TSQLDBOracleStatement.ColumnsToJSON(WR: TJSONWriter);
var V: pointer;
    col, indicator: integer;
    tmp: array[0..31] of AnsiChar;
    U: RawUTF8;
begin
  if not Assigned(fStatement) or (CurrentRow<=0) then
    raise ESQLDBOracle.Create('TSQLDBOracleStatement.ColumnsToJSON() with no prior Step');
  if WR.Expand then
    WR.Add('{');
  for col := 0 to fColumnCount-1 do // fast direct conversion from OleDB buffer
  with fColumns[col] do begin
    if WR.Expand then
      WR.AddFieldName(ColumnName); // add '"ColumnName":'
    indicator := PSmallIntArray(fRowBuffer)[cardinal(col)*fRowCount+fRowFetchedCurrent];
    if indicator=-1 then
      WR.AddShort('null') else begin
      if indicator<>0 then
        LogTruncatedColumn(fColumns[col]);
      V := @fRowBuffer[ColumnAttr+fRowFetchedCurrent*ColumnValueDBSize];
      case ColumnType of
       ftInt64:
         if ColumnValueDBType=SQLT_INT then
           WR.Add(PInt64(V)^) else
           WR.AddNoJSONEscape(V); // already as SQLT_STR
       ftDouble:
         WR.Add(PDouble(V)^);
       ftCurrency: begin
         if PWord(V)^=ord('-')+ord('.')shl 8 then begin
           WR.Add('-','0'); // '-.3' -> '-0.3'
           Inc(PtrUInt(V));
         end else
         if PAnsiChar(V)^='.' then
           WR.Add('0'); // '.5' -> '0.5'
         WR.AddNoJSONEscape(V); // already as SQLT_STR
       end;
       ftDate:
         WR.AddNoJSONEscape(@tmp,POracleDate(V)^.ToIso8601(tmp));
       ftUTF8: begin
         WR.Add('"');
         with TSQLDBOracleConnection(Connection) do
           if ColumnValueInlined then
             STRToUTF8(V,U) else
             U := OCI.BlobFromDescriptor(fContext,fError,PPOCIDescriptor(V)^);
         WR.AddJSONEscape(pointer(U),length(U));
         WR.Add('"');
       end;
       ftBlob:
         if ColumnValueInlined then
           SetString(U,PAnsiChar(V),ColumnValueDBSize) else begin
           with TSQLDBOracleConnection(Connection) do
             U := OCI.BlobFromDescriptor(fContext,fError,PPOCIDescriptor(V)^);
           WR.WrBase64(Pointer(U),length(U),true);
         end;
       else assert(false);
      end;
    end;
    WR.Add(',');
  end;
  WR.CancelLastComma; // cancel last ','
  if WR.Expand then
    WR.Add('}');
end;

function TSQLDBOracleStatement.ColumnToVariant(Col: integer;
  var Value: Variant): TSQLDBFieldType;
const FIELDTYPE2VARTYPE: array[TSQLDBFieldType] of Word = (
  varEmpty, varNull, varInt64, varDouble, varCurrency, varDate,
  {$ifdef UNICODE}varUString{$else}varOleStr{$endif}, varString);
// ftUnknown, ftNull, ftInt64, ftDouble, ftCurrency, ftDate, ftUTF8, ftBlob
var C: PSQLDBColumnProperty;
    V: pointer;
    tmp: RawUTF8;
    Val: TVarData absolute Value;
begin
  V := GetCol(Col,C);
  if V=nil then
    result := ftNull else
    result := C^.ColumnType;
  VarClear(Value);
  Val.VType := FIELDTYPE2VARTYPE[result];
  case result of
    ftNull: ; // do nothing
    ftInt64:
      if C^.ColumnValueDBType=SQLT_INT then
        Val.VInt64 := PInt64(V)^ else
        Val.VInt64 := GetInt64(V);  // encoded as SQLT_STR
    ftCurrency:
      Val.VInt64 := StrToCurr64(V); // encoded as SQLT_STR
    ftDouble:
      Val.VInt64 := PInt64(V)^; // copy 64 bit content
    ftDate:
      Val.VDate := POracleDate(V)^.ToDateTime;
    ftUTF8: begin
      Val.VAny := nil;
      with TSQLDBOracleConnection(Connection) do
        if C^.ColumnValueInlined then
        {$ifndef UNICODE}
          if not Connection.Properties.VariantStringAsWideString then begin
            Val.VType := varString;
            STRToAnsiString(V,AnsiString(Val.VAny));
            exit;
          end else
        {$endif}
          STRToUTF8(V,tmp) else
          tmp := OCI.BlobFromDescriptor(fContext,fError,PPOCIDescriptor(V)^);
      {$ifndef UNICODE}
      if not Connection.Properties.VariantStringAsWideString then begin
        Val.VType := varString;
        AnsiString(Val.VAny) := UTF8DecodeToString(pointer(tmp),length(tmp));
      end else
      {$endif}
        UTF8ToSynUnicode(tmp,SynUnicode(Val.VAny));
    end;
    ftBlob: begin
      Val.VAny := nil;
      if C^.ColumnValueInlined then
        SetString(RawByteString(Val.VAny),PAnsiChar(V),C^.ColumnValueDBSize) else
        with TSQLDBOracleConnection(Connection) do
          RawByteString(Val.VAny) := OCI.BlobFromDescriptor(fContext,fError,PPOCIDescriptor(V)^);
    end;
    else raise ESQLDBOracle.CreateFmt('Unexpected %d type',[ord(result)]);
  end;
end;

function TSQLDBOracleStatement.ColumnUTF8(Col: integer): RawUTF8;
var C: PSQLDBColumnProperty;
    V: PAnsiChar;
begin
  V := GetCol(Col,C);
  if V=nil then // column is NULL
    result := '' else
    if C^.ColumnType=ftUTF8 then
      if C^.ColumnValueInlined then
        // conversion from SQLT_STR (null-terminated string)
        TSQLDBOracleConnection(Connection).STRToUTF8(V,result) else
        // conversion from POCILobLocator
        with TSQLDBOracleConnection(Connection) do 
          result := OCI.BlobFromDescriptor(fContext,fError,PPOCIDescriptor(V)^) else
      // need conversion to destination type
      ColumnToTypedValue(Col,ftUTF8,result);
end;

constructor TSQLDBOracleStatement.Create(aConnection: TSQLDBConnection);
begin
  if not aConnection.InheritsFrom(TSQLDBOracleConnection) then
    raise ESQLDBOracle.CreateFmt('%s.Create expects a TSQLDBOracleConnection',[ClassName]);
  inherited Create(aConnection);
  fInternalBufferSize := (aConnection.Properties as TSQLDBOracleConnectionProperties).InternalBufferSize;
  if fInternalBufferSize<16384 then // default is 128 KB 
    fInternalBufferSize := 16384; // minimal value
end;

destructor TSQLDBOracleStatement.Destroy;
begin
  try
    {$ifndef DELPHI5OROLDER}
    SynDBLog.Add.Log(sllDB,'Total rows = %',[TotalRowsRetrieved],self);
    {$endif}
    FreeHandles;
  finally
    inherited;
  end;
end;

procedure TSQLDBOracleStatement.ExecutePrepared;
var i: integer;
    oData: pointer;
    oLength: sb4;
    oBind: POCIBind;
    oIndicator: sb2;
    Status: integer;
    mode: cardinal;
    Int32: set of 0..127;
    Log: ISynLog;
label txt;
begin
  Log := SynDBLog.Enter(self);
  if (Self=nil) or (fStatement=nil) then
    raise ESQLDBOracle.Create('ExecutePrepared called without previous Prepare');
  with Log.Instance do
    if sllSQL in Family.Level then
      Log(sllSQL,SQLWithInlinedParams,self);
  try
    fRowFetchedEnded := false;
    // 1. bind parameters
    if fParamCount>0 then begin
      fillchar(Int32,sizeof(Int32),0);
      for i := 0 to fParamCount-1 do
      with fParams[i] do begin
        oLength := sizeof(Int64);
        oData := @VInt64;
        oIndicator := 0;
        case VType of
        ftNull:
          oIndicator := -1; // assign a NULL to the column, ignoring input value 
        ftInt64:
          if (OCI.major_version>11) or ((OCI.major_version=11) and (OCI.minor_version>1)) then
            // starting with 11.2, OCI supports NUMBER conversion from Int64
            VDBType := SQLT_INT else
            if (VInt64>low(integer)) and (VInt64<high(Integer)) then begin
              // map to 32 bit will always work
              oLength := SizeOf(integer);
              Include(Int32,i);
            end else begin
              // before 11.2 client, huge integers will be managed as text
              VData := Int64ToUtf8(VInt64);
              goto txt;
            end;
        ftDouble:
          VDBType := SQLT_FLT;
        ftCurrency: begin
          VData := Curr64ToStr(VInt64);
          goto txt; // currency values will be managed as text
        end;
        ftDate: begin
          VDBType := SQLT_DAT; // conversion to Oracle date format
          POracleDate(@VInt64)^.From(PDateTime(@VInt64)^);
          oLength := sizeof(TOracleDate);
        end;
        ftUTF8: begin
txt:      VDBType := SQLT_AVC; // use CHARZ external data type
          oLength := Length(VData)+1; // include #0
          if oLength=1 then // '' will just map one #0
            oData := @VData else
          if oLength<4000 then
            oData := pointer(VData) else begin
            VDBType := SQLT_LVC; // LONG VARCHAR for huge text
            oData := Pointer(PtrInt(VData)-sizeof(Integer));
            Inc(oLength,sizeof(Integer));
          end;
        end;
        ftBlob: begin
          oLength := Length(VData);
          if oLength<2000 then begin
            VDBTYPE := SQLT_BIN;
            oData := pointer(VData);
          end else begin
            VDBTYPE := SQLT_LVB;
            oData := Pointer(PtrInt(VData)-sizeof(Integer));
            Inc(oLength,sizeof(Integer));
          end;
        end;
        else
          raise ESQLDBOracle.CreateFmt('Invalid bound parameter #%d',[i+1]);
        end;
        oBind := nil;
        OCI.Check(OCI.BindByPos(fStatement,oBind,fError,i+1,oData,oLength,VDBType,
          @oIndicator,nil,nil,0,nil,OCI_DEFAULT),fError);
      end;
    end;
    // 2. execute prepared statement
    if (fColumnCount=0) and (Connection.TransactionCount=0) then
      // for INSERT/UPDATE/DELETE without a transaction: AutoCommit after execution
      mode := OCI_COMMIT_ON_SUCCESS else
      // for SELECT or inside a transaction: wait for an explicit COMMIT
      mode := OCI_DEFAULT;
    Status := OCI.StmtExecute((Connection as TSQLDBOracleConnection).fContext,
      fStatement,fError,fRowCount,0,nil,nil,mode);
    FetchTest(Status); // error + set fRowCount+fCurrentRow+fRowFetchedCurrent
  finally
    // unconvert bound parameters
    for i := 0 to fParamCount-1 do
    with fParams[i] do
    case VType of
      ftInt64:
        if VDBType=SQLT_AVC then
          VInt64 := GetInt64(pointer(VData)) else
        if i in Int32 then
          VInt64 := PInteger(@VInt64)^;
      ftCurrency: // currency were SQLT_AVC encoded
        VInt64 := StrToCurr64(pointer(VData));
      ftDate:
        PDateTime(@VInt64)^ := POracleDate(@VInt64)^.ToDateTime;
    end;
  end;
end;

procedure TSQLDBOracleStatement.FetchTest(Status: integer);
begin
  fRowFetched := 0;
  case Status of
    OCI_SUCCESS:
      if fColumnCount<>0 then
        fRowFetched := fRowCount;
    OCI_NO_DATA: begin
      assert(fColumnCount<>0);
      OCI.AttrGet(fStatement,OCI_HTYPE_STMT,@fRowFetched,nil,OCI_ATTR_ROWS_FETCHED,fError);
      fRowFetchedEnded := true; 
    end;
    else OCI.Check(Status,fError); // will raise error
  end;
  if fRowFetched=0 then begin
    fRowCount := 0;
    fCurrentRow := -1; // no data
  end else begin
    fCurrentRow := 0; // mark cursor on the first row
    fRowFetchedCurrent := 0;
  end;
end;

procedure TSQLDBOracleStatement.FreeHandles;
var i,j: integer;
    PLOB: PPointer;
begin
  if self=nil then exit;
  if fRowBuffer<>nil then
  for i := 0 to fColumnCount-1 do
    with fColumns[i] do
      if not ColumnValueInlined then begin
        PLOB := @fRowBuffer[ColumnAttr]; // first POCILobLocator item
        for j := 1 to fRowCount do begin
          if PLOB^<>nil then begin
            OCI.DescriptorFree(PLOB,OCI_DTYPE_LOB);
            PLOB^ := nil;
          end;
          inc(PLOB);
        end;
      end;
  if fError<>nil then begin
    OCI.HandleFree(fError,OCI_HTYPE_ERROR);
    fError := nil;
  end;
  if fStatement<>nil then begin
    OCI.HandleFree(fStatement,OCI_HTYPE_STMT);
    fStatement := nil;
  end;
  if fRowBuffer<>nil then
    SetLength(fRowBuffer,0); // release internal buffer memory
  if fColumnCount>0 then
    fColumn.Clear;
end;

function TSQLDBOracleStatement.GetCol(Col: Integer;
  out Column: PSQLDBColumnProperty): pointer;
begin
  CheckCol(Col); // check Col value
  if not Assigned(fStatement) or (fColumnCount=0) or (fRowCount=0) or (fRowBuffer=nil) then
    raise ESQLDBOracle.Create('TSQLDBOracleStatement.Column*() with no prior Execute');
  if CurrentRow<=0 then
    raise ESQLDBOracle.Create('TSQLDBOracleStatement.Column*() with no prior Step');
  Column := @fColumns[Col];
  result := @fRowBuffer[Column^.ColumnAttr+fRowFetchedCurrent*Column^.ColumnValueDBSize];
  case PSmallIntArray(fRowBuffer)[cardinal(Col)*fRowCount+fRowFetchedCurrent] of
    // 0:OK, >0:untruncated length, -1:NULL, -2:truncated (length>32KB)
   -1: result := nil; // NULL
    0: exit;
    else LogTruncatedColumn(Column^);
  end;
end;

function TSQLDBOracleStatement.GetUpdateCount: integer;
begin
  result := 0;
  if (self<>nil) and (fStatement<>nil) then
    OCI.AttrGet(fStatement,OCI_HTYPE_STMT,@result,nil,OCI_ATTR_ROW_COUNT,fError);
end;

procedure TSQLDBOracleStatement.Prepare(const aSQL: RawUTF8;
  ExpectResults: Boolean);
var oSQL, aName, tmp: RawUTF8;
    Env: POCIEnv;
    Col: PSQLDBColumnProperty;
    StatementType: ub2;
    i,j,L,B,n: integer;
    P: PAnsiChar;
    oHandle: POCIHandle;
    oDefine: POCIDefine;
    oName: PAnsiChar;
    oNameLen, oScale: integer;
    ColCount, RowSize: cardinal;
    oType, oSize: ub2;
    HasLOB: boolean;
    PLOB: PPOCIDescriptor;
    Indicators: PAnsiChar;
    Log: ISynLog;
begin
  Log := SynDBLog.Enter(self);
  try
    if (fStatement<>nil) or (fColumnCount>0) then
      raise ESQLDBOracle.CreateFmt('%s.Prepare should be called only once',[ClassName]);
    // 1. process SQL
    inherited Prepare(aSQL,ExpectResults); // set fSQL + Connect if necessary
    L := Length(aSQL);
    while (L>0) and (aSQL[L] in [#1..' ',';']) do
      dec(L); // trim ' ' or ';' right (last ';' could be found incorrect)
    if PosEx('?',aSQL)>0 then begin
      // change ? into :AA :BA ..
      n := 0;
      i := 0;
      P := pointer(aSQL);
      if P<>nil then
      repeat
        B := i;
        while (i<L) and (P[i]<>'?') do begin
          if (P[i]='''') and (P[i+1]<>'''') then begin
            repeat // ignore chars inside ' quotes
              inc(i);
            until (i=L) or (P^='''');
            if i=L then break;
          end;
          inc(i);
        end;
        SetString(tmp,P+B,i-B);
        oSQL := oSQL+tmp;
        if i=L then break;
        if n>fParamCount then
          break; // avoid GPF in D^
        // store :AA :BA ..
        j := length(oSQL);
        SetLength(oSQL,j+3);
        PAnsiChar(pointer(oSQL))[j] := ':';
        PAnsiChar(pointer(oSQL))[j+1] := AnsiChar(n and 15+65);
        PAnsiChar(pointer(oSQL))[j+2] := AnsiChar(n shr 4+65);
        inc(i); // jump '?'
      until i=L;
    end else
      oSQL := copy(aSQL,1,L); // trim right ';' if any
    // 2. prepare statement
    Env := (Connection as TSQLDBOracleConnection).fEnv;
    with OCI do begin
      HandleAlloc(Env,fError,OCI_HTYPE_ERROR);
      HandleAlloc(Env,fStatement,OCI_HTYPE_STMT);
      Check(StmtPrepare(fStatement,fError,pointer(oSQL),length(oSQL),
        OCI_NTV_SYNTAX,OCI_DEFAULT),fError);
      AttrGet(fStatement,OCI_HTYPE_STMT,@StatementType,nil,OCI_ATTR_STMT_TYPE,fError);
      if ExpectResults<>(StatementType=OCI_STMT_SELECT) then
        raise ESQLDBOracle.CreateFmt('%s.Prepare called with wrong ExpectResults',[ClassName]);
      if not ExpectResults then begin
        fRowCount := 1; 
        exit; // no row data expected -> leave fColumnCount=0
      end;
      // 3. retrieve rows column types
      Check(StmtExecute(TSQLDBOracleConnection(Connection).fContext,fStatement,fError,
        1,0,nil,nil,OCI_DESCRIBE_ONLY),fError);
      ColCount := 0;
      AttrGet(fStatement,OCI_HTYPE_STMT,@ColCount,nil,OCI_ATTR_PARAM_COUNT,fError);
      RowSize := ColCount*sizeof(sb2); // space for indicators
      HasLOB := false;
      for i := 1 to ColCount do begin
        oHandle := nil;
        ParamGet(fStatement,OCI_HTYPE_STMT,fError,oHandle,i);
        AttrGet(oHandle,OCI_DTYPE_PARAM,@oName,@oNameLen,OCI_ATTR_NAME,fError);
        if oNameLen=0 then
          aName := 'col_'+Int32ToUtf8(i) else
          SetString(aName,oName,oNameLen);
        Col := fColumn.AddAndMakeUniqueName(aName);
        AttrGet(oHandle,OCI_DTYPE_PARAM,@oType,nil,OCI_ATTR_DATA_TYPE,fError);
        AttrGet(oHandle,OCI_DTYPE_PARAM,@oSize,nil,OCI_ATTR_DATA_SIZE,fError);
        Col^.ColumnValueDBSize := oSize;
        Col^.ColumnValueInlined := true;
        case oType of
        SQLT_CHR, SQLT_VCS, SQLT_AFC, SQLT_AVC, SQLT_STR, SQLT_VST, SQLT_NTY: begin
          if Col^.ColumnValueDBSize=0 then
            raise ESQLDBOracle.CreateFmt('Column %s: size=0',[Col^.ColumnName]);
          Col^.ColumnType := ftUTF8;
          Col^.ColumnValueDBType := SQLT_STR; // null-terminated string
          inc(Col^.ColumnValueDBSize); // must include ending #0
        end;
        SQLT_LNG: begin
          Col^.ColumnValueDBSize := 32768; // will be truncated at 32 KB
          Col^.ColumnType := ftUTF8;
          Col^.ColumnValueDBType := SQLT_STR; // null-terminated string
        end;
        SQLT_LVC, SQLT_CLOB: begin
          Col^.ColumnType := ftUTF8;
          Col^.ColumnValueInlined := false;
          Col^.ColumnValueDBType := SQLT_CLOB;
          Col^.ColumnValueDBSize := sizeof(POCILobLocator);
          HasLOB := true;
        end;
        SQLT_RID, SQLT_RDD: begin
          Col^.ColumnType := ftUTF8;
          Col^.ColumnValueDBType := SQLT_STR; // null-terminated string
          Col^.ColumnValueDBSize := 24; // 24 will fit 8 bytes alignment
        end;
        SQLT_VNU, SQLT_FLT, SQLT_BFLOAT, SQLT_BDOUBLE: begin
          Col^.ColumnValueDBType := SQLT_BDOUBLE;
          Col^.ColumnValueDBSize := sizeof(Double);
        end;
        SQLT_NUM: begin
          oScale:= 5; // OCI_ATTR_PRECISION is always 38 (on Oracle 11g) :(
          AttrGet(oHandle,OCI_DTYPE_PARAM,@oScale,nil,OCI_ATTR_SCALE,fError);
          Col^.ColumnValueDBSize := sizeof(Double);
          case oScale of
          0: begin
            Col^.ColumnType := ftInt64;
            if (major_version>11) or ((major_version=11) and (minor_version>1)) then
              // starting with 11.2, OCI supports NUMBER conversion into Int64
              Col^.ColumnValueDBType := SQLT_INT else begin
              // we'll work out with null-terminated string
              Col^.ColumnValueDBType := SQLT_STR;
              Col^.ColumnValueDBSize := 24;
            end;
          end;
          1..4: begin
             Col^.ColumnType := ftCurrency;
             Col^.ColumnValueDBType := SQLT_STR; // use null-terminated string
             Col^.ColumnValueDBSize := 24;
           end else begin
            Col^.ColumnType := ftDouble;
            Col^.ColumnValueDBType := SQLT_BDOUBLE;
          end;
          end;
        end;
        SQLT_INT, _SQLT_PLI, SQLT_UIN: begin
          Col^.ColumnType := ftInt64;
          Col^.ColumnValueDBType := SQLT_INT;
          Col^.ColumnValueDBSize := sizeof(Int64);
        end;
        SQLT_DAT, SQLT_DATE, SQLT_TIME, SQLT_TIME_TZ,
        SQLT_TIMESTAMP, SQLT_TIMESTAMP_TZ, SQLT_TIMESTAMP_LTZ: begin
          Col^.ColumnType := ftDate;
          Col^.ColumnValueDBType := SQLT_DAT;
          Col^.ColumnValueDBSize := sizeof(TOracleDate); 
        end;
        SQLT_BIN, SQLT_LBI, SQLT_BLOB: begin
          Col^.ColumnType := ftBlob;
          Col^.ColumnValueInlined := false;
          Col^.ColumnValueDBType := SQLT_BLOB;
          Col^.ColumnValueDBSize := sizeof(POCILobLocator);
          HasLOB := true;
        end;
        else raise ESQLDBOracle.CreateFmt('Column %s: unknown type %d',
          [Col^.ColumnName,oType]);
        end;
        inc(RowSize,Col^.ColumnValueDBSize);
      end;
      assert(fColumn.Count=integer(ColCount));
      // 4. Dispatch data in row buffer
      assert(fRowBuffer=nil);
      fRowCount := (fInternalBufferSize-ColCount shl 4) div RowSize;
      if fRowCount=0 then begin // reserve space for at least one row of data
        fInternalBufferSize := RowSize+ColCount shl 4;
        fRowCount := 1;
      end;
      Setlength(fRowBuffer,fInternalBufferSize);
      assert(fRowCount>0);
      if HasLob and (fRowCount>100) then
        fRowCount := 100; // do not create too much POCILobLocator items
      // fRowBuffer[] contains Indicators[] + Col0[] + Col1[] + Col2[]...
      Indicators := pointer(fRowBuffer);
      RowSize := fRowCount*ColCount*sizeof(sb2);
      for i := 0 to ColCount-1 do
      with fColumns[i] do begin
        RowSize := ((RowSize-1) shr 3+1)shl 3; // 8 bytes Col*[] alignment
        ColumnAttr := RowSize;
        if not ColumnValueInlined then begin
          PLOB := @fRowBuffer[RowSize]; // first POCILobLocator item
          for j := 1 to fRowCount do begin
            DescriptorAlloc(Env,PLOB^,OCI_DTYPE_LOB,0,nil);
            inc(PLOB);
          end;
        end;
        oDefine := nil;
        Check(DefineByPos(fStatement,oDefine,fError,i+1,@fRowBuffer[RowSize],
          ColumnValueDBSize,ColumnValueDBType,Indicators,
          nil,nil,OCI_DEFAULT),fError);
        if (ColumnValueDBType=SQLT_STR) and
           (TSQLDBOracleConnection(Connection).fOCICharSet<>OCI_CLIENT_CHARSET_UTF8) then
          // force CHAR + NVARCHAR2 inlined fields expected charset
          // -> a conversion into UTF-8 will probably truncate the result
          Check(AttrSet(oDefine,OCI_HTYPE_DEFINE,
            @TSQLDBOracleConnection(Connection).fOCICharSet,0,OCI_ATTR_CHARSET_ID,
            fError),fError);
        inc(RowSize,fRowCount*ColumnValueDBSize);
        inc(Indicators,fRowCount*sizeof(sb2));
      end;
      assert(PtrUInt(Indicators-pointer(fRowBuffer))=fRowCount*ColCount*sizeof(sb2));
      assert(RowSize<=fInternalBufferSize);
    end;
  except
    on E: Exception do begin
      Log.Log(sllError,E);
      FreeHandles;
      raise;
    end;
  end;
end;

function TSQLDBOracleStatement.Step(SeekFirst: boolean): boolean;
var sav, status: integer;
begin
  if not Assigned(fStatement) then
    raise ESQLDBOracle.Create('TSQLDBOracleStatement.Execute should be called before Step');
  result := false;
  if (fCurrentRow<0) or (fRowCount=0) then
    exit; // no data available at all
  sav := fCurrentRow;
  fCurrentRow := -1;
  if fColumnCount=0 then
    exit; // no row available at all (e.g. for SQL UPDATE) -> return false
  if sav<>0 then // ignore if just retrieved ROW #1
    if SeekFirst then begin
      if OCI.major_version<9 then
        raise ESQLDBOracle.CreateFmt('Oracle Client %s does not support OCI_FETCH_FIRST',
          [OCI.ClientRevision]);
      status := OCI.StmtFetch(fStatement,fError,fRowCount,OCI_FETCH_FIRST,OCI_DEFAULT);
      FetchTest(Status); // error + set fRowCount+fRowFetchedCurrent
      if fCurrentRow<0 then // should not happen
        raise ESQLDBOracle.Create('OCI_FETCH_FIRST did not reset cursor');
    end else begin
      // ensure we have some data in fRowBuffer[] for this row
      inc(fRowFetchedCurrent);
      if fRowFetchedCurrent>=fRowFetched then begin
        if fRowFetchedEnded then
          exit; // no more data
        fRowFetched := 0;
        status := OCI.StmtFetch(fStatement,fError,fRowCount,OCI_FETCH_NEXT,OCI_DEFAULT);
        case Status of
        OCI_SUCCESS:
          fRowFetched := fRowCount; // all rows successfully retrived
        OCI_NO_DATA: begin
          OCI.AttrGet(fStatement,OCI_HTYPE_STMT,@fRowFetched,nil,OCI_ATTR_ROWS_FETCHED,fError);
          if fRowFetched=0 then
            exit; // no more row available -> return false and fCurrentRow=-1
          fRowFetchedEnded := true;
        end;
        else
          OCI.Check(Status,fError); // will raise error
        end;
        fRowFetchedCurrent := 0;
      end;
    end;
  fCurrentRow := sav+1;
  inc(fTotalRowsRetrieved);
  result := true; // mark data available in fRowSetData
end;

end.

