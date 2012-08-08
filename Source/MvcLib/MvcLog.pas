unit MvcLog;

interface

uses SysUtils, MvcCommon, DateUtils, Windows, StrUtils, Classes;

type
  TSessionIdEvent = procedure(var ASessionId: Int64) of object;

  TLog = class
  private
    class var FOnSessionId: TSessionIdEvent;
    class var FInstance: TLog;
    class var monitor: String;
    class var FlastError: String;
    class var logEnabledTime: TDateTime;
    class var previousLogDirectory: String;
    class var enableDebugLog: Boolean;
    class var enableInfoLog: Boolean;
    class var enableWarningLog: Boolean;
    class var enableErrorLog: Boolean;
    class var enableSqlLog: Boolean;
    class var enableDevelopmentLog: Boolean;
    class var enableTraceListenerLog: Boolean;
    class var enableConsoleLog: Boolean;
    class var logToFile: Boolean;
    class procedure DisableLogSetting;
    class procedure EnableLogSettingFromConfigSettings;

  class var
    FloggingEnabled: Boolean;
    class property loggingEnabled: Boolean read FloggingEnabled;
    class procedure PrepareLogFolder;
    constructor Create;
    class function FormatLog(logType: String; ts: TDateTime; resultVal: String;
      msg: String): String;
    procedure EraseOldFiles;
    class function Instance: TLog;
    class function IsLogEnabledForCurrentExecutable: Boolean;
    class var AutoDisable: Boolean;
    class var LogFileName: String;
    class var IsFileSizeSpecified: Boolean;
    class var MaxFileSize: Int64;
    class var DisableAfterMins: Integer;
    class var TraceFilePath: String;

  public
    class property lastError: String read FlastError;
    class procedure Debug(logMsg: String); overload;
    class procedure Debug(logMsg: String; ex: Exception); overload;
    class procedure Information(logMsg: String);
    class procedure Warning(logMsg: String); overload;
    class procedure Warning(logMsg: String; ex: Exception); overload;
    class procedure Error(logMsg: String); overload;
    class procedure Error(logMsg: String; ex: Exception); overload;
    class procedure Error(ex: Exception); overload;
    class procedure Error(ex: TMvcModelState); overload;
    class procedure Error(logMsg: String; ex: TMvcModelState); overload;
    class procedure UnHandled(logMsg: String); overload;
    class procedure UnHandled(ex: TMvcModelState); overload;
    class procedure UnHandled(logMsg: String; ex: TMvcModelState); overload;
    class procedure UnHandled(logMsg: String; ex: Exception); overload;
    class procedure UnHandled(ex: Exception); overload;
    class procedure Fatal(logMsg: String); overload;
    class procedure Fatal(ex: TMvcModelState); overload;
    class procedure Fatal(logMsg: String; ex: TMvcModelState); overload;
    class procedure Fatal(logMsg: String; ex: Exception); overload;
    class procedure Fatal(ex: Exception); overload;
    class procedure ConfigError(logMsg: String); overload;
    class procedure ConfigError(logMsg: String; ex: Exception); overload;
    class function WriteWinEventError(AEntry: string; AServer: string = '';
      ASource: string = 'Logger'; AEventType: word = EVENTLOG_INFORMATION_TYPE;
      AEventId: word = 0; AEventCategory: word = 0): Boolean;
    class procedure SQL(SQL: String); overload;
    class procedure SQL(SQL: String; timeSpan: TDateTime); overload;
    class procedure Debugger(msg: String); overload;
    procedure WriteLog(logLevel: String; logMsg: String;
      ex: Exception); overload;
    procedure WriteLog(logLevel: String; logMsg: String); overload;
    procedure WriteSQLLog(logLevel: String; ts: TDateTime; &result: String;
      logMsg: String); overload;
    procedure WriteFile(logLevel: String; logMsg: String); overload;
    procedure WriteToConsole(logMsg: String); overload;
    procedure WriteToDebugger(logMsg: String); overload;
    procedure ArchiveLog; overload;
    function GetNewLogFileName: string;
    class property OnSessionId: TSessionIdEvent read FOnSessionId
      write FOnSessionId;
  end;

