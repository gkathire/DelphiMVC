{
This file is part of DelphiMvcWeb project.
Created By : Guru Kathiresan.
License : MPL - http://www.mozilla.org/MPL/MPL-1.1.html

Orinal Author: Wanderlan Santos dos Anjos (wanderlan.anjos@gmail.com)
Date: apr-2008
License: BSD<extlink http://www.opensource.org/licenses/bsd-license.php>BSD</extlink>
}

unit MvcWebUtils;

{$IFDEF FPC}{$MACRO ON}{$MODE DELPHI}{$ENDIF}

interface

uses
  Classes, Generics.Collections,TypInfo, Rtti,
  {$IF CompilerVersion > 22.0}Xml.XMLDoc,{$ELSE}XMLDoc,{$IFEND}
  superobject,{$IF CompilerVersion > 22.0}Winapi.Windows{$ELSE}Windows{$IFEND};

const
  MvcWebVersion = '0.1';

type
  TMvcStringObjectDictionary = class(TDictionary<string, TValue>)
  private
    function GetItemEx(const AKey: String): TValue;
    procedure SetItemEx(const AKey: String; AValue: TValue);
  public
    property Items[const Key: string]: TValue read GetItemEx
      write SetItemEx; default;
    destructor Destroy;override;
  end;

type
  TBrowser         = (brUnknown, brIE, brFirefox, brChrome, brSafari, brOpera, brKonqueror, brMobileSafari); // Internet Browsers
  TCSSUnit         = (cssPX, cssPerc, cssEM, cssEX, cssIN, cssCM, cssMM, cssPT, cssPC, cssnone); // HTML CSS units
  TExtProcedure    = procedure of object; // Defines a procedure than can be called by a <link TExtObject.Ajax, AJAX> request
  TUploadBlockType = (ubtUnknown, ubtBegin, ubtMiddle, ubtEnd);
  {$IFDEF DELPHI}
  PtrInt = integer;
  {$ENDIF}
  TMvcWebUtils = class
    class procedure StrToTStrings(const S : string; List : TStrings);
    class function URLDecode(const Encoded : string): string;
    class function URLEncode(const Decoded : string): string;
    {
    Determine browser from HTTP_USER_AGENT header string.
    @param UserAgentStr String returned by, for example, RequestHeader['HTTP_USER_AGENT'].
    @return TBrowser
    }
    class function DetermineBrowser(const UserAgentStr : string) : TBrowser;

    {
    Mimics preg_match php function. Searches S for a match to delimiter strings given in Delims parameter
    @param Delims Delimiter strings to match
    @param S Subject string
    @param Matches Substrings from Subject string delimited by Delimiter strings. <b>Matches (TStringList) should already be created</b>.
    @param Remove matches strings from S, default is true
    @return True if some match hit, false otherwise
    }
    class function Extract(const Delims : array of string; var S : string; var Matches : TStringList; Remove : boolean = true) : boolean;

    {
    Mimics explode php function.
    Creates a TStringList where each string is a substring formed by the splitting of S string through delimiter Delim.
    @param Delim Delimiter used to split the string
    @param S Source string to split
    @return TStringList created with substrings from S
    }
    class function Explode(Delim : char; const S : string; Separator : char = '=') : TStringList;

    {
    The opposite of LastDelimiter RTL function.
    Returns the index of the first occurence in a string of the characters specified.
    If none of the characters in Delimiters appears in string S, function returns zero.
    @param Delimiters String where each character is a valid delimiter.
    @param S String to search for delimiters.
    @param Offset Index from where the search begins.
    }
    class function FirstDelimiter(const Delimiters, S : string; Offset : integer = 1) : integer;

    // The opposite of "StrUtils.PosEx" function. Returns the index value of the last occurrence of a specified substring in a given string.
    class function RPosEx(const Substr, Str : string; Offset : integer = 1) : integer;

    {
    Returns the number of occurrences of Substr in Str until UntilStr occurs
    @param Substr String to count in Str
    @param Str String where the counting will be done
    @param UntilStr Optional String, stop counting if this string occurs
    }
    class function CountStr(const Substr, Str : string; UntilStr : string = '') : integer;

    {
    Converts a string with param place holders to a JavaScript string. Converts a string representing a regular expression to a JavaScript RegExp.
    Replaces " to \", ^M^J to <br/> and isolated ^M or ^J to <br/>, surrounds the string with " and insert %0..%9 JS place holders.
    When setting a TExtFormTextField value (in property setter setvalue), the UseBR should be set to false,
    because otherwise it is impossible to display multiline text in a TExtFormTextArea.
    @param S Source string with param place holders or RegExpr
    @param UseBR If true uses replace ^M^J to <br/> else to \n
    @return a well formatted JS string
    }
    class function StrToJS(const S : string; UseBR : boolean = false) : string;

    {
    Finds S string in Cases array, returning its index or -1 if not found. Good to use in Pascal "case" command. Similar to AnsiIndexText.
    @param S Source string where to search
    @param Cases String array to find in S
    }
    class function CaseOf(const S : string; const Cases : array of string) : integer;

    {
    Finds Cases array in S string, returning its index or -1 if not found. Good to use in Pascal "case" command. Reverse to AnsiIndexStr.
    @param S string to find in Cases array
    @param Cases String array where to search
    }
    class function RCaseOf(const S : string; const Cases : array of string) : integer;

    {
    Converts a Pascal enumerated type constant into a JS string, used internally by ExtToPascal wrapper. See ExtFixes.txt for more information.
    @param TypeInfo Type information record that describes the enumerated type, use TypeInfo() function with enumerated type
    @param Value The enumerated value, represented as an integer
    @return JS string
    }
    class function EnumToJSString(TypeInfo : PTypeInfo; Value : integer) : string;

    {
    Helper function to make code more pascalish, use
    @example <code>BodyStyle := SetPaddings(10, 15);</code>
    instead
    @example <code>BodyStyle := 'padding:10px 15px';</code>
    }
    class function SetPaddings(Top : integer; Right : integer = 0; Bottom : integer = -1; Left : integer = 0; CSSUnit : TCSSUnit = cssPX;
      Header : boolean = true) : string;

    {
    Helper function to make code more pascalish, use
    @example <code>Margins := SetMargins(3, 3, 3);</code>
    instead
    @example <code>Margins := '3 3 3 0';</code>
    }
    class function SetMargins(Top : integer; Right : integer = 0; Bottom : integer = 0; Left : integer = 0; CSSUnit : TCSSUnit = cssNone;
      Header : boolean = false) : string;

    // Returns true if BeforesS string occurs before AfterS string in S string
    class function Before(const BeforeS, AfterS, S : string) : boolean;

    // Returns true if all chars in S are uppercase
    class function IsUpperCase(S : string) : boolean;

    // Beautify generated JS commands from ExtPascal, automatically used when DEBUGJS symbol is defined
    class function BeautifyJS(const AScript : string; const StartingLevel : integer = 0; SplitHTMLNewLine : boolean = true) : string;

    // Beautify generated CSS from ExtPascal, automatically used when DEBUGJS symbol is defined
    class function BeautifyCSS(const AStyle : string) : string;

    // Screen space, in characters, used for a field using regular expression mask
    class function LengthRegExp(Rex : string; CountAll : Boolean = true) : integer;

    class function JSDateToDateTime(JSDate : string) : TDateTime;

    class function IsNumber(S : string) : boolean;

    {
    Encrypts a string using a simple and quick method, but not trivial.
    @param Value String to be encrypted.
    @return String encrypted.
    }
    class function Encrypt(Value : string) : string;

    {
    Decrypts a string that was previously crypted using the function <link Encrypt>.
    @param Value String to be decrypted.
    @return String decrypted.
    }
    class function Decrypt(Value : string) : string;

    class function DownloadContentType(const FileName :string; Default: string='text/html'): AnsiString;
    class function HTTPInterprete(src: PSOChar; named: boolean = false; sep: SOChar = ';'; StrictSep: boolean = false; codepage: Integer = 0): ISuperObject;

    class function XMLType:string;
    class function JsonType:string;
    class function TextType:string;
    class function HtmlType:string;
    class function CssType:string;
    class function JsType:string;

  end;




