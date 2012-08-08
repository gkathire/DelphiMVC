unit SQLite3;

{
  Simplified interface for SQLite.
  Updated for Sqlite 3 by Tim Anderson (tim@itwriting.com)
  Note: NOT COMPLETE for version 3, just minimal functionality
  Adapted from file created by Pablo Pissanetzky (pablo@myhtpc.net)
  which was based on SQLite.pas by Ben Hochstrasser (bhoc@surfeu.ch)
}

{$IFDEF FPC}
  {$MODE DELPHI}
  {$H+}            (* use AnsiString *)
  {$PACKENUM 4}    (* use 4-byte enums *)
  {$PACKRECORDS C} (* C/C++-compatible record packing *)
{$ELSE}
  {$MINENUMSIZE 4} (* use 4-byte enums *)
{$ENDIF}

{.$define ENHANCEDRTL}
{ define this if you DID install our Enhanced Runtime library or LVCL
  - it's better to define this globaly in the Project/Options window }

{.$define INCLUDE_FTS3}
{ define this if you want to include the FTS3 feature into the library
  - FTS3 is an SQLite module implementing full-text search
  - see http://www.sqlite.org/fts3.html for documentation
  - not defined by default, to save about 50 KB of code size }

{$ifdef UNICODE}
{$undef ENHANCEDRTL} // Delphi 2009.. don't have our Enhanced Runtime library yet
{$endif}

interface

uses Windows;

const
{$IF Defined(MSWINDOWS)}
  SQLiteDLL = 'sqlite3.dll';
{$ELSEIF Defined(DARWIN)}
  SQLiteDLL = 'libsqlite3.dylib';
  {$linklib libsqlite3}
{$ELSEIF Defined(UNIX)}
  SQLiteDLL = 'sqlite3.so';
{$IFEND}

// Return values for sqlite3_exec() and sqlite3_step()


type
  TSQLiteDB = Pointer;
  TSQLiteResult = ^PAnsiChar;
  TSQLiteStmt = Pointer;

type
  PPAnsiCharArray = ^TPAnsiCharArray;
  TPAnsiCharArray = array[0 .. (MaxInt div SizeOf(PAnsiChar))-1] of PAnsiChar;

type
  TSQLiteExecCallback = function(UserData: Pointer; NumCols: integer; ColValues:
    PPAnsiCharArray; ColNames: PPAnsiCharArray): integer; cdecl;
  TSQLiteBusyHandlerCallback = function(UserData: Pointer; P2: integer): integer; cdecl;

  //function prototype for define own collate
  TCollateXCompare = function(UserData: pointer; Buf1Len: integer; Buf1: pointer;
    Buf2Len: integer; Buf2: pointer): integer; cdecl;

{ ************ direct access to sqlite3.c / sqlite3.obj consts and functions }
type
  /// internaly store the SQLite3 database handle
  TSQLHandle = TSQLiteDB;

{$ifndef FPC}
type
  /// a CPU-dependent unsigned integer type cast of a pointer / register
  // - used for 64 bits compatibility, native under Free Pascal Compiler
  PtrUInt = cardinal;
  /// a CPU-dependent unsigned integer type cast of a pointer of pointer
  // - used for 64 bits compatibility, native under Free Pascal Compiler
  PPtrUInt = ^PtrUInt;

  /// a CPU-dependent signed integer type cast of a pointer / register
  // - used for 64 bits compatibility, native under Free Pascal Compiler
  PtrInt = integer;
  /// a CPU-dependent signed integer type cast of a pointer of pointer
  // - used for 64 bits compatibility, native under Free Pascal Compiler
  PPtrInt = ^PtrInt;

  /// unsigned Int64 doesn't exist under Delphi, but is defined in FPC
  QWord = Int64;
{$endif}

type
  {{ RawUnicode is an Unicode String stored in an AnsiString
    - faster than WideString, which are allocated in Global heap (for COM)
    - an AnsiChar(#0) is added at the end, for having a true WideChar(#0) at ending
    - length(RawUnicode) returns memory bytes count: use (length(RawUnicode) shr 1)
     for WideChar count (that's why the definition of this type since Delphi 2009
     is AnsiString(1200) and not UnicodeString)
    - pointer(RawUnicode) is compatible with Win32 'Wide' API call
    - mimic Delphi 2009 UnicodeString, without the WideString or Ansi conversion overhead
    - all conversion to/from AnsiString or RawUTF8 must be explicit }
{$ifdef UNICODE} RawUnicode = type AnsiString(1200); // Codepage for an UnicodeString
{$else}          RawUnicode = type AnsiString;
{$endif}

  {{ RawUTF8 is an UTF-8 String stored in an AnsiString
    - use this type instead of System.UTF8String, which behavior changed
     between Delphi 2009 compiler and previous versions: our implementation
     is consistent and compatible with all versions of Delphi compiler
    - mimic Delphi 2009 UTF8String, without the charset conversion overhead
    - all conversion to/from AnsiString or RawUnicode must be explicit }
{$ifdef UNICODE} RawUTF8 = type AnsiString(CP_UTF8); // Codepage for an UTF8string
{$else}          RawUTF8 = type AnsiString; {$endif}

  {{ WinAnsiString is a WinAnsi-encoded AnsiString (code page 1252)
    - use this type instead of System.String, which behavior changed
     between Delphi 2009 compiler and previous versions: our implementation
     is consistent and compatible with all versions of Delphi compiler
    - all conversion to/from RawUTF8 or RawUnicode must be explicit }
{$ifdef UNICODE} WinAnsiString = type AnsiString(1252); // WinAnsi Codepage
{$else}          WinAnsiString = type AnsiString; {$endif}

{$ifndef UNICODE}
  /// define RawByteString, as it does exist in Delphi 2009/2010
  // - to be used for byte storage into an AnsiString
  // - use this type if you don't want the Delphi compiler not to do any
  // code page conversions when you assign a typed AnsiString to a RawByteString,
  // i.e. a RawUTF8 or a WinAnsiString
  RawByteString = AnsiString;
{$endif}

  PRawUnicode = ^RawUnicode;
  PRawUTF8 = ^RawUTF8;
  PWinAnsiString = ^WinAnsiString;
  PWinAnsiChar = PAnsiChar;

  /// a simple wrapper to UTF-8 encoded zero-terminated PAnsiChar
  // - PAnsiChar is used only for Win-Ansi encoded text
  // - the Synopse SQLite3 framework uses mostly this PUTF8Char type,
  // because all data is internaly stored and expected to be UTF-8 encoded
  PUTF8Char = PAnsiChar;
  PPUTF8Char = ^PUTF8Char;

  /// a Row/Col array of PUTF8Char, for containing sqlite3_get_table() result
  TPUtf8CharArray = array[0..MaxInt div SizeOf(PUTF8Char)-1] of PUTF8Char;
  PPUtf8CharArray = ^TPUtf8CharArray;

  /// a dynamic array of UTF-8 encoded strings
  PRawUTF8DynArray = ^TRawUTF8DynArray;
  TRawUTF8DynArray = array of RawUTF8;

  TInt64Array = array[0..MaxInt div SizeOf(Int64)-1] of Int64;
  PInt64Array = ^TInt64Array;

  PCardinalArray = ^TCardinalArray;
  TCardinalArray = array[0..MaxInt div SizeOf(cardinal)-1] of cardinal;

const
  {{ internal SQLite3 type as Integer }
  SQLITE_INTEGER = 1;
  {{ internal SQLite3 type as Floating point value }
  SQLITE_FLOAT = 2;
  {{ internal SQLite3 type as Text }
  SQLITE_TEXT = 3;
  {{ internal SQLite3 type as Blob }
  SQLITE_BLOB = 4;
  {{ internal SQLite3 type as NULL }
  SQLITE_NULL = 5;

  {{ text is UTF-8 encoded }
  SQLITE_UTF8     = 1;
  {{ text is UTF-16 LE encoded }
  SQLITE_UTF16LE  = 2;
  {{ text is UTF-16 BE encoded }
  SQLITE_UTF16BE  = 3;
  {{ text is UTF-16 encoded, using the system native byte order }
  SQLITE_UTF16    = 4;
  {{ used by sqlite3_create_collation() only }
  SQLITE_UTF16_ALIGNED = 8;


  {{ sqlite_exec() return code: no error occured }
  SQLITE_OK = 0;
  {{ sqlite_exec() return code: SQL error or missing database - legacy generic code }
  SQLITE_ERROR = 1;
  {{ sqlite_exec() return code: An internal logic error in SQLite  }
  SQLITE_INTERNAL = 2;
  {{ sqlite_exec() return code: Access permission denied  }
  SQLITE_PERM = 3;
  {{ sqlite_exec() return code: Callback routine requested an abort  }
  SQLITE_ABORT = 4;
  {{ sqlite_exec() return code: The database file is locked  }
  SQLITE_BUSY = 5;
  {{ sqlite_exec() return code: A table in the database is locked  }
  SQLITE_LOCKED = 6;
  {{ sqlite_exec() return code: A malloc() failed  }
  SQLITE_NOMEM = 7;
  {{ sqlite_exec() return code: Attempt to write a readonly database  }
  SQLITE_READONLY = 8;
  {{ sqlite_exec() return code: Operation terminated by sqlite3_interrupt() }
  SQLITE_INTERRUPT = 9;
  {{ sqlite_exec() return code: Some kind of disk I/O error occurred  }
  SQLITE_IOERR = 10;
  {{ sqlite_exec() return code: The database disk image is malformed  }
  SQLITE_CORRUPT = 11;
  {{ sqlite_exec() return code: (Internal Only) Table or record not found  }
  SQLITE_NOTFOUND = 12;
  {{ sqlite_exec() return code: Insertion failed because database is full  }
  SQLITE_FULL = 13;
  {{ sqlite_exec() return code: Unable to open the database file  }
  SQLITE_CANTOPEN = 14;
  {{ sqlite_exec() return code: (Internal Only) Database lock protocol error  }
  SQLITE_PROTOCOL = 15;
  {{ sqlite_exec() return code: Database is empty  }
  SQLITE_EMPTY = 16;
  {{ sqlite_exec() return code: The database schema changed, and unable to be recompiled }
  SQLITE_SCHEMA = 17;
  {{ sqlite_exec() return code: Too much data for one row of a table  }
  SQLITE_TOOBIG = 18;
  {{ sqlite_exec() return code: Abort due to contraint violation  }
  SQLITE_CONSTRAINT = 19;
  {{ sqlite_exec() return code: Data type mismatch  }
  SQLITE_MISMATCH = 20;
  {{ sqlite_exec() return code: Library used incorrectly  }
  SQLITE_MISUSE = 21;
  {{ sqlite_exec() return code: Uses OS features not supported on host  }
  SQLITE_NOLFS = 22;
  {{ sqlite_exec() return code: Authorization denied  }
  SQLITE_AUTH = 23;
  {{ sqlite_exec() return code: Auxiliary database format error  }
  SQLITE_FORMAT = 24;
  {{ sqlite_exec() return code: 2nd parameter to sqlite3_bind out of range  }
  SQLITE_RANGE = 25;
  {{ sqlite_exec() return code: File opened that is not a database file  }
  SQLITE_NOTADB = 26;

  {{ sqlite3_step() return code: another result row is ready  }
  SQLITE_ROW = 100;
  {{ sqlite3_step() return code: has finished executing  }
  SQLITE_DONE = 101;

{$define USEC}
{ BCC32 -pr fastcall (=Delphi resgister) is buggy, don't know why
 (because of issues with BCC32 itself, I guess) }


procedure sqlite3_free(Msg: PUTF8Char); {$ifdef USEC}cdecl;{$endif} external;
function sqlite3_total_changes(db: TSQLHandle): integer; {$ifdef USEC}cdecl;{$endif} external;
function sqlite3_errcode(db: TSQLHandle): integer; {$ifdef USEC}cdecl;{$endif} external;
function sqlite3_bind_null(hStmt: TSQLHandle; ParamNum: integer): integer; {$ifdef USEC}cdecl;{$endif} external;
procedure sqlite3_busy_timeout(db: TSQLHandle; TimeOut: integer); {$ifdef USEC}cdecl;{$endif} external;
function sqlite3_changes(db: TSQLHandle): integer; {$ifdef USEC}cdecl;{$endif} external;
function sqlite3_bind_parameter_index(hStmt: TSQLHandle; zName: PAnsiChar): integer; {$ifdef USEC}cdecl;{$endif} external;
function sqlite3_prepare(db: TSQLHandle; SQLStatement: PAnsiChar; nBytes: integer; var hStmt: TSQLHandle; var pzTail: PAnsiChar): integer;  {$ifdef USEC}cdecl;{$endif} external;


{{ initialize the SQLite3 database code
  - automaticaly called by the initialization block of this unit
  - so sqlite3.c is compiled with SQLITE_OMIT_AUTOINIT defined }
function sqlite3_initialize: integer; {$ifdef USEC}cdecl;{$endif} external;

{{ shutdown the SQLite3 database core
  - automaticaly called by the finalization block of this unit }
function sqlite3_shutdown: integer; {$ifdef USEC}cdecl;{$endif} external;


{{ Open a SQLite3 database filename, creating a DB handle
  - filename must be UTF-8 encoded (filenames containing international
    characters must be converted to UTF-8 prior to passing them)
  - allocate a sqlite3 object, and return its handle in DB
  - return SQLITE_OK on success
  - an error code (see SQLITE_* const) is returned otherwize - sqlite3_errmsg()
    can be used to obtain an English language description of the error
 - Whatever or not an error occurs when it is opened, resources associated with
   the database connection handle should be released by passing it to
   sqlite3_close() when it is no longer required }
function sqlite3_open(filename: PUTF8Char; var DB: TSQLHandle): integer; {$ifdef USEC}cdecl;{$endif} external;


type
  /// SQLite3 collation (i.e. sort and comparaison) function prototype
  // - this function MUST use s1Len and s2Len parameters during the comparaison:
  // s1 and s2 are not zero-terminated
  TSQLCollateFunc = function(CollateParam: pointer; s1Len: integer; s1: pointer;
    s2Len: integer; s2: pointer) : integer; {$ifdef USEC}cdecl;{$endif}

{{ Define New Collating Sequences
  - add new collation sequences to the database connection specified
  - collation name is to be used in CREATE TABLE t1 (a COLLATE CollationName);
   or in SELECT * FROM t1 ORDER BY c COLLATE CollationName;
  - StringEncoding is either SQLITE_UTF8 either SQLITE_UTF16
  - TSQLDataBase.Create add WIN32CASE, WIN32NOCASE and ISO8601 collations }
function sqlite3_create_collation(DB: TSQLHandle; CollationName: PUTF8Char;
  StringEncoding: integer; CollateParam: pointer; cmp: TSQLCollateFunc): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ Destructor for the sqlite3 object, which handle is DB
  - Applications should finalize all prepared statements and close all BLOB handles
    associated with the sqlite3 object prior to attempting to close the object
    (sqlite3_next_stmt() interface can be used for this task)
  - if invoked while a transaction is open, the transaction is automatically rolled back }
function sqlite3_close(DB: TSQLHandle): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ Return the version of the SQLite database engine, in ascii format
  - currently returns '3.6.23' }
function sqlite3_libversion: PUTF8Char; {$ifdef USEC}cdecl;{$endif} external;

{{ Returns English-language text that describes an error,
   using UTF-8 encoding (which, with English text, is the same as Ansi).
  - Memory to hold the error message string is managed internally.
     The application does not need to worry about freeing the result.
     However, the error string might be overwritten or deallocated by
     subsequent calls to other SQLite interface functions. }
function sqlite3_errmsg(DB: TSQLHandle): PAnsiChar; {$ifdef USEC}cdecl;{$endif} external;

{{ Returns the rowid of the most recent successful INSERT into the database }
function sqlite3_last_insert_rowid(DB: TSQLHandle): Int64; {$ifdef USEC}cdecl;{$endif} external;

{{ Convenience Routines For Running Queries
  - fill Table with all Row/Col for the SQL query
  - use sqlite3_free_table() to release memory }
function sqlite3_get_table(DB: TSQLHandle; SQL: PUTF8Char; var Table: PPUTF8CharArray;
  var ResultRow, ResultCol: integer; var Error: PUTF8Char): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ release memory allocated for a sqlite3_get_table() result }
procedure sqlite3_free_table(Table: PPUTF8CharArray); {$ifdef USEC}cdecl;{$endif} external;

{{ One-Step Query Execution Interface }
function sqlite3_exec(DB: TSQLHandle; SQL: PUTF8Char; CallBack, Args: pointer; Error: PUTF8Char): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ Compile a SQL query into byte-code
  - SQL must contains an UTF8-encoded null-terminated string query
  - SQL_bytes contains -1 (to stop at the null char) or the number of bytes in
   the input string, including the null terminator
  - return SQLITE_OK on success or an error code - see SQLITE_* and sqlite3_errmsg()
  - S will contain an handle of the resulting statement (an opaque sqlite3_stmt
   object) on success, or will 0 on error - the calling procedure is responsible
   for deleting the compiled SQL statement using sqlite3_finalize() after it has
   finished with it
  - in this "v2" interface, the prepared statement that is returned contains a
   copy of the original SQL text
  - this routine only compiles the first statement in SQL, so SQLtail is left pointing
   to what remains uncompiled }
function sqlite3_prepare_v2(DB: TSQLHandle; SQL: PUTF8Char; SQL_bytes: integer;
  var S: TSQLHandle; var SQLtail: PUTF8Char): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ Delete a previously prepared statement
  - return SQLITE_OK on success or an error code - see SQLITE_* and sqlite3_errmsg()
  - this routine can be called at any point during the execution of the prepared
   statement. If the virtual machine has not completed execution when this routine
   is called, that is like encountering an error or an interrupt. Incomplete updates
   may be rolled back and transactions canceled, depending on the circumstances,
   and the error code returned will be SQLITE_ABORT }
function sqlite3_finalize(S: TSQLHandle): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ Find the next prepared statement
  - this interface returns a handle to the next prepared statement after S,
   associated with the database connection DB.
  - if S is 0 then this interface returns a pointer to the first prepared
   statement associated with the database connection DB.
  - if no prepared statement satisfies the conditions of this routine, it returns 0 }
function sqlite3_next_stmt(DB: TSQLHandle; S: TSQLHandle): TSQLHandle; {$ifdef USEC}cdecl;{$endif} external;

{{ Reset a prepared statement object back to its initial state, ready to be re-Prepared
  - if the most recent call to sqlite3_step(S) returned SQLITE_ROW or SQLITE_DONE,
   or if sqlite3_step(S) has never before been called with S, then sqlite3_reset(S)
   returns SQLITE_OK.
  - return an appropriate error code if the most recent call to sqlite3_step(S) failed
  - any SQL statement variables that had values bound to them using the sqlite3_bind_*()
   API retain their values. Use sqlite3_clear_bindings() to reset the bindings. }
function sqlite3_reset(S: TSQLHandle): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ Evaluate An SQL Statement, returning a result status:
  - SQLITE_BUSY means that the database engine was unable to acquire the database
   locks it needs to do its job. If the statement is a COMMIT or occurs outside of
   an explicit transaction, then you can retry the statement. If the statement
   is not a COMMIT and occurs within a explicit transaction then you should
   rollback the transaction before continuing.
  - SQLITE_DONE means that the statement has finished executing successfully.
   sqlite3_step() should not be called again on this virtual machine without
   first calling sqlite3_reset() to reset the virtual machine state back.
  - SQLITE_ROW is returned each time a new row of data is ready for processing by
   the caller. The values may be accessed using the column access functions below.
   sqlite3_step() has to be called again to retrieve the next row of data.
  - SQLITE_MISUSE means that the this routine was called inappropriately. Perhaps
   it was called on a prepared statement that has already been finalized or on
   one that had previously returned SQLITE_ERROR or SQLITE_DONE. Or it could be
   the case that the same database connection is being used by two or more threads
   at the same moment in time.
  - SQLITE_SCHEMA means that the database schema changes, and the SQL statement
   has been recompiled and run again, but the schame changed in a way that makes
   the statement no longer valid, as a fatal error.
  - another specific error code is returned on fatal error }
function sqlite3_step(S: TSQLHandle): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ number of columns in the result set for the statement }
function sqlite3_column_count(S: TSQLHandle): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ datatype code for the initial data type of a result column
  - returned value is one of SQLITE_INTEGER, SQLITE_FLOAT, SQLITE_TEXT,
   SQLITE_BLOB or SQLITE_NULL
  - S is the SQL statement, after sqlite3_step(S) returned SQLITE_ROW
  - Col is the column number, indexed from 0 to sqlite3_column_count(S)-1
  - must be called before any sqlite3_column_*() statement, which may result in
   an implicit type conversion: in this case, value is undefined }
function sqlite3_column_type(S: TSQLHandle; Col: integer): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ returns a zero-terminated UTF-8 string containing the declared datatype of a result column }
function sqlite3_column_decltype(S: TSQLHandle; Col: integer): PAnsiChar; {$ifdef USEC}cdecl;{$endif} external;

{{ returns the name of a result column as a zero-terminated UTF-8 string }
function sqlite3_column_name(S: TSQLHandle; Col: integer): PUTF8Char; {$ifdef USEC}cdecl;{$endif} external;

{{ number of bytes for a BLOB or UTF-8 string result
  - S is the SQL statement, after sqlite3_step(S) returned SQLITE_ROW
  - Col is the column number, indexed from 0 to sqlite3_column_count(S)-1
  - an implicit conversion into UTF-8 text is made for a numeric value or
    UTF-16 column: you must call sqlite3_column_text() or sqlite3_column_blob()
    before calling sqlite3_column_bytes() to perform the conversion itself }
function sqlite3_column_bytes(S: TSQLHandle; Col: integer): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ get the value handle of the Col column in the current row of prepared statement S
  - this handle represent a sqlite3_value object
  - this handle can then be accessed with any sqlite3_value_*() function below }
function sqlite3_column_value(S: TSQLHandle; Col: integer): TSQLHandle; {$ifdef USEC}cdecl;{$endif} external;

{{ converts the Col column in the current row prepared statement S
  into a floating point value and returns a copy of that value
  - NULL is converted into 0.0
  - INTEGER is converted into corresponding floating point value
  - TEXT or BLOB is converted from all correct ASCII numbers with 0.0 as default }
function sqlite3_column_double(S: TSQLHandle; Col: integer): double; {$ifdef USEC}cdecl;{$endif} external;

{{ converts the Col column in the current row prepared statement S
  into an integer 32bits value and returns a copy of that value
  - NULL is converted into 0
  - FLOAT is truncated into corresponding integer value
  - TEXT or BLOB is converted from all correct ASCII numbers with 0 as default }
function sqlite3_column_int(S: TSQLHandle; Col: integer): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ converts the Col column in the current row prepared statement S
  into an integer 32bits value and returns a copy of that value
  - NULL is converted into 0
  - FLOAT is truncated into corresponding integer value
  - TEXT or BLOB is converted from all correct ASCII numbers with 0 as default }
function sqlite3_column_int64(S: TSQLHandle; Col: integer): int64; {$ifdef USEC}cdecl;{$endif} external;

{{ converts the Col column in the current row prepared statement S
  into a zero-terminated UTF-8 string and returns a pointer to that string
  - NULL is converted into nil
  - INTEGER or FLOAT are converted into ASCII rendering of the numerical value
  - TEXT is returned directly (with UTF-16 -> UTF-8 encoding if necessary)
  - BLOB add a zero terminator if needed }
function sqlite3_column_text(S: TSQLHandle; Col: integer): PUTF8Char; {$ifdef USEC}cdecl;{$endif} external;

{{ converts the Col column in the current row of prepared statement S
  into a BLOB and then returns a pointer to the converted value
  - NULL is converted into nil
  - INTEGER or FLOAT are converted into ASCII rendering of the numerical value
  - TEXT and BLOB are returned directly }
function sqlite3_column_blob(S: TSQLHandle; Col: integer): PAnsiChar; {$ifdef USEC}cdecl;{$endif} external;


{{ datatype code for a sqlite3_value object, specified by its handle
  - returned value is one of SQLITE_INTEGER, SQLITE_FLOAT, SQLITE_TEXT,
   SQLITE_BLOB or SQLITE_NULL
  - must be called before any sqlite3_value_*() statement, which may result in
   an implicit type conversion: in this case, value is undefined }
function sqlite3_value_type(V: TSQLHandle): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ number of bytes for a sqlite3_value object, specified by its handle
  - used after a call to sqlite3_value_text() or sqlite3_value_blob()
  to determine buffer size (in bytes) }
function sqlite3_value_bytes(V: TSQLHandle): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ converts a sqlite3_value object, specified by its handle,
  into a floating point value and returns a copy of that value }
function sqlite3_value_double(V: TSQLHandle): double; {$ifdef USEC}cdecl;{$endif} external;

{{ converts a sqlite3_value object, specified by its handle,
  into an integer value and returns a copy of that value }
function sqlite3_value_int64(V: TSQLHandle): Int64; {$ifdef USEC}cdecl;{$endif} external;

{{ converts a sqlite3_value object, specified by its handle,
  into an UTF-8 encoded string, and returns a copy of that value }
function sqlite3_value_text(V: TSQLHandle): PUTF8Char; {$ifdef USEC}cdecl;{$endif} external;

{{ converts a sqlite3_value object, specified by its handle,
  into a blob memory, and returns a copy of that value }
function sqlite3_value_blob(V: TSQLHandle): PUTF8Char; {$ifdef USEC}cdecl;{$endif} external;

{{ Number Of SQL Parameters for a prepared statement
 - returns the index of the largest (rightmost) parameter. For all forms
  except ?NNN, this will correspond to the number of unique parameters.
  If parameters of the ?NNN are used, there may be gaps in the list. }
function sqlite3_bind_parameter_count(S: TSQLHandle): integer; {$ifdef USEC}cdecl;{$endif} external;

type
  /// type for a binding destructor - use FreeMem() e.g.
  TDestroyPtr = procedure(p: pointer); {$ifdef USEC}cdecl;{$endif}

const
  /// DestroyPtr set to SQLITE_STATIC if data is constant and will never change
  SQLITE_STATIC    = pointer(0);
  /// DestroyPtr set to SQLITE_TRANSIENT for SQLite3 to make private copy of the data
  SQLITE_TRANSIENT = pointer(-1);

{{ Bind a Text Value to a parameter of a prepared statement
  - return SQLITE_OK on success or an error code - see SQLITE_* and sqlite3_errmsg()
  - S is a statement prepared by a previous call to sqlite3_prepare_v2()
  - Param is the index of the SQL parameter to be set. The leftmost SQL parameter
   has an index of 1.
  - Text must contains an UTF8-encoded null-terminated string query
  - Text_bytes contains -1 (to stop at the null char) or the number of bytes in
   the input string, including the null terminator
  - leave DestroyPtr as SQLITE_STATIC for static binding
  - set DestroyPtr to SQLITE_TRANSIENT for SQLite to make its own private copy of the data
  - or provide a custom destroyer function in DestroyPtr, as FreeMem }
function sqlite3_bind_text(S: TSQLHandle; Param: integer; Text: PAnsiChar; Text_bytes: integer = -1;
  DestroyPtr: TDestroyPtr=SQLITE_STATIC): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ Bind a Blob Value to a parameter of a prepared statement
  - return SQLITE_OK on success or an error code - see SQLITE_* and sqlite3_errmsg()
  - S is a statement prepared by a previous call to sqlite3_prepare_v2()
  - Param is the index of the SQL parameter to be set (leftmost=1)
  - Buf must contains an UTF8-encoded null-terminated string query
  - Buf_bytes contains the number of bytes in Buf
  - leave DestroyPtr as nil for static binding
  - set DestroyPtr to pointer(-1) for SQLite to make its own private copy of the data
  - or provide a custom destroyer function in DestroyPtr, as FreeMem }
function sqlite3_bind_blob(S: TSQLHandle; Param: integer; Buf: pointer; Buf_bytes: integer;
  DestroyPtr: TDestroyPtr=nil): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ bind a ZeroBlob buffer to a parameter
  - uses a fixed amount of memory (just an integer to hold its size) while
   it is being processed. Zeroblobs are intended to serve as placeholders
   for BLOBs whose content is later written using incremental BLOB I/O routines.
  - a negative value for the Size parameter results in a zero-length BLOB
  - the leftmost SQL parameter has an index of 1, but ?NNN may override it }
function sqlite3_bind_zeroblob(S: TSQLHandle; Param: integer; Size: integer): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ Bind a floating point Value to a parameter of a prepared statement
  - return SQLITE_OK on success or an error code - see SQLITE_* and sqlite3_errmsg()
  - S is a statement prepared by a previous call to sqlite3_prepare_v2()
  - Param is the index of the SQL parameter to be set (leftmost=1)
  - Value is the floating point number to bind }
function sqlite3_bind_double(S: TSQLHandle; Param: integer; Value: double): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ Bind a 32 bits Integer Value to a parameter of a prepared statement
  - return SQLITE_OK on success or an error code - see SQLITE_* and sqlite3_errmsg()
  - S is a statement prepared by a previous call to sqlite3_prepare_v2()
  - Param is the index of the SQL parameter to be set (leftmost=1)
  - Value is the 32 bits Integer to bind }
function sqlite3_bind_Int(S: TSQLHandle; Param: integer; Value: integer): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ Bind a 64 bits Integer Value to a parameter of a prepared statement
  - return SQLITE_OK on success or an error code - see SQLITE_* and sqlite3_errmsg()
  - S is a statement prepared by a previous call to sqlite3_prepare_v2()
  - Param is the index of the SQL parameter to be set (leftmost=1)
  - Value is the 64 bits Integer to bind }
function sqlite3_bind_Int64(S: TSQLHandle; Param: integer; Value: Int64): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ Reset All Bindings On A Prepared Statement }
function sqlite3_clear_bindings(S: TSQLHandle): integer; {$ifdef USEC}cdecl;{$endif} external;

{{ Open a BLOB For Incremental I/O
  - returns a BLOB handle for row RowID, column ColumnName, table TableName
    in database DBName; in other words, the same BLOB that would be selected by:
  ! SELECT ColumnName FROM DBName.TableName WHERE rowid = RowID; }
function sqlite3_blob_open(DB: TSQLHandle; DBName, TableName, ColumnName: PUTF8Char;
  RowID: Int64; Flags: Integer; var Blob: TSQLHandle): Integer; {$ifdef USEC}cdecl;{$endif} external;

{{ Close A BLOB Handle }
function sqlite3_blob_close(Blob: TSQLHandle): Integer; {$ifdef USEC}cdecl;{$endif} external;

{{ Read Data From a BLOB Incrementally }
function sqlite3_blob_read(Blob: TSQLHandle; const Data; Count, Offset: Integer): Integer; {$ifdef USEC}cdecl;{$endif} external;

{{ Write Data To a BLOB Incrementally }
function sqlite3_blob_write(Blob: TSQLHandle; const Data; Count, Offset: Integer): Integer; {$ifdef USEC}cdecl;{$endif} external;

{{ Return The Size Of An Open BLOB }
function sqlite3_blob_bytes(Blob: TSQLHandle): Integer; {$ifdef USEC}cdecl;{$endif} external;

/// get the signed 32 bits integer value stored in P^
// - we use the PtrInt result type, even if expected to be 32 bits, to use
// native CPU register size (don't want any 32 bits overflow here)
function GetInteger(P: PUTF8Char): PtrInt; overload;

/// get the signed 32 bits integer value stored in P^
// - this version return 0 in err if no error occured, and 1 if an invalid
// character was found, not its exact index as for the val() function
// - we use the PtrInt result type, even if expected to be 32 bits, to use
// native CPU register size (don't want any 32 bits overflow here)
function GetInteger(P: PUTF8Char; var err: integer): PtrInt; overload;

function MyStrLen(S: PUTF8Char): PtrInt;



// In the SQL strings input to sqlite3_prepare() and sqlite3_prepare16(),
// one or more literals can be replace by a wildcard "?" or ":N:" where
// N is an integer.  These value of these wildcard literals can be set
// using the routines listed below.
//
// In every case, the first parameter is a pointer to the sqlite3_stmt
// structure returned from sqlite3_prepare().  The second parameter is the
// index of the wildcard.  The first "?" has an index of 1.  ":N:" wildcards
// use the index N.
//
// The fifth parameter to sqlite3_bind_blob(), sqlite3_bind_text(), and
//sqlite3_bind_text16() is a destructor used to dispose of the BLOB or
//text after SQLite has finished with it.  If the fifth argument is the
// special value SQLITE_STATIC, then the library assumes that the information
// is in static, unmanaged space and does not need to be freed.  If the
// fifth argument has the value SQLITE_TRANSIENT, then SQLite makes its
// own private copy of the data.
//
// The sqlite3_bind_* routine must be called before sqlite3_step() after
// an sqlite3_prepare() or sqlite3_reset().  Unbound wildcards are interpreted
// as NULL.
//


type
  TSQLite3Destructor = procedure(Ptr: Pointer); cdecl;


function SQLiteFieldType(SQLiteFieldTypeCode: Integer): AnsiString;
function SQLiteErrorStr(SQLiteErrorCode: Integer): AnsiString;

implementation

uses
  SysUtils;

  { ************ direct access to sqlite3.c / sqlite3.obj consts and functions }
{
  Code below will link all database engine, from amalgamation source file:

 - compiled with free Borland C++ compiler 5.5.1 from the command line:
     d:\dev\bcc\bin\bcc32 -6 -O2 -c -d -u- sqlite3.c
 - the following defines must be added in the beginning of the sqlite3.c file:

//#define SQLITE_ENABLE_FTS3
//  this unit is FTS3-ready, but not compiled with it by default
//  but for FTS3 to compile, you will have to change:
//    isspace -> sqlite3Isspace in fts3isspace() function,
//    tolower -> sqlite3Tolower in simpleNext() function,
//    isalnum -> sqlite3Isalnum in simpleCreate() function
//  this conditional is defined at compile time, in order to create sqlite3fts3.obj
#define SQLITE_DEFAULT_MEMSTATUS 0
//  don't need any debug here
#define SQLITE_THREADSAFE 0
//  assuming multi-thread safety is made by caller
#define SQLITE_OMIT_SHARED_CACHE
// no need of shared cache in a threadsafe calling model
#define SQLITE_OMIT_AUTOINIT
//  sqlite3_initialize() is done in initialization section below -> no AUTOINIT
#define SQLITE_OMIT_DEPRECATED
//  spare some code size
#define SQLITE_OMIT_TRACE 1
// trace is time consuming (at least under windows)
#define SQLITE_OMIT_LOAD_EXTENSION
// we don't need extension in an embedded engine
//#define SQLITE_OMIT_LOOKASIDE
// since we use FastMM4, LookAside is not needed but seems mandatory in c source

and, in the sqlite3.c source file, the following functions are made external
in order to allow our proprietary but simple and efficient encryption system:

extern int winRead(
  sqlite3_file *id,          /* File to read from */
  void *pBuf,                /* Write content into this buffer */
  int amt,                   /* Number of bytes to read */
  sqlite3_int64 offset       /* Begin reading at this offset */
);

extern int winWrite(
  sqlite3_file *id,         /* File to write into */
  const void *pBuf,         /* The bytes to be written */
  int amt,                  /* Number of bytes to write */
  sqlite3_int64 offset      /* Offset into the file to begin writing at */
);

}

{$ifdef INCLUDE_FTS3}
{$L sqlite3.obj}       // link SQlite3 database engine
{$else}
{$L sqlite3fts3.obj}   // link SQlite3 database engine with FTS3
{$endif}


// we then implement all needed Borland C++ runtime functions in pure pascal:

function _ftol: Int64;
// Borland C++ float to integer (Int64) conversion
asm
  jmp System.@Trunc  // FST(0) -> EDX:EAX, as expected by BCC32 compiler
end;

function _ftoul: Int64;
// Borland C++ float to integer (Int64) conversion
asm
  jmp System.@Trunc  // FST(0) -> EDX:EAX, as expected by BCC32 compiler
end;

function malloc(size: cardinal): Pointer; cdecl; { always cdecl }
// the SQLite3 database engine will use the FastMM4 very fast heap manager
begin
  GetMem(Result, size);
end;

procedure free(P: Pointer); cdecl; { always cdecl }
// the SQLite3 database engine will use the FastMM4 very fast heap manager
begin
  FreeMem(P);
end;

function realloc(P: Pointer; Size: Integer): Pointer; cdecl; { always cdecl }
// the SQLite3 database engine will use the FastMM4 very fast heap manager
begin
  result := P;
  ReallocMem(result,Size);
end;

function memset(P: Pointer; B: Integer; count: Integer): pointer; cdecl; { always cdecl }
// a fast full pascal version of the standard C library function
begin
  result := P;
  FillChar(P^, count, B);
end;

procedure memmove(dest, source: pointer; count: Integer); cdecl; { always cdecl }
// a fast full pascal version of the standard C library function
begin
  Move(source^, dest^, count); // move() is overlapping-friendly
end;

procedure memcpy(dest, source: Pointer; count: Integer); cdecl; { always cdecl }
// a fast full pascal version of the standard C library function
begin
  Move(source^, dest^, count);
end;

function atol(P: pointer): integer; cdecl; { always cdecl }
// a fast full pascal version of the standard C library function
begin
  result := GetInteger(P);
end;

var __turbofloat: word; { not used, but must be present for linking }

// Borland C++ and Delphi share the same low level Int64 _ll*() functions:

procedure _lldiv;
asm
  jmp System.@_lldiv
end;

procedure _lludiv;
asm
  jmp System.@_lludiv
end;

procedure _llmod;
asm
  jmp System.@_llmod
end;

procedure _llmul;
asm
  jmp System.@_llmul
end;

procedure _llumod;
asm
  jmp System.@_llumod
end;

procedure _llshl;
asm
  jmp System.@_llshl
end;

procedure _llshr;
asm
{$ifndef ENHANCEDRTL} // need this code for Borland/CodeGear default System.pas
  shrd    eax, edx, cl
  sar     edx, cl
  cmp     cl, 32
  jl      @@Done
  cmp     cl, 64
  jge     @@RetSign
  mov     eax, edx
  sar     edx, 31
  ret
@@RetSign:
  sar     edx, 31
  mov     eax, edx
@@Done:
{$else}
  // our customized System.pas didn't forget to put _llshr in its interface :)
  jmp System.@_llshr
{$endif}
end;

procedure _llushr;
asm
  jmp System.@_llushr
end;

function strlen(p: PAnsiChar): integer; cdecl; { always cdecl }
// a fast full pascal version of the standard C library function
begin // called only by some obscure FTS3 functions (normal code use dedicated functions)
  result := MyStrLen(pointer(p));
end;

function memcmp(p1, p2: pByte; Size: integer): integer; cdecl; { always cdecl }
// a fast full pascal version of the standard C library function
begin
  if (p1<>p2) and (Size<>0) then
    if p1<>nil then
      if p2<>nil then begin
        repeat
          if p1^<>p2^ then begin
            result := p1^-p2^;
            exit;
          end;
          dec(Size);
          inc(p1);
          inc(p2);
        until Size=0;
        result := 0;
      end else
      result := 1 else
    result := -1 else
  result := 0;
end;

function strncmp(p1, p2: PByte; Size: integer): integer; cdecl; { always cdecl }
// a fast full pascal version of the standard C library function
var i: integer;
begin
  for i := 1 to Size do begin
    result := p1^-p2^;
    if (result<>0) or (p1^=0) then
      exit;
    inc(p1);
    inc(p2);
  end;
  result := 0;
end;

// qsort() is used if SQLITE_ENABLE_FTS3 is defined
type // this function type is defined for calling termDataCmp() in sqlite3.c
  qsort_compare_func = function(P1,P2: pointer): integer; {$ifdef USEC}cdecl;{$endif}

procedure QuickSort(baseP: PAnsiChar; Width: integer; L, R: Integer; comparF: qsort_compare_func);
// code below is very fast and optimized
procedure Exchg(P1,P2: PAnsiChar; Size: integer);
var B: AnsiChar;
    i: integer;
begin
  for i := 1 to Size do begin
    B := P1^;
    P1^ := P2^;
    P2^ := B;
    inc(P1);
    inc(P2);
  end;
end;
var I, J, P: Integer;
    PP, C: PAnsiChar;
begin
  repeat
    I := L;
    J := R;
    P := (L+R) shr 1;
    repeat
      PP := baseP+P*Width; // compute PP at every loop, since P may change
      C := baseP+I*Width;
      while comparF(C,PP)<0 do begin
        inc(I);
        inc(C,width); // avoid slower multiplication in loop
      end;
      C := baseP+J*Width;
      while comparF(C,PP)>0 do begin
        dec(J);
        dec(C,width); // avoid slower multiplication in loop
      end;
      if I<=J then begin
        Exchg(baseP+I*Width,baseP+J*Width,Width); // fast memory exchange
        if P=I then P := J else if P=J then P := I;
        inc(I);
        dec(J);
      end;
    until I>J;
    if L<J then
      QuickSort(baseP, Width, L, J, comparF);
    L := I;
  until I>=R;
end;

procedure qsort(baseP: PAnsiChar; NElem, Width: integer; comparF: qsort_compare_func);
  cdecl; { always cdecl }
// a fast full pascal version of the standard C library function
begin
  if (cardinal(NElem)>1) and (Width>0) then
    QuickSort(baseP, Width, 0, NElem-1, comparF);
end;

var
  { as standard C library documentation states:
  Statically allocated buffer, shared by the functions gmtime() and localtime().
  Each call of these functions overwrites the content of this structure. }
  atm: packed record
    tm_sec: Integer;            { Seconds.      [0-60] (1 leap second) }
    tm_min: Integer;            { Minutes.      [0-59]  }
    tm_hour: Integer;           { Hours.        [0-23]  }
    tm_mday: Integer;           { Day.          [1-31]  }
    tm_mon: Integer;            { Month.        [0-11]  }
    tm_year: Integer;           { Year          - 1900. }
    tm_wday: Integer;           { Day of week.  [0-6]   }
    tm_yday: Integer;           { Days in year. [0-365] }
    tm_isdst: Integer;          { DST.          [-1/0/1]}
    __tm_gmtoff: Integer;       { Seconds east of UTC.  }
    __tm_zone: ^Char;           { Timezone abbreviation.}
  end;

function localtime(t: PCardinal): pointer; cdecl; { always cdecl }
// a fast full pascal version of the standard C library function
var uTm: TFileTime;
    lTm: TFileTime;
    S: TSystemTime;
begin
  Int64(uTm) := (Int64(t^) + 11644473600)*10000000; // unix time to dos file time
  FileTimeToLocalFileTime(uTM,lTM);
  FileTimeToSystemTime(lTM,S);
  with atm do begin
    tm_sec := S.wSecond;
    tm_min := S.wMinute;
    tm_hour := S.wHour;
    tm_mday := S.wDay;
    tm_mon := S.wMonth-1;
    tm_year := S.wYear-1900;
    tm_wday := S.wDayOfWeek;
  end;
  result := @atm;
end;

function GetInteger(P: PUTF8Char): PtrInt;
var c: PtrUInt;
    minus: boolean;
begin
  if P=nil then begin
    result := 0;
    exit;
  end;
  if P^=' ' then repeat inc(P) until P^<>' ';
  if P^='-' then begin
    minus := true;
    repeat inc(P) until P^<>' ';
  end else begin
    minus := false;
    if P^='+' then
      repeat inc(P) until P^<>' ';
  end;
  c := byte(P^)-48;
  if c>9 then
    result := 0 else begin
    result := c;
    inc(P);
    repeat
      c := byte(P^)-48;
      if c>9 then
        break else
        result := result*10+PtrInt(c);
      inc(P);
    until false;
  end;
  if minus then
    result := -result;
end;

function GetInteger(P: PUTF8Char; var err: integer): PtrInt;
var c: PtrUInt;
    minus: boolean;
begin
  if P=nil then begin
    result := 0;
    err := 1;
    exit;
  end else
    err := 0;
  if P^=' ' then repeat inc(P) until P^<>' ';
  if P^='-' then begin
    minus := true;
    repeat inc(P) until P^<>' ';
  end else begin
    minus := false;
    if P^='+' then
      repeat inc(P) until P^<>' ';
  end;
  c := byte(P^)-48;
  if c>9 then begin
    err := 1;
    result := 0;
    exit;
  end else begin
    result := c;
    inc(P);
    repeat
      c := byte(P^)-48;
      if c>9 then begin
        if byte(P^)<>0 then
          err := 1;
        break;
      end else
        result := result*10+PtrInt(c);
      inc(P);
    until false;
  end;
  if minus then
    result := -result;
end;

function MyStrLen(S: PUTF8Char): PtrInt;
{$ifdef PUREPASCAL}
begin
  result := 0;
  if S<>nil then
  while true do
    if S[0]<>#0 then
    if S[1]<>#0 then
    if S[2]<>#0 then
    if S[3]<>#0 then begin
      inc(S,4);
      inc(result,4);
    end else begin
      inc(result,3);
      exit;
    end else begin
      inc(result,2);
      exit;
    end else begin
      inc(result);
      exit;
    end else
      exit;
end;
{$else}
// faster than default SysUtils version
asm
     test eax,eax
     jz @@z
     cmp   byte ptr [eax+0],0; je @@0
     cmp   byte ptr [eax+1],0; je @@1
     cmp   byte ptr [eax+2],0; je @@2
     cmp   byte ptr [eax+3],0; je @@3
     push  eax
     and   eax,-4              {DWORD Align Reads}
@@Loop:
     add   eax,4
     mov   edx,[eax]           {4 Chars per Loop}
     lea   ecx,[edx-$01010101]
     not   edx
     and   edx,ecx
     and   edx,$80808080       {Set Byte to $80 at each #0 Position}
     jz    @@Loop              {Loop until any #0 Found}
@@SetResult:
     pop   ecx
     bsf   edx,edx             {Find First #0 Position}
     shr   edx,3               {Byte Offset of First #0}
     add   eax,edx             {Address of First #0}
     sub   eax,ecx
@@z: ret
@@0: xor eax,eax; ret
@@1: mov eax,1;   ret
@@2: mov eax,2;   ret
@@3: mov eax,3
end;
{$endif}


type
{$A4} // C alignment is 4 bytes
  TSQLFile = record // called winFile (expand sqlite3_file) in sqlite3.c
    pMethods: pointer;     // sqlite3_io_methods_ptr
    h: THandle;            // Handle for accessing the file
    bulk: cardinal;        // lockType+sharedLockByte are word-aligned
    lastErrno: cardinal;   // The Windows errno from the last I/O error
    // asm code generated from c is [esi+12] for lastErrNo -> OK
  end;
{$A+}

function WinWrite(var F: TSQLFile; buf: PByte; buflen: integer; off: Int64): integer; {$ifdef USEC}cdecl;{$endif}
// Write data from a buffer into a file.  Return SQLITE_OK on success
// or some other error code on failure
var n: integer;
    offset: Int64Rec;
label err;
begin
  offset.Lo := Int64Rec(off).Lo;
  offset.Hi := Int64Rec(off).Hi and $7fffffff; // offset must be positive (u64)
  result := SetFilePointer(F.h,offset.Lo,@offset.Hi,FILE_BEGIN);
  if result=-1 then begin
    result := GetLastError;
    if result<>NO_ERROR then begin
      F.lastErrno := result;
      result := SQLITE_FULL;
      exit;
    end;
  end;

  n := buflen;
  while n>0 do begin
    if not WriteFile(F.h,buf^,n,cardinal(result),nil) then begin
err:  F.lastErrno := GetLastError;
      result := SQLITE_FULL;
      exit;
    end;
    if result=0 then break;
    dec(n,result);
    inc(buf,result);
  end;
  if n>result then
    goto err;
  result := SQLITE_OK;
end;

const
  SQLITE_IOERR_READ       = $010A;
  SQLITE_IOERR_SHORT_READ = $020A;

function WinRead(var F: TSQLFile; buf: PByte; buflen: integer; off: Int64): integer; {$ifdef USEC}cdecl;{$endif}
// Read data from a file into a buffer.  Return SQLITE_OK on success
// or some other error code on failure
var offset: Int64Rec;
begin
  offset.Lo := Int64Rec(off).Lo;
  offset.Hi := Int64Rec(off).Hi and $7fffffff; // offset must be positive (u64)
  result := SetFilePointer(F.h,offset.Lo,@offset.Hi,FILE_BEGIN);
  if result=-1 then begin
    result := GetLastError;
    if result<>NO_ERROR then begin
      F.lastErrno := result;
      result := SQLITE_FULL;
      exit;
    end;
  end;
  if not ReadFile(F.h,buf^,buflen,cardinal(result),nil) then begin
    F.lastErrno := GetLastError;
    result := SQLITE_IOERR_READ;
    exit;
  end;
  dec(buflen,result);
  if buflen>0 then begin // remaining bytes are set to 0
    inc(buf,result);
    fillchar(buf^,buflen,0);
    result := SQLITE_IOERR_SHORT_READ;
  end else
    result := SQLITE_OK;
end;

//End of Sqlite static Code

function SQLiteFieldType(SQLiteFieldTypeCode: Integer): AnsiString;
begin
  case SQLiteFieldTypeCode of
    SQLITE_INTEGER: Result := 'Integer';
    SQLITE_FLOAT: Result := 'Float';
    SQLITE_TEXT: Result := 'Text';
    SQLITE_BLOB: Result := 'Blob';
    SQLITE_NULL: Result := 'Null';
  else
    Result := 'Unknown SQLite Field Type Code "' + AnsiString(IntToStr(SQLiteFieldTypeCode)) + '"';
  end;
end;

function SQLiteErrorStr(SQLiteErrorCode: Integer): AnsiString;
begin
  case SQLiteErrorCode of
    SQLITE_OK: Result := 'Successful result';
    SQLITE_ERROR: Result := 'SQL error or missing database';
    SQLITE_INTERNAL: Result := 'An internal logic error in SQLite';
    SQLITE_PERM: Result := 'Access permission denied';
    SQLITE_ABORT: Result := 'Callback routine requested an abort';
    SQLITE_BUSY: Result := 'The database file is locked';
    SQLITE_LOCKED: Result := 'A table in the database is locked';
    SQLITE_NOMEM: Result := 'A malloc() failed';
    SQLITE_READONLY: Result := 'Attempt to write a readonly database';
    SQLITE_INTERRUPT: Result := 'Operation terminated by sqlite3_interrupt()';
    SQLITE_IOERR: Result := 'Some kind of disk I/O error occurred';
    SQLITE_CORRUPT: Result := 'The database disk image is malformed';
    SQLITE_NOTFOUND: Result := '(Internal Only) Table or record not found';
    SQLITE_FULL: Result := 'Insertion failed because database is full';
    SQLITE_CANTOPEN: Result := 'Unable to open the database file';
    SQLITE_PROTOCOL: Result := 'Database lock protocol error';
    SQLITE_EMPTY: Result := 'Database is empty';
    SQLITE_SCHEMA: Result := 'The database schema changed';
    SQLITE_TOOBIG: Result := 'Too much data for one row of a table';
    SQLITE_CONSTRAINT: Result := 'Abort due to contraint violation';
    SQLITE_MISMATCH: Result := 'Data type mismatch';
    SQLITE_MISUSE: Result := 'Library used incorrectly';
    SQLITE_NOLFS: Result := 'Uses OS features not supported on host';
    SQLITE_AUTH: Result := 'Authorization denied';
    SQLITE_FORMAT: Result := 'Auxiliary database format error';
    SQLITE_RANGE: Result := '2nd parameter to sqlite3_bind out of range';
    SQLITE_NOTADB: Result := 'File opened that is not a database file';
    SQLITE_ROW: Result := 'sqlite3_step() has another row ready';
    SQLITE_DONE: Result := 'sqlite3_step() has finished executing';
  else
    Result := 'Unknown SQLite Error Code "' + AnsiString(IntToStr(SQLiteErrorCode)) + '"';
  end;
end;

function ColValueToStr(Value: PAnsiChar): AnsiString;
begin
  if (Value = nil) then
    Result := 'NULL'
  else
    Result := Value;
end;

initialization
  sqlite3_initialize; // so sqlite3.c is compiled with SQLITE_OMIT_AUTOINIT defined

finalization
  sqlite3_shutdown;

end.