implementation

var
  FLogMonitor: TObject;

const
  STRING_SQL: String = 'SQL';
  STRING_TRACE: String = 'TRACE';
  STRING_DEBUG: String = 'DEBUG';
  STRING_INFO: String = 'INFO';
  STRING_WARN: String = 'WARN';
  STRING_ERROR: String = 'ERROR';
  STRING_FATAL: String = 'FATAL';
  STRING_UNHANDLED: String = 'UNHANDELED';
  STRING_SYSTEM_INIT: String = 'INIT';
  STRING_SYSTEM_CLEANUP: String = 'CLEANUP';

constructor TLog.Create;
begin
  inherited Create;
end;

class function TLog.Instance: TLog;
var
  FSize: Int64;
  lastWriteTime: TDateTime;
begin
  if FInstance = nil then
  begin
    try
      MonitorEnter(FLogMonitor);
      if FInstance = nil then
      begin
        FInstance := TLog.Create;
        PrepareLogFolder();
        FInstance.WriteLog(STRING_SYSTEM_INIT, 'Log Started at : ' +
          DateTimeToStr(Now));
        if loggingEnabled then
          logEnabledTime := Now
      end
    finally
      MonitorExit(FLogMonitor);
    end;
  end;

  // should we archive?
  if loggingEnabled then
  begin
    if (loggingEnabled) and (logToFile) then
    begin
      PrepareLogFolder();
      if logToFile then
      begin
        FSize := 0;
        if IsFileSizeSpecified then
        begin
          try
            FSize := FileSize(LogFileName);
          except
            on exFileNotFound: Exception do
            begin
              LogFileName := EmptyStr;
              PrepareLogFolder();
              FInstance.WriteLog(STRING_SYSTEM_INIT, exFileNotFound.Message);
              if FileExists(LogFileName) then
              begin
                FSize := FileSize(LogFileName);
              end
            end;
          end
        end;
        lastWriteTime := FileLastWriteTime(LogFileName);
        MonitorEnter(FLogMonitor);
        begin
          if ((Today > lastWriteTime)) or
            ((((IsFileSizeSpecified = true)) and
            ((FSize > ((MaxFileSize * 1024 * 1000) - 1))))) then
          begin
            FInstance.ArchiveLog();
          end;
        end;
        MonitorExit(FLogMonitor);
      end
    end
  end;

  Exit(FInstance);
end;

class function TLog.IsLogEnabledForCurrentExecutable: Boolean;
begin

end;

class procedure TLog.DisableLogSetting;
begin
  enableDebugLog := false;
  enableInfoLog := false;
  enableWarningLog := false;
  enableErrorLog := false;
  enableSqlLog := false;
  enableDevelopmentLog := false;
  enableTraceListenerLog := false;
  enableConsoleLog := false;
  logToFile := false;
  FloggingEnabled := false
end;

class procedure TLog.EnableLogSettingFromConfigSettings;
begin
  FloggingEnabled :=
    (((((((enableTraceListenerLog) or (enableDebugLog)) or (enableInfoLog)) or
    (enableWarningLog)) or (enableErrorLog)) or (enableSqlLog)) or
    (enableDevelopmentLog)) or (enableConsoleLog)
end;

class procedure TLog.PrepareLogFolder;
var
  filename, dirName: String;

begin
  try
    filename := LogFileName;
    dirName := ExtractFilePath(filename);
    ForceDirectories(dirName);
  except
    on ex: Exception do
    begin
      // On file Creation error we will disable to log to file option
      TLog.ConfigError
        ('Disabling Log to file option because we are unable to create folder for new log location - '
        + LogFileName, ex);
      logToFile := false;
      logToFile := false
    end;
  end
end;

class procedure TLog.Debug(logMsg: String);
begin
  if enableDebugLog = true then
    Instance().WriteLog(STRING_DEBUG, logMsg)
end;

class procedure TLog.Debug(logMsg: String; ex: Exception);
begin
  if enableDebugLog = true then
    Instance().WriteLog(STRING_DEBUG, logMsg, ex)