implementation

uses
  StrUtils, SysUtils, Math, DateUtils;

const
  CMIMEExtensions:
    array [1 .. 177] of record
    Ext: string;
    MimeType:AnsiString;
  end
 = ((Ext: '.gif'; MimeType: 'image/gif'), (Ext: '.jpg'; MimeType: 'image/jpeg'),
  (Ext: '.jpeg'; MimeType: 'image/jpeg'), (Ext: '.html'; MimeType: 'text/html'),
  (Ext: '.htm'; MimeType: 'text/html'), (Ext: '.css'; MimeType: 'text/css'),
  (Ext: '.js'; MimeType: 'text/javascript'), (Ext: '.txt';
  MimeType: 'text/plain'), (Ext: '.xls'; MimeType: 'application/excel'),
  (Ext: '.rtf'; MimeType: 'text/richtext'), (Ext: '.wq1';
  MimeType: 'application/x-lotus'), (Ext: '.wk1';
  MimeType: 'application/x-lotus'), (Ext: '.raf'; MimeType: 'application/raf'),
  (Ext: '.png'; MimeType: 'image/x-png'), (Ext: '.c'; MimeType: 'text/plain'),
  (Ext: '.c++'; MimeType: 'text/plain'), (Ext: '.pl'; MimeType: 'text/plain'),
  (Ext: '.cc'; MimeType: 'text/plain'), (Ext: '.h'; MimeType: 'text/plain'),
  (Ext: '.talk'; MimeType: 'text/x-speech'), (Ext: '.xbm';
  MimeType: 'image/x-xbitmap'), (Ext: '.xpm'; MimeType: 'image/x-xpixmap'),
  (Ext: '.ief'; MimeType: 'image/ief'), (Ext: '.jpe'; MimeType: 'image/jpeg'),
  (Ext: '.tiff'; MimeType: 'image/tiff'), (Ext: '.tif'; MimeType: 'image/tiff'),
  (Ext: '.rgb'; MimeType: 'image/rgb'), (Ext: '.g3f'; MimeType: 'image/g3fax'),
  (Ext: '.xwd'; MimeType: 'image/x-xwindowdump'), (Ext: '.pict';
  MimeType: 'image/x-pict'), (Ext: '.ppm'; MimeType: 'image/x-portable-pixmap'),
  (Ext: '.pgm'; MimeType: 'image/x-portable-graymap'), (Ext: '.pbm';
  MimeType: 'image/x-portable-bitmap'), (Ext: '.pnm';
  MimeType: 'image/x-portable-anymap'), (Ext: '.bmp';
  MimeType: 'image/x-ms-bmp'), (Ext: '.ras'; MimeType: 'image/x-cmu-raster'),
  (Ext: '.pcd'; MimeType: 'image/x-photo-cd'), (Ext: '.cgm';
  MimeType: 'image/cgm'), (Ext: '.mil'; MimeType: 'image/x-cals'), (Ext: '.cal';
  MimeType: 'image/x-cals'), (Ext: '.fif'; MimeType: 'image/fif'), (Ext: '.dsf';
  MimeType: 'image/x-mgx-dsf'), (Ext: '.cmx'; MimeType: 'image/x-cmx'),
  (Ext: '.wi'; MimeType: 'image/wavelet'), (Ext: '.dwg';
  MimeType: 'image/vnd.dwg'), (Ext: '.dxf'; MimeType: 'image/vnd.dxf'),
  (Ext: '.svf'; MimeType: 'image/vnd.svf'), (Ext: '.au';
  MimeType: 'audio/basic'), (Ext: '.snd'; MimeType: 'audio/basic'),
  (Ext: '.aif'; MimeType: 'audio/x-aiff'), (Ext: '.aiff';
  MimeType: 'audio/x-aiff'), (Ext: '.aifc'; MimeType: 'audio/x-aiff'),
  (Ext: '.wav'; MimeType: 'audio/x-wav'), (Ext: '.mpa';
  MimeType: 'audio/x-mpeg'), (Ext: '.abs'; MimeType: 'audio/x-mpeg'),
  (Ext: '.mpega'; MimeType: 'audio/x-mpeg'), (Ext: '.mp2a';
  MimeType: 'audio/x-mpeg-2'), (Ext: '.mpa2'; MimeType: 'audio/x-mpeg-2'),
  (Ext: '.es'; MimeType: 'audio/echospeech'), (Ext: '.vox';
  MimeType: 'audio/voxware'), (Ext: '.lcc'; MimeType: 'application/fastman'),
  (Ext: '.ra'; MimeType: 'application/x-pn-realaudio'), (Ext: '.ram';
  MimeType: 'application/x-pn-realaudio'), (Ext: '.mmid';
  MimeType: 'x-music/x-midi'), (Ext: '.skp'; MimeType: 'application/vnd.koan'),
  (Ext: '.talk'; MimeType: 'text/x-speech'), (Ext: '.mpeg';
  MimeType: 'video/mpeg'), (Ext: '.mpg'; MimeType: 'video/mpeg'), (Ext: '.mpe';
  MimeType: 'video/mpeg'), (Ext: '.mpv2'; MimeType: 'video/mpeg-2'),
  (Ext: '.mp2v'; MimeType: 'video/mpeg-2'), (Ext: '.qt';
  MimeType: 'video/quicktime'), (Ext: '.mov'; MimeType: 'video/quicktime'),
  (Ext: '.avi'; MimeType: 'video/x-msvideo'), (Ext: '.movie';
  MimeType: 'video/x-sgi-movie'), (Ext: '.vdo'; MimeType: 'video/vdo'),
  (Ext: '.viv'; MimeType: 'video/vnd.vivo'), (Ext: '.pac';
  MimeType: 'application/x-ns-proxy-autoconfig'), (Ext: '.ai';
  MimeType: 'application/postscript'), (Ext: '.eps';
  MimeType: 'application/postscript'), (Ext: '.ps';
  MimeType: 'application/postscript'), (Ext: '.rtf';
  MimeType: 'application/rtf'), (Ext: '.pdf'; MimeType: 'application/pdf'),
  (Ext: '.mif'; MimeType: 'application/vnd.mif'), (Ext: '.t';
  MimeType: 'application/x-troff'), (Ext: '.tr';
  MimeType: 'application/x-troff'), (Ext: '.roff';
  MimeType: 'application/x-troff'), (Ext: '.man';
  MimeType: 'application/x-troff-man'), (Ext: '.me';
  MimeType: 'application/x-troff-me'), (Ext: '.ms';
  MimeType: 'application/x-troff-ms'), (Ext: '.latex';
  MimeType: 'application/x-latex'), (Ext: '.tex';
  MimeType: 'application/x-tex'), (Ext: '.texinfo';
  MimeType: 'application/x-texinfo'), (Ext: '.texi';
  MimeType: 'application/x-texinfo'), (Ext: '.dvi';
  MimeType: 'application/x-dvi'), (Ext: '.doc'; MimeType: 'application/msword'),
  (Ext: '.oda'; MimeType: 'application/oda'), (Ext: '.evy';
  MimeType: 'application/envoy'), (Ext: '.gtar';
  MimeType: 'application/x-gtar'), (Ext: '.tar'; MimeType: 'application/x-tar'),
  (Ext: '.ustar'; MimeType: 'application/x-ustar'), (Ext: '.bcpio';
  MimeType: 'application/x-bcpio'), (Ext: '.cpio';
  MimeType: 'application/x-cpio'), (Ext: '.shar';
  MimeType: 'application/x-shar'), (Ext: '.zip'; MimeType: 'application/zip'),
  (Ext: '.hqx'; MimeType: 'application/mac-binhex40'), (Ext: '.sit';
  MimeType: 'application/x-stuffit'), (Ext: '.sea';
  MimeType: 'application/x-stuffit'), (Ext: '.fif';
  MimeType: 'application/fractals'), (Ext: '.bin';
  MimeType: 'application/octet-stream'), (Ext: '.uu';
  MimeType: 'application/octet-stream'), (Ext: '.exe';
  MimeType: 'application/octet-stream'), (Ext: '.src';
  MimeType: 'application/x-wais-source'), (Ext: '.wsrc';
  MimeType: 'application/x-wais-source'), (Ext: '.hdf';
  MimeType: 'application/hdf'), (Ext: '.ls'; MimeType: 'text/javascript'),
  (Ext: '.mocha'; MimeType: 'text/javascript'), (Ext: '.vbs';
  MimeType: 'text/vbscript'), (Ext: '.sh'; MimeType: 'application/x-sh'),
  (Ext: '.csh'; MimeType: 'application/x-csh'), (Ext: '.pl';
  MimeType: 'application/x-perl'), (Ext: '.tcl'; MimeType: 'application/x-tcl'),
  (Ext: '.spl'; MimeType: 'application/futuresplash'), (Ext: '.mbd';
  MimeType: 'application/mbedlet'), (Ext: '.swf';
  MimeType: 'application/x-director'), (Ext: '.pps';
  MimeType: 'application/mspowerpoint'), (Ext: '.asp';
  MimeType: 'application/x-asap'), (Ext: '.asn';
  MimeType: 'application/astound'), (Ext: '.axs';
  MimeType: 'application/x-olescript'), (Ext: '.ods';
  MimeType: 'application/x-oleobject'), (Ext: '.opp';
  MimeType: 'x-form/x-openscape'), (Ext: '.wba';
  MimeType: 'application/x-webbasic'), (Ext: '.frm';
  MimeType: 'application/x-alpha-form'), (Ext: '.wfx';
  MimeType: 'x-script/x-wfxclient'), (Ext: '.pcn';
  MimeType: 'application/x-pcn'), (Ext: '.ppt';
  MimeType: 'application/vnd.ms-powerpoint'), (Ext: '.svd';
  MimeType: 'application/vnd.svd'), (Ext: '.ins';
  MimeType: 'application/x-net-install'), (Ext: '.ccv';
  MimeType: 'application/ccv'), (Ext: '.vts'; MimeType: 'workbook/formulaone'),
  (Ext: '.wrl'; MimeType: 'x-world/x-vrml'), (Ext: '.vrml';
  MimeType: 'x-world/x-vrml'), (Ext: '.vrw'; MimeType: 'x-world/x-vream'),
  (Ext: '.p3d'; MimeType: 'application/x-p3d'), (Ext: '.svr';
  MimeType: 'x-world/x-svr'), (Ext: '.wvr'; MimeType: 'x-world/x-wvr'),
  (Ext: '.3dmf'; MimeType: 'x-world/x-3dmf'), (Ext: '.ma';
  MimeType: 'application/mathematica'), (Ext: '.msh';
  MimeType: 'x-model/x-mesh'), (Ext: '.v5d'; MimeType: 'application/vis5d'),
  (Ext: '.igs'; MimeType: 'application/iges'), (Ext: '.dwf';
  MimeType: 'drawing/x-dwf'), (Ext: '.showcase';
  MimeType: 'application/x-showcase'), (Ext: '.slides';
  MimeType: 'application/x-showcase'), (Ext: '.sc';
  MimeType: 'application/x-showcase'), (Ext: '.sho';
  MimeType: 'application/x-showcase'), (Ext: '.show';
  MimeType: 'application/x-showcase'), (Ext: '.ins';
  MimeType: 'application/x-insight'), (Ext: '.insight';
  MimeType: 'application/x-insight'), (Ext: '.ano';
  MimeType: 'application/x-annotator'), (Ext: '.dir';
  MimeType: 'application/x-dirview'), (Ext: '.lic';
  MimeType: 'application/x-enterlicense'), (Ext: '.faxmgr';
  MimeType: 'application/x-fax-manager'), (Ext: '.faxmgrjob';
  MimeType: 'application/x-fax-manager-job'), (Ext: '.icnbk';
  MimeType: 'application/x-iconbook'), (Ext: '.wb';
  MimeType: 'application/x-inpview'), (Ext: '.inst';
  MimeType: 'application/x-install'), (Ext: '.mail';
  MimeType: 'application/x-mailfolder'), (Ext: '.pp';
  MimeType: 'application/x-ppages'), (Ext: '.ppages';
  MimeType: 'application/x-ppages'), (Ext: '.sgi-lpr';
  MimeType: 'application/x-sgi-lpr'), (Ext: '.tardist';
  MimeType: 'application/x-tardist'), (Ext: '.ztardist';
  MimeType: 'application/x-ztardist'), (Ext: '.wkz';
  MimeType: 'application/x-wingz'), (Ext: '.xml'; MimeType: 'application/xml'),
 (Ext: '.iv'; MimeType: 'graphics/x-inventor'),
 (Ext: '.json'; MimeType: 'application/json')
  );