end;

class procedure TLog.Information(logMsg: String);
begin
  if enableInfoLog = true then
    Instance().WriteLog(STRING_INFO, logMsg)
end;

class procedure TLog.Warning(logMsg: String);
begin
  if enableWarningLog = true then
    Instance().WriteLog(STRING_WARN, logMsg)
end;

class procedure TLog.Warning(logMsg: String; ex: Exception);
begin
  if enableWarningLog = true then
    Instance().WriteLog(STRING_WARN, logMsg, ex)
end;

class procedure TLog.Error(logMsg: String);
begin
  if enableErrorLog = true then
    Instance().WriteLog(STRING_ERROR, logMsg);
  FlastError := logMsg
end;

class procedure TLog.Error(logMsg: String; ex: Exception);
begin
  if enableErrorLog = true then
    Instance().WriteLog(STRING_ERROR, logMsg, ex);
  FlastError := logMsg
end;

class procedure TLog.Error(ex: Exception);
begin
  if enableErrorLog = true then
    Instance().WriteLog(STRING_ERROR, '', ex);
  FlastError := ex.Message
end;

class procedure TLog.Error(ex: TMvcModelState);
begin
  if ((enableErrorLog = true)) and ((ex <> nil)) then
    Instance().WriteLog(STRING_ERROR, ex.ToString());
  if ex <> nil then
    FlastError := ''; // ex.ToString()
end;

class procedure TLog.Error(logMsg: String; ex: TMvcModelState);
begin
  if ((enableErrorLog = true)) and ((ex <> nil)) then
    Instance().WriteLog(STRING_ERROR, logMsg + ' ' + ex.ToString())
  else
    Instance().WriteLog(STRING_ERROR, logMsg);
  if ex <> nil then
    FlastError := ''; // ex.ToString()
end;

class procedure TLog.UnHandled(logMsg: String);
begin
  WriteWinEventError(logMsg);
  Instance().WriteLog(STRING_UNHANDLED, logMsg);
  FlastError := logMsg;
end;

class procedure TLog.UnHandled(ex: TMvcModelState);
begin
  if ex <> nil then
  begin
    // WriteWinEventError(ex.ToString());
    // Instance().WriteLog(STRING_UNHANDLED, ex.ToString());
    // lastError := ex.ToString()
  end
end;

class procedure TLog.UnHandled(logMsg: String; ex: TMvcModelState);
begin
  if ex <> nil then
  begin
    // WriteWinEventError(logMsg + ' ' + ex.ToString());
    // Instance().WriteLog(STRING_UNHANDLED, logMsg + ' ' + ex.ToString());
    // lastError := logMsg + ' ' + ex.ToString()
  end
  else
  begin
    WriteWinEventError(logMsg);
    Instance().WriteLog(STRING_UNHANDLED, logMsg);
    FlastError := logMsg
  end
end;

class procedure TLog.UnHandled(logMsg: String; ex: Exception);
begin
  // WriteWinEventError(logMsg + ' ' + ExceptionUtils.ExceptionUtils.
  // FormattedExceptionMessage(ex));
  Instance().WriteLog(STRING_UNHANDLED, logMsg, ex);
  FlastError := logMsg
end;

class procedure TLog.UnHandled(ex: Exception);
begin
  if ex <> nil then
  begin
    // WriteWinEventError('ExceptionUtils.ExceptionUtils.FormattedExceptionMessage(ex));
    Instance().WriteLog(STRING_UNHANDLED, '', ex);
    FlastError := ex.Message
  end
end;

class procedure TLog.Fatal(logMsg: String);
begin
  WriteWinEventError(logMsg);
  Instance().WriteLog(STRING_FATAL, logMsg);
  FlastError := logMsg
end;

class procedure TLog.Fatal(ex: TMvcModelState);
begin
  if ex <> nil then
  begin
    // WriteWinEventError(ex.ToString());
    // Instance().WriteLog(STRING_FATAL, ex.ToString());
    // lastError := ex.ToString()
  end
end;