destructor TMvcStringObjectDictionary.Destroy;
begin
  self.Clear;
end;

function TMvcStringObjectDictionary.GetItemEx(const AKey: String): TValue;
begin
  if (self.TryGetValue(AKey, result) = false) then
    Add(AKey, nil);
end;

procedure TMvcStringObjectDictionary.SetItemEx(const AKey: String; AValue: TValue);
begin
  self.AddOrSetValue(AKey, AValue);
end;


class function TMvcWebUtils.DetermineBrowser(const UserAgentStr : string) : TBrowser; begin
  Result := TBrowser(RCaseOf(UserAgentStr, ['MSIE', 'Firefox', 'Chrome', 'Safari', 'Opera', 'Konqueror'])+1);
  // Note string order must match order in TBrowser enumeration above
  if (Result = brSafari) and // Which Safari?
     (Pos('Mobile', UserAgentStr) > 0) and
     (Pos('Apple', UserAgentStr) > 0) then
    Result := brMobileSafari
end;

class function TMvcWebUtils.Extract(const Delims : array of string; var S : string; var Matches : TStringList; Remove : boolean = true) : boolean;
var
  I, J : integer;
  Points : array of integer;
begin
  Result := false;
  if Matches <> nil then Matches.Clear;
  SetLength(Points, length(Delims));
  J := 1;
  for I := 0 to high(Delims) do begin
    J := PosEx(Delims[I], S, J);
    Points[I] := J;
    if J = 0 then
      exit
    else
      inc(J, length(Delims[I]));
  end;
  for I := 0 to high(Delims)-1 do begin
    J := Points[I] + length(Delims[I]);
    Matches.Add(trim(copy(S, J, Points[I+1]-J)));
  end;
  if Remove then S := copy(S, Points[high(Delims)] + length(Delims[high(Delims)]), length(S));
  Result := true