class procedure TLog.Fatal(logMsg: String; ex: TMvcModelState);
begin
  if ex <> nil then
  begin
    // WriteWinEventError(logMsg + ' ' + ex.ToString());
    // Instance().WriteLog(STRING_FATAL, logMsg + ' ' + ex.ToString());
    // flastError := logMsg + ' ' + ex.ToString()
  end
  else
  begin
    WriteWinEventError(logMsg);
    Instance().WriteLog(STRING_FATAL, logMsg);
    FlastError := logMsg
  end
end;

class procedure TLog.Fatal(logMsg: String; ex: Exception);
begin
  // WriteWinEventError(logMsg + ' ' + ExceptionUtils.ExceptionUtils.
  // FormattedExceptionMessage(ex));
  // Instance().WriteLog(STRING_FATAL, logMsg, ex);
  FlastError := logMsg
end;

class procedure TLog.Fatal(ex: Exception);
begin
  if ex <> nil then
  begin
    // WriteWinEventError(
    // ExceptionUtils.ExceptionUtils.FormattedExceptionMessage(ex));
    Instance().WriteLog(STRING_FATAL, '', ex);
    FlastError := ex.Message
  end
end;

class procedure TLog.ConfigError(logMsg: String);
begin
  WriteWinEventError(logMsg);
  OutputDebugString(PChar(logMsg));
end;

class procedure TLog.ConfigError(logMsg: String; ex: Exception);
var
  entry: String;
begin
  // entry:=logMsg + ExceptionUtils.ExceptionUtils.FormattedExceptionMessage(ex);
  WriteWinEventError(entry);
  OutputDebugString(PChar(entry));
end;

class function TLog.WriteWinEventError(AEntry: string; AServer: string = '';
  ASource: string = 'Logger'; AEventType: word = EVENTLOG_INFORMATION_TYPE;
  AEventId: word = 0; AEventCategory: word = 0): Boolean;
var
  EventLog: Integer;
  P: Pointer;
begin
  Result := false;
  P := PWideChar(AEntry);
  if Length(AServer) = 0 then // Write to the local machine
    EventLog := RegisterEventSource(nil, PWideChar(ASource))
  else // Write to a remote machine
    EventLog := RegisterEventSource(PWideChar(AServer), PWideChar(ASource));
  if EventLog <> 0 then
    try
      ReportEvent(EventLog, // event log handle
        AEventType, // event type
        AEventCategory, // category zero
        AEventId, // event identifier
        nil, // no user security identifier
        1, // one substitution string
        0, // no data
        @P, // pointer to string array
        nil); // pointer to data
      Result := true;
    finally
      DeregisterEventSource(EventLog);
    end;
end;

class procedure TLog.SQL(SQL: String);
begin
  {
    if enableSqlLog then
    begin
    Instance().WriteSQLLog(STRING_SQL, timeSpan.MinValue, '', SQL)
    end
  }
end;

class procedure TLog.SQL(SQL: String; timeSpan: TDateTime);
begin
  {
    if enableSqlLog then
    begin
    Instance().WriteSQLLog(STRING_SQL, timeSpan, '', SQL)
    end
  }
end;

class procedure TLog.Debugger(msg: String);
begin
  if enableDevelopmentLog then
  begin
    OutputDebugString(PChar(FormatLog('DEBUGGER', 0, '', msg)))
  end
end;

procedure TLog.WriteLog(logLevel: String; logMsg: String; ex: Exception);
begin
  if (not loggingEnabled) then
    Exit;

  // WriteLog(logLevel, logMsg + ExceptionUtils.ExceptionUtils.
  // FormattedExceptionMessage(ex))
end;

procedure TLog.WriteLog(logLevel: String; logMsg: String);
begin
  if (not loggingEnabled) then
    Exit;

  // if ((((Config.EnableStringFilter)) and ((logMsg.IndexOf(Config.StringFilter)
  // <> -1)))) or ((Config.EnableStringFilter = false)) then
  // WriteFile(logLevel, FormatLog(logLevel, 0, '',
  // StringUtil.FlattenString(logMsg)))
end;