end;

class function TMvcWebUtils.Explode(Delim : char; const S : string; Separator : char = '=') : TStringList;
var
  I : integer;
begin
  Result := TStringList.Create;
  Result.StrictDelimiter := true;
  Result.Delimiter := Delim;
  Result.DelimitedText := S;
  Result.NameValueSeparator := Separator;
  for I := 0 to Result.Count-1 do Result[I] := trim(Result[I]);
end;

class function TMvcWebUtils.FirstDelimiter(const Delimiters, S : string; Offset : integer = 1) : integer;
var
  I : integer;
begin
  for Result := Offset to length(S) do
    for I := 1 to length(Delimiters) do
      if Delimiters[I] = S[Result] then exit;
  Result := 0;
end;

class function TMvcWebUtils.RPosEx(const Substr, Str : string; Offset : integer = 1) : integer;
var
  I : integer;
begin
  Result := PosEx(Substr, Str, Offset);
  while Result <> 0 do begin
    I := PosEx(Substr, Str, Result+1);
    if I = 0 then
      break
    else
      Result := I
  end;
end;

class function TMvcWebUtils.CountStr(const Substr, Str : string; UntilStr : string = '') : integer;
var
  I, J : integer;
begin
  I := 0;
  Result := 0;
  J := Pos(UntilStr, Str);
  repeat
    I := PosEx(Substr, Str, I+1);
    if (J <> 0) and (J < I) then exit;
    if I <> 0 then inc(Result);
  until I = 0;
end;

class function TMvcWebUtils.StrToJS(const S : string; UseBR : boolean = false) : string;
var
  I, J : integer;
  BR   : string;
begin
  BR := IfThen(UseBR, '<br/>', '\n');
  Result := AnsiReplaceStr(S, '"', '\"');
  Result := AnsiReplaceStr(Result, ^M^J, BR);
  Result := AnsiReplaceStr(Result, ^M, BR);
  Result := AnsiReplaceStr(Result, ^J, BR);
  if (Result <> '') and (Result[1] = #3) then begin // Is RegEx
    delete(Result, 1, 1);
    if Pos('/', Result) <> 1 then Result := '/' + Result + '/';
  end
  else begin
    I := pos('%', Result);
    if (pos(';', Result) = 0) and (I <> 0) and ((length(Result) > 1) and (I < length(Result)) and (Result[I+1] in ['0'..'9'])) then begin // Has param place holder, ";" disable place holder
      J := FirstDelimiter(' "''[]{}><=!*-+/,', Result, I+2);
      if J = 0 then J := length(Result)+1;
      if J <> (length(Result)+1) then begin
        insert('+"', Result, J);
        Result := Result + '"';
      end;
      if I <> 1 then begin
        insert('"+', Result, I);
        Result := '"' + Result;
      end;
    end
    else
      if (I = 1) and (length(Result) > 1) and (Result[2] in ['a'..'z', 'A'..'Z']) then
        Result := copy(Result, 2, length(Result))
      else
        Result := '"' + Result + '"'
  end;
end;

class function TMvcWebUtils.CaseOf(const S : string; const Cases : array of string) : integer; begin
  for Result := 0 to high(Cases) do
    if SameText(S, Cases[Result]) then exit;
  Result := -1;
end;

class function TMvcWebUtils.RCaseOf(const S : string; const Cases : array of string) : integer; begin
  for Result := 0 to high(Cases) do
    if pos(Cases[Result], S) <> 0 then exit;
  Result := -1;
end;

class function TMvcWebUtils.EnumToJSString(TypeInfo : PTypeInfo; Value : integer) : string;
var
  I : integer;
  JS: string;
begin
  Result := '';
  JS := GetEnumName(TypeInfo, Value);
  for I := 1 to length(JS) do
    if JS[I] in ['A'..'Z'] then begin
      Result := LowerCase(copy(JS, I, 100));
      if Result = 'perc' then Result := '%';
      exit
    end;
end;

class function TMvcWebUtils.SetPaddings(Top : integer; Right : integer = 0; Bottom : integer = -1; Left : integer = 0; CSSUnit : TCSSUnit = cssPX;
  Header : boolean = true) : string;
begin
  Result := Format('%s%d%3:s %2:d%3:s', [IfThen(Header, 'padding: ', ''), Top, Right, EnumToJSString(TypeInfo(TCSSUnit), ord(CSSUnit))]);
  if Bottom <> -1 then
    Result := Result + Format(' %d%2:s %1:d%2:s', [Bottom, Left, EnumToJSString(TypeInfo(TCSSUnit), ord(CSSUnit))]);
end;

class function TMvcWebUtils.SetMargins(Top : integer; Right : integer = 0; Bottom : integer = 0; Left : integer = 0; CSSUnit : TCSSUnit = cssNone;
  Header : boolean = false) : string;
begin
  Result := Format('%s%d%5:s %2:d%5:s %3:d%5:s %4:d%s', [IfThen(Header, 'margin: ', ''), Top, Right, Bottom, Left,
    EnumToJSString(TypeInfo(TCSSUnit), ord(CSSUnit))])
end;

class function TMvcWebUtils.Before(const BeforeS, AfterS, S : string) : boolean;
var
  I : integer;
begin
  I := pos(BeforeS, S);
  Result := (I <> 0) and (I < pos(AfterS, S))
end;

class function TMvcWebUtils.IsUpperCase(S : string) : boolean;
var
  I : integer;
begin
  Result := false;
  for I := 1 to length(S) do
    if S[I] in ['a'..'z'] then exit;
  Result := true;
end;

function SpaceIdents(const aLevel: integer; const aWidth: string = '  '): string;
var
  c: integer;
begin
  Result := '';
  if aLevel < 1 then Exit;
  for c := 1 to aLevel do Result := Result + aWidth;
end;

function MinValueOf(Values : array of integer; const MinValue : integer = 0) : integer;
var
  I : integer;
begin
  for I := 0 to High(Values) do
    if Values[I] <= MinValue then Values[I] := MAXINT;
  Result := MinIntValue(Values);
  // if all are the minimum value then return 0
  if Result = MAXINT then Result := MinValue;
end;

class function TMvcWebUtils.BeautifyJS(const AScript : string; const StartingLevel : integer = 0; SplitHTMLNewLine : boolean = true) : string;
var
  pBlockBegin, pBlockEnd, pPropBegin, pPropEnd, pStatEnd, {pFuncBegin,} pSqrBegin, pSqrEnd,
  pFunction, pString, pOpPlus, pOpMinus, pOpTime, {pOpDivide,} pOpEqual, pRegex : integer;
  P, Lvl : integer;
  Res : string;

  function AddNewLine(const atPos : integer; const AddText : string) : integer; begin
    insert(^J + AddText, Res, atPos);
    Result := length(^J + AddText);
  end;

  function SplitHTMLString(AStart, AEnd : integer): integer;  // range is including the quotes
  var
    br,pe,ps: integer;
    s: string;
  begin
    Result := AEnd;
    s := copy(res, AStart, AEnd);
    // find html new line (increase verbosity)
    br := PosEx('<br>', res, AStart+1);
    pe := PosEx('</p>', res, AStart+1);
    ps := MinValueOf([br,pe]);
    // html new line is found
    // Result-5 is to skip the mark at the end of the line
    while (ps > 0) and (ps < Result-5) do begin
      s := '"+'^J+SpaceIdents(Lvl)+SpaceIdents(3)+'"';
      Insert(s, res, ps+4);
      Result := Result + length(s);
      // find next new line
      br := PosEx('<br>', res, ps+length(s)+4);
      pe := PosEx('</p>', res, ps+length(s)+4);
      ps := MinValueOf([br,pe]);
    end;
  end;

var
  Backward, onReady, inProp, inNew : boolean;
  LvlProp, i, j, k : integer;
begin
  // skip empty script
  if AScript = '' then exit;
  P := 1;
  Res := AScript;
  inNew := true;
  inProp := false;
  onReady := false;
  LvlProp := 1000; // max identation depth
  Lvl := StartingLevel;
  // remove space in the beginning
  if Res[1] = ' ' then Delete(Res, 1, 1);
  // proceed the whole generated script by scanning the text
  while (p > 0) and (p < Length(Res)-1) do begin
    // chars that will be processed (10 signs)
    inc(P);
    pString     := PosEx('"', Res, P);
    pOpEqual    := PosEx('=', Res, P);
    pOpPlus     := PosEx('+', Res, P);
    pOpMinus    := PosEx('-', Res, P);
    pOpTime     := PosEx('*', Res, P);
    pBlockBegin := PosEx('{', Res, P);
    pBlockEnd   := PosEx('}', Res, P);
    pPropBegin  := PosEx(':', Res, P);
    pPropEnd    := PosEx(',', Res, P);
    pStatEnd    := PosEx(';', Res, P);
    pSqrBegin   := PosEx('[', Res, P);
    pSqrEnd     := PosEx(']', Res, P);
    pFunction   := PosEx('function', Res, P);
    pRegex      := PosEx('regex:', Res, P);
    // process what is found first
    P := MinValueOf([pBlockBegin, pBlockEnd, pPropBegin, pPropEnd, pStatEnd, {pFuncBegin,} pSqrBegin, pSqrEnd,
                     pString, pOpEqual, pOpPlus, pOpMinus, pOpTime, {pOpDivide,} pFunction, pRegex]);
    // keep Ext's onReady function at the first line
    if (not onReady) and (P > 0) and (length(Res) >= P) and (res[p] = 'f') then
      if Copy(Res, P-9, 9) = '.onReady(' then begin
        onReady := true;
        continue;
      end;
    // now, let's proceed with what char is found
    if P > 0 then begin
      // reset inProp status based on minimum lvlProp
      if inProp then inProp := Lvl >= LvlProp; // or (lvl > StartingLevel);
      // process chars
      case res[p] of // skip string by jump to the next mark
        '"' :
          if Res[P+1] = '"' then // skip empty string
            inc(P)
          else
            if SplitHTMLNewLine then // proceed html string value
              P := SplitHTMLString(P, PosEx('"', Res, P+1))
            else // just skip the string
              P := PosEx('"', Res, P+1);
        '=', '*', '/': begin // neat the math operator
          insert(' ', Res, P);   inc(P);
          if Res[P+1] = '=' then inc(P); // double equals
          insert(' ', Res, P+1); inc(P);
        end;
        '{' : // statement block begin
          if Res[P+1] = '}' then // skip empty statement
            inc(P)
          else begin
            inc(Lvl); // Increase identation level
            inProp := false;
            inc(P, AddNewLine(P+1, SpaceIdents(Lvl)));
          end;
        '}' : begin // statement block end
          // some pair values are treated specially: keep },{ pair intact to save empty lines
          if (length(Res) >= (P+2)) and (Res[P+1] = ',') and (Res[P+2] = '{') then begin
            dec(Lvl);
            inc(P, AddNewLine(P, SpaceIdents(Lvl)) + 2);
            inc(Lvl);
            inc(P, AddNewLine(P+1, SpaceIdents(Lvl)));
            continue;
          end;
          if not inNew then // special })] pair for items property group object ending
            inNew := (Res[P+1] = ')') and (Res[P+2] = ']');
          // common treatment for block ending
          dec(Lvl); // decrease identation level
          P := P + AddNewLine(P, SpaceIdents(lvl));
          // bring the following trails
          I := P;
          Backward := false;
          repeat
            inc(I);
            // find multiple statement block end
            if (length(Res) >= I) and (Res[I] in ['{', '}', ';']) then backward := true;
            if inNew and (length(Res) >= I) and (Res[I] = ']') then backward := true;
          until (I > length(Res)) or (Res[I] = ',') or backward;
          if not backward then // add new line
            inc(P, AddNewLine(i+1, SpaceIdents(Lvl)))
          else // suspend new line to proceed with next block
            P := i-1;
        end;
        ';' : begin // end of statement
          // fix to ExtPascal parser bug which become helpful, because it could be mark of new object creation
          if (length(Res) >= P+2) and (Res[P+1] = ' ') and (Res[P+2] = 'O') then begin  // ; O string
            inProp := false;
            delete(Res, P+1, 1);
            inc(P, AddNewLine(P+1, ^J+SpaceIdents(Lvl)));
            continue;
          end;
          if (length(Res) >= P+1) and (Res[P+1] = '}') then continue; // skip if it's already at the end of block
          if P = length(Res) then // skip identation on last end of statement
            inc(P, AddNewLine(P+1, SpaceIdents(StartingLevel-1)))
          else
            inc(P, AddNewLine(P+1, SpaceIdents(lvl)));
        end;
        '[' : begin // square declaration begin
          if Res[P+1] = '[' then begin // double square treat as sub level
            inc(Lvl);
            inc(P, AddNewLine(p+1, SpaceIdents(Lvl)));
            inProp := true;
            continue;
          end;
          // find special pair within square block
          i := PosEx(']', Res, P+1);
          j := PosEx('{', Res, P+1);
          k := PosEx('new ', Res, P+1);
          if (j > 0) and (j < i) then begin // new block found in property value
            inc(Lvl);
            // new object found in property value, add new line
            if (k > 0) and (k < i) then begin
              inNew := true;
              inc(P, AddNewLine(P+1, SpaceIdents(Lvl)));
            end
            else begin // move forward to next block beginning
              inNew := false;
              inc(J, AddNewLine(J+1, SpaceIdents(Lvl)));
              P := j-1;
            end;
          end
          else // no sub block found, move at the end of square block
            P := i;
        end;
        ']' : // square declaration end
          if Res[P-1] = ']' then begin // double square ending found, end sub block
            dec(Lvl);
            inc(P, AddNewLine(P, SpaceIdents(Lvl)));
          end
          else // skip processing if not part of square sub block
            if not inNew then
              continue
            else begin // end of block square items group
              dec(Lvl);
              inc(P, AddNewLine(P, SpaceIdents(Lvl)));
            end;
        ':' : begin // property value begin
          if Res[P+1] <> ' ' then begin // separate name:value with a space
            insert(' ', Res, P+1);
            inc(P);
          end;
          inProp := true;
          if Lvl < LvlProp then LvlProp := Lvl; // get minimum depth level of property
        end;
        ',' : // property value end
          if inProp then inc(P, AddNewLine(P+1, SpaceIdents(Lvl)));
        'f' : begin // independent function definition
          if inProp then Continue; // skip function if within property
          if copy(Res, P, 8) = 'function' then // add new line for independent function
            inc(P, AddNewLine(P, SpaceIdents(Lvl)) + 7);
        end;
        'r' : begin
          P := PosEx('/', Res, P);
          P := PosEx('/', Res, P+1);
        end;
      end;
    end;
  end;
  Result := Res;
end;

class function TMvcWebUtils.BeautifyCSS(const AStyle : string) : string;
var
  pOpen, pClose, pProp, pEnd, pString : integer;
  P, Lvl : integer;
  Res : string;
begin
  P := 1;
  Lvl := 0;
  Res := ^J+AStyle;
  while P > 0 do begin
    inc(P);
    pString := PosEx('''', Res, P);
    pOpen   := PosEx('{',  Res, P);
    pClose  := PosEx('}',  Res, P);
    pProp   := PosEx(':',  Res, P);
    pEnd    := PosEx(';',  Res, P);
    P := MinValueOf([pString, pOpen, pClose, pProp, pEnd]);
    if P > 0 then
      case Res[p] of
        '''' : P := PosEx('''', Res, P+1);
        '{' : begin
          Inc(lvl);
          if (res[p-1] <> ' ') then begin
            Insert(' ', res, p);
            p := p+1;
          end;
          Insert(^J+SpaceIdents(lvl), res, p+1);
          p := p + Length(^J+SpaceIdents(lvl));
        end;
        '}' : begin
          dec(lvl);
          insert(^J+SpaceIdents(lvl), Res, P);
          inc(P, length(^J+SpaceIdents(Lvl)));
          insert(^J+SpaceIdents(lvl), Res, P+1);
          inc(P, length(^J+SpaceIdents(Lvl)));
        end;
        ':' :
          if Res[P+1] <> ' ' then begin
            insert(' ', Res, P+1);
            inc(P);
          end;
        ';' : begin
          if Res[P+1] = '}' then continue;
          if Res[P+1] = ' ' then delete(Res, P+1, 1);
          insert(^J+SpaceIdents(Lvl), Res, P+1);
          inc(P, length(^J+SpaceIdents(Lvl)));
        end;
      end;
  end;
  Result := Res;
end;

class function TMvcWebUtils.LengthRegExp(Rex : string; CountAll : Boolean = true) : integer;
var
  Slash, I : integer;
  N : string;
begin
  Result := 0;
  N := '';
  Slash := 0;
  for I := 1 to length(Rex) do
    case Rex[I] of
      '\' :
        if CountAll and (I < length(Rex)) and (Rex[I+1] in ['d', 'D', 'l', 'f', 'n', 'r', 's', 'S', 't', 'w', 'W']) then inc(Slash);
      ',', '{' : begin
        N := '';
        if Slash > 1 then begin
          inc(Result, Slash);
          Slash := 0;
        end;
      end;
      '}' : begin
        inc(Result, StrToIntDef(N, 0));
        N := '';
        dec(Slash);
      end;
      '0'..'9' : N := N + Rex[I];
      '?' : inc(Slash);
      '*' :
        if not CountAll then begin
          Result := -1;
          exit;
        end;
    end;
  inc(Result, Slash);
end;

class function TMvcWebUtils.JSDateToDateTime(JSDate : string) : TDateTime; begin
  Result := EncodeDateTime(StrToInt(copy(JSDate, 12, 4)), AnsiIndexStr(copy(JSDate, 5, 3), ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']) +1,
    StrToInt(copy(JSDate, 9, 2)), StrToInt(copy(JSDate, 17, 2)), StrToInt(copy(JSDate, 20, 2)), StrToInt(copy(JSDate, 23, 2)), 0);
end;

class function TMvcWebUtils.IsNumber(S : string) : boolean;
var
  C : integer;
  D : double;
begin
  val(S, D, C);
  Result := C = 0;
end;

class function TMvcWebUtils.Encrypt(Value : string) : string;
var
  I, F1, F2, T : integer;
  B : byte;
  NValue : string;
begin
  Randomize;
  B := Random(256);
  NValue := char(B);
  F1 := 1; F2 := 2;
  for I := 1 to length(Value) do begin
    T := F2;
    inc(F2, F1);
    F1 := T;
    NValue := NValue + char(ord(Value[I]) + (B*F2));
  end;
  Result := '';
  for I := 1 to Length(NValue) do
    Result := Result + IntToHex(byte(NValue[I]), 2);
end;

class function TMvcWebUtils.Decrypt(Value : string) : string;
var
  I, F1, F2, T : integer;
  B : byte;
  NValue : string;
begin
  Result := '';
  if Value = '' then exit;
  NValue := '';
  for I := 0 to (length(Value)-1) div 2 do
    NValue := NValue + char(StrToInt('$' + copy(Value, I*2+1, 2)));
  B := ord(NValue[1]);
  F1 := 1; F2 := 2;
  for I := 2 to length(NValue) do begin
    T := F2;
    inc(F2, F1);
    F1 := T;
    Result := Result + char(ord(NValue[I]) - (B*F2))
  end;
end;

class procedure TMvcWebUtils.StrToTStrings(const S : string; List : TStrings);
var
  I: Integer;
begin
  List.DelimitedText := S;
  for I := 0 to List.Count - 1 do
    List[I] := Trim(List[I]);
end;

{
Decodes a URL encoded string to a normal string
@param Encoded URL encoded string to convert
@return A decoded string
}
class function TMvcWebUtils.URLDecode(const Encoded : string) : string;
var
  I : integer;
begin
  Result := {$IFDEF MSWINDOWS}UTF8ToAnsi{$ENDIF}(Encoded);
  I := pos('%', Result);
  while I <> 0 do begin
    Result[I] := chr(StrToIntDef('$' + copy(Result, I+1, 2), 32));
    Delete(Result, I+1, 2);
    I := pos('%', Result);
  end;
end;

{
Encodes a string to fit in URL encoding form
@param Decoded Normal string to convert
@return An URL encoded string
}
class function TMvcWebUtils.URLEncode(const Decoded : string) : string;
const
  Allowed = ['A'..'Z','a'..'z', '*', '@', '.', '_', '-', '0'..'9', '$', '!', '''', '(', ')'];
var
  I : integer;
begin
  Result := '';
  for I := 1 to length(Decoded) do
    if Decoded[I] in Allowed then
      Result := Result + Decoded[I]
    else
      Result := Result + '%' + IntToHex(ord(Decoded[I]), 2);
end;

class function TMvcWebUtils.DownloadContentType(const FileName :string; Default: string): AnsiString;
var
  FileExt: string;
  I: Integer;
begin
  Result := Default;
  FileExt := LowerCase(ExtractFileExt(FileName));
  for I := Low(CMIMEExtensions) to High(CMIMEExtensions) do
    with CMIMEExtensions[I] do
      if Ext = FileExt then
      begin
        Result := MimeType;
        Break;
      end;
end;

function MBUDecode(const str: RawByteString; cp: Word): UnicodeString;
begin
  SetLength(Result, MultiByteToWideChar(cp, 0, PAnsiChar(str), length(str), nil, 0));
  MultiByteToWideChar(cp, 0, PAnsiChar(str), length(str), PWideChar(Result), Length(Result));
end;


function HTTPDecode(const AStr: string): RawByteString;
var
  Sp, Rp, Cp: PAnsiChar;
  src: RawByteString;
begin
  src := RawByteString(AStr);
  SetLength(Result, Length(src));
  Sp := PAnsiChar(src);
  Rp := PAnsiChar(Result);
  while Sp^ <> #0 do
  begin
    case Sp^ of
      '+': Rp^ := ' ';
      '%': begin
             Inc(Sp);
             if Sp^ = '%' then
               Rp^ := '%'
             else
             begin
               Cp := Sp;
               Inc(Sp);
               if (Cp^ <> #0) and (Sp^ <> #0) then
                 Rp^ := AnsiChar(StrToInt('$' + Char(Cp^) + Char(Sp^)))
               else
               begin
                 Result := '';
                 Exit;
               end;
             end;
           end;
    else
      Rp^ := Sp^;
    end;
    Inc(Rp);
    Inc(Sp);
  end;
  SetLength(Result, Rp - PAnsiChar(Result));
end;


class function TMvcWebUtils.HTTPInterprete(src: PSOChar; named: boolean = false; sep: SOChar = ';'; StrictSep: boolean = false; codepage: Integer = 0): ISuperObject;
var
  P1: PSOChar;
  S: SOString;
  i: integer;
  obj, obj2, value: ISuperObject;
begin
    if named then
      Result := TSuperObject.create(stObject) else
      Result := TSuperObject.create(stArray);
    if not StrictSep then
      while {$IFDEF UNICODE}(src^ < #256) and {$ENDIF} (AnsiChar(src^) in [#1..' ']) do
        Inc(src);
    while src^ <> #0 do
    begin
      P1 := src;
      while ((not StrictSep and (src^ >= ' ')) or
            (StrictSep and (src^ <> #0))) and (src^ <> sep) do
        Inc(src);
      SetString(S, P1, src - P1);
      if codepage > 0 then
        S := MBUDecode(HTTPDecode(S), codepage);
      if named then
      begin
        i := pos('=', S);
        // named
        if i > 1 then
        begin
          S[i] := #0;
          obj := Result[S];
//          if sep = '&' then
//            value := DecodeValue(PChar(@S[i+1])) else
            value := TSuperObject.Create(PSOChar(@S[i+1]));
          if obj = nil then
            Result[S] := value else
            begin
              if obj.IsType(stArray) then
                obj.AsArray.Add(value) else
                begin
                  obj2 := TSuperObject.Create(stArray);
                  Result[S] := obj2;
                  obj2.AsArray.Add(obj);
                  obj2.AsArray.Add(value);
                end;
            end;
        end else
        begin
          // unamed value ignored
        end;
      end else
      begin
        value := TSuperObject.Create(S);
        if value = nil then
//          if sep = '&' then
//            value := DecodeValue(PChar(s)) else
            value := TSuperObject.Create(s);
        Result.AsArray.Add(value);
      end;
      if not StrictSep then
        while {$IFDEF UNICODE}(src^ < #256) and {$ENDIF} (AnsiChar(src^) in [#1..' ']) do
          Inc(src);
      if src^ = sep then
      begin
        P1 := src;
        Inc(P1);
        if (P1^ = #0) and not named then
          Result.AsArray.Add(TSuperObject.Create(''));
        repeat
          Inc(src);
        until not (not StrictSep and {$IFDEF UNICODE}(src^ < #256) and {$ENDIF} (AnsiChar(src^) in [#1..' ']));
      end;
    end;
end;

class function TMvcWebUtils.CssType:string;
begin
  Result:= 'text/css';
end;

class function TMvcWebUtils.JsType:string;
begin
  Result:= 'text/javascript';
end;

class function TMvcWebUtils.XMLType:string;
begin
  Result:= 'application/xml';
end;

class function TMvcWebUtils.JsonType:string;
begin
  Result:= 'application/json';
end;

class function TMvcWebUtils.TextType:string;
begin
  Result:= 'text/plain';
end;

class function TMvcWebUtils.HtmlType:string;
begin
  Result:= 'text/html';
end;


end.