procedure TLog.WriteSQLLog(logLevel: String; ts: TDateTime; &result: String;
  logMsg: String);
begin
  if (not loggingEnabled) then
    Exit;
  {
    if ((((Config.EnableSqlFilterTime)) and ((ts > Config.SqlFilterTime)))) or
    ((Config.EnableSqlFilterTime = false)) then
    WriteFile(logLevel, FormatLog(logLevel, ts, result,
    StringUtil.FlattenString(logMsg)))
  }
end;

procedure TLog.WriteFile(logLevel: String; logMsg: String);
var
  errMsg: String;
begin
  if (not loggingEnabled) then
    Exit;

  if logToFile then
  begin
    MonitorEnter(FLogMonitor);
    begin
      try
        // sw := new StreamWriter(Config.LogFileName, true);
        // sw.WriteLine(logMsg);
        // sw.Close()
      except
        on ex: Exception do
        begin
          errMsg := 'Couldn''t write to Log File :' + LogFileName;
          WriteToConsole(errMsg);
          // On file Creation error we will disable to log to file option
          TLog.ConfigError
            ('Disabling Log to file option because we are unable to write to the log - '
            + LogFileName, ex);
          logToFile := false;
        end;
      end;
    end;
    MonitorExit(FLogMonitor);
  end;
  // Write to console
  WriteToConsole(logMsg);
  // Write to Debugger
  WriteToDebugger(logMsg);
end;

procedure TLog.WriteToConsole(logMsg: String);
begin
  if enableConsoleLog then
    WriteLn(logMsg)
end;

function TLog.GetNewLogFileName: string;
begin

end;

procedure TLog.WriteToDebugger(logMsg: String);
begin
  if enableDevelopmentLog then
    OutputDebugString(PChar(logMsg))
end;

procedure TLog.ArchiveLog;
var
  newLogfile: String;
begin
  if FileExists(LogFileName) then
  begin
    WriteLog(STRING_SYSTEM_CLEANUP, 'Log Started at : ' + DateTimeToStr(Now))
  end;
  EraseOldFiles();
  // Switch to new file name. The old file get archived anyway.
  newLogfile := GetNewLogFileName();
  if FileExists(LogFileName) then
  begin
    WriteLog(STRING_SYSTEM_CLEANUP, 'Switching to new log file : ' + newLogfile)
  end;
  LogFileName := newLogfile;
  WriteLog(STRING_SYSTEM_INIT, 'Log Started at : ' + DateTimeToStr(Now));
end;

class function TLog.FormatLog(logType: String; ts: TDateTime; resultVal: String;
  msg: String): String;
var
  SessionId: Int64;
begin
  if Assigned(FOnSessionId) then
    FOnSessionId(SessionId);
  Exit(IntToStr(SessionId) + #9 + IntToStr(GetCurrentProcessId) + #9 +
    IntToStr(GetCurrentThreadId) + #9 + logType + #9 +
    FormatDateTime('MM/dd/yy HH:mm:ss', Now) + #9 + IfThen(ts = 0,
    FormatFloat('#,##0.00', (DateTimeToMilliseconds(ts) / 1000)), '') + #9 +
    '[ ' + resultVal + ' ]' + #9 + msg)
end;

procedure TLog.EraseOldFiles;
begin

end;

procedure WriteToFile(AFileName: string; AMsg: string);
var
  F: TFileStream;
  WrkHandle: Integer;
begin
  try
    WrkHandle := FileOpen(AFileName, fmOpenReadWrite OR fmShareDenyWrite or
      fmCreate);
    if WrkHandle < 0 then
      raise EFCreateError.CreateFmt('Cannot create file %s', [AFileName]);
    F := TFileStream.Create(WrkHandle);
  except
    on EFCreateError do
    begin
      Exit;
    end;
    else;
  end;

  try
    try
      F.WriteBuffer(PChar(AMsg)^, Length(AMsg));
    except
      on EInOutError do
      begin
      end;
      else;
    end;
  finally
    FreeAndNil(F);
  end;
end;

initialization

FLogMonitor := TObject.Create;

finalization

FLogMonitor.Destroy;

end.
