unit uHTMLWriter;
{$REGION 'License'}
{
  ***** BEGIN LICENSE BLOCK *****
  * Version: MPL 1.1
  *
  * The contents of this file are subject to the Mozilla Public License Version
  * 1.1 (the "License"); you may not use this file except in compliance with
  * the License. You may obtain a copy of the License at
  * http://www.mozilla.org/MPL/
  *
  * Software distributed under the License is distributed on an "AS IS" basis,
  * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
  * for the specific language governing rights and limitations under the
  * License.
  *
  * The Original Code is Delphi HTMLWriter
  *
  * The Initial Developer of the Original Code is
  * Nick Hodges
  *
  * Portions created by the Initial Developer are Copyright (C) 2010
  * the Initial Developer. All Rights Reserved.
  *
  * Contributor(s):
  *
  * ***** END LICENSE BLOCK *****
  }
{$ENDREGION}

interface

uses
       SysUtils
     , HTMLWriterUtils
     , Classes
     , Generics.Collections
     , HTMLWriterIntf
     , LoadSaveIntf
     ;

/// <summary>This function creates a reference to an ITHMLWriter interface. It creates a new HTML document by opening an &lt;html&gt; tag.</summary>
function HTMLWriterCreateDocument: IHTMLWriter; overload;
/// <summary>This function creates a reference to an ITHMLWriter interface. It adds the given HTML DOCTYPE header and then opens an &lt;html&gt; tag.</summary>
/// <param name="aDocType">Indicates what type of HTML document type should be created. Determines which HTML header is placed at the beginning of the document.</param>
function HTMLWriterCreateDocument(aDocType: THTMLDocType): IHTMLWriter; overload;
/// <summary>This function creates a reference to an ITHMLWriter interface. It creates an instance by opening the given tag and leaves the interface ready to add HTML.</summary>
/// <param name="aTagName">Defines the tag to be used as the initial tag for the HTML string</param>
/// <param name="aCloseTagType">This optional parameter defines how the starting tag should be closed.</param>
/// <param name="aCanAddAttributes">This otional parameter defines whether or not the tag should be allowed to take attributes.</param>
/// <remarks>Use this function when you need to create a "chunk" of HTML, and not a complete HTML document.</remarks>
function HTMLWriterCreate(aTagName: string = ''; aCloseTagType: TCloseTagType = ctNormal; aCanAddAttributes: TCanHaveAttributes = chaCanHaveAttributes): IHTMLWriter; overload;

implementation

type
  THTMLWriter = class(TInterfacedObject, IGetHTML, ILoadSave, IHTMLWriter)
  private
    FHTML: TStringBuilder;
    FClosingTag: string;
    FCurrentTagName: string;
    FTagState: TTagStates;
    FTableState: TTableStates;
    FFormState: TFormStates;
    FErrorLevels: THTMLErrorLevels;
    FParent: IHTMLWriter;
    FCanHaveAttributes: TCanHaveAttributes;
    function AddFormattedText(aString: string; aFormatType: TFormatType): IHTMLWriter;
    function OpenFormatTag(aFormatType: TFormatType; aCanAddAttributes: TCanHaveAttributes = chaCannotHaveAttributes): IHTMLWriter;
    function AddHeadingText(aString: string; aHeadingType: THeadingType): IHTMLWriter;
{$REGION 'In Tag Type Methods'}
    function InHeadTag: Boolean;
    function InBodyTag: Boolean;
    function InCommentTag: Boolean;
    function InSlashOnlyTag: Boolean;
    function TagIsOpen: Boolean;
    function InFormTag: Boolean;
    function InFieldSetTag: Boolean;
    function InListTag: Boolean;
    function InTableTag: Boolean;
    function InTableRowTag: Boolean;
    function TableHasColTag: Boolean;
    function TableIsOpen: Boolean;
    function InFrameSetTag: Boolean;
    function InMapTag: Boolean;
    function InObjectTag: Boolean;
    function InSelectTag: Boolean;
    function InOptGroup: Boolean;
    function HasTableContent: Boolean;
    function InDefList: Boolean;
{$ENDREGION}
    procedure IsDeprecatedTag(aName: string; aDeprecationLevel: THTMLErrorLevel);
{$REGION 'Close and Clean Methods'}
    function CloseBracket: IHTMLWriter;
    procedure CleanUpTagState;
    procedure CloseTheTag;
{$ENDREGION}
{$REGION 'Check Methods'}
    function CheckForErrors: Boolean;
    procedure CheckInHeadTag;
    procedure CheckInCommentTag;
    procedure CheckInListTag;
    procedure CheckInFormTag;
    procedure CheckInObjectTag;
    procedure CheckInFieldSetTag;
    procedure CheckInTableRowTag;
    procedure CheckInTableTag;
    procedure CheckInFramesetTag;
    procedure CheckInMapTag;
    procedure CheckInSelectTag;
    procedure CheckBracketOpen(aString: string);
    procedure CheckCurrentTagIsHTMLTag;
    procedure CheckNoOtherTableTags;
    procedure CheckNoColTag;
    procedure CheckBeforeTableContent;
    procedure CheckInDefList;
    procedure CheckIfNestedDefList;
    procedure CheckDefTermIsCurrent;
    procedure CheckDefItemIsCurrent;
{$ENDREGION}
    procedure SetClosingTagValue(aCloseTagType: TCloseTagType; aString: string = cEmptyString);
    function GetAttribute(const Name, Value: string): IHTMLWriter;
    function GetErrorLevels: THTMLErrorLevels;
    procedure SetErrorLevels(const Value: THTMLErrorLevels);
    function GetHTML: TStringBuilder;
    procedure InitializeHTMLWriter(aCloseTagType: TCloseTagType; aTagName: string);
    procedure InitializeEmptyHTMLWriter();
    procedure RemoveDefinitionFlags;

  public
{$REGION 'Constructors/Destructors'}
    /// <summary>Creates an instance of IHTMLWriter by passing in any arbitrary tag. Use this constructur if you want to create a chunk of HTML code not associated with a document.</summary>
    /// <param name="aTagName">The text for the tag you are creating. For instance, if you want to create a &lt;span&gt; tag, you should pass 'span' as the value</param>
    /// <param name="aCloseTagType">Determines the type of the tag being opened upon creation</param>
    /// <param name="aCanAddAttributes">Indicates if the tag should be allowed to have attributes. For instance, normally the &lt;b&gt; doesn't have attributes. Set this to False if you want to ensure that the tag will not have any attributes.</param>
    /// <exception cref="EHTMLWriterEmptyTagException">raised if an empty tag is passed as the aTagName parameter</exception>
    /// <seealso cref="CreateDocument">The CreateDocument constructor</seealso>
    constructor Create(aTagName: string; aCloseTagType: TCloseTagType = ctNormal; aCanAddAttributes: TCanHaveAttributes = chaCanHaveAttributes); overload;
    constructor Create(aHTMLWriter: THTMLWriter); overload;
    /// <summary>The CreateDocument constructor will create a standard HTML document.</summary>
    constructor CreateDocument; overload;
    constructor CreateDocument(aDocType: THTMLDocType); overload;

    destructor Destroy; override;
{$ENDREGION}
    function AddTag(aString: string; aCloseTagType: TCloseTagType = ctNormal; aCanAddAttributes: TCanHaveAttributes = chaCanHaveAttributes): IHTMLWriter;
{$REGION 'Main Section Methods'}
    function OpenHead: IHTMLWriter;
    function OpenMeta: IHTMLWriter;
    function OpenBase: IHTMLWriter;
    function OpenBaseFont: IHTMLWriter;
    function AddBase(aTarget: TTargetType; aFrameName: string = cEmptyString): IHTMLWriter; overload;
    function AddBase(aHREF: string): IHTMLWriter; overload;
    function OpenTitle: IHTMLWriter;
    function AddTitle(aTitleText: string): IHTMLWriter;
    function AddMetaNamedContent(aName: string; aContent: string): IHTMLWriter;
    function OpenBody: IHTMLWriter;
{$ENDREGION}
{$REGION 'Text Block Methods'}
    function OpenParagraph: IHTMLWriter;
    function OpenParagraphWithStyle(aStyle: string): IHTMLWriter;
    function OpenParagraphWithID(aID: string): IHTMLWriter;
    function OpenSpan: IHTMLWriter;
    function OpenDiv: IHTMLWriter;
    function OpenBlockQuote: IHTMLWriter;
    function AddParagraphText(aString: string): IHTMLWriter;
    function AddParagraphTextWithStyle(aString: string; aStyle: string): IHTMLWriter;
    function AddParagraphTextWithID(aString: string; aID: string): IHTMLWriter;
    function AddParagraphTextWithClass(aString: string; aClass: string): IHTMLWriter;
    function AddSpanText(aString: string): IHTMLWriter;
    function AddSpanTextWithStyle(aString: string; aStyle: string): IHTMLWriter;
    function AddSpanTextWithID(aString: string; aID: string): IHTMLWriter;
    function AddSpanTextWithClass(aString: string; aClass: string): IHTMLWriter;
    function AddDivText(aString: string): IHTMLWriter;
    function AddDivTextWithStyle(aString: string; aStyle: string): IHTMLWriter;
    function AddDivTextWithID(aString: string; aID: string): IHTMLWriter;
    function AddDivTextWithClass(aString: string; aClass: string): IHTMLWriter;
{$ENDREGION}
{$REGION 'General Formatting Methods'}
    function OpenBold: IHTMLWriter;
    function OpenItalic: IHTMLWriter;
    function OpenUnderline: IHTMLWriter;
    function OpenEmphasis: IHTMLWriter;
    function OpenStrong: IHTMLWriter;
    function OpenPre: IHTMLWriter;
    function OpenCite: IHTMLWriter;
    function OpenAcronym: IHTMLWriter;
    function OpenAbbreviation: IHTMLWriter;
    function OpenAddress: IHTMLWriter;
    function OpenBDO: IHTMLWriter;
    function OpenBig: IHTMLWriter;
    function OpenCenter: IHTMLWriter;
    function OpenCode: IHTMLWriter;
    function OpenDelete: IHTMLWriter;
    function OpenDefinition: IHTMLWriter;
    function OpenFont: IHTMLWriter;
    function OpenKeyboard: IHTMLWriter;
    function OpenQuotation: IHTMLWriter;
    function OpenSample: IHTMLWriter;
    function OpenSmall: IHTMLWriter;
    function OpenStrike: IHTMLWriter;
    function OpenTeletype: IHTMLWriter;
    function OpenVariable: IHTMLWriter;
    function OpenInsert: IHTMLWriter;

    function AddBoldText(aString: string): IHTMLWriter;
    function AddItalicText(aString: string): IHTMLWriter;
    function AddUnderlinedText(aString: string): IHTMLWriter;
    function AddEmphasisText(aString: string): IHTMLWriter;
    function AddStrongText(aString: string): IHTMLWriter;
    function AddPreformattedText(aString: string): IHTMLWriter;
    function AddCitationText(aString: string): IHTMLWriter;
    function AddBlockQuoteText(aString: string): IHTMLWriter;
    function AddAcronymText(aString: string): IHTMLWriter;
    function AddAbbreviationText(aString: string): IHTMLWriter;
    function AddAddressText(aString: string): IHTMLWriter;
    function AddBDOText(aString: string): IHTMLWriter;
    function AddBigText(aString: string): IHTMLWriter;
    function AddCenterText(aString: string): IHTMLWriter;
    function AddCodeText(aString: string): IHTMLWriter;
    function AddDeleteText(aString: string): IHTMLWriter;
    function AddDefinitionText(aString: string): IHTMLWriter;
    function AddFontText(aString: string): IHTMLWriter;
    function AddKeyboardText(aString: string): IHTMLWriter;
    function AddQuotationText(aString: string): IHTMLWriter;
    function AddSampleText(aString: string): IHTMLWriter;
    function AddSmallText(aString: string): IHTMLWriter;
    function AddStrikeText(aString: string): IHTMLWriter;
    function AddTeletypeText(aString: string): IHTMLWriter;
    function AddVariableText(aString: string): IHTMLWriter;
    function AddInsertText(aString: string): IHTMLWriter;
{$ENDREGION}
{$REGION 'Heading Methods'}
    function OpenHeading1: IHTMLWriter;
    function OpenHeading2: IHTMLWriter;
    function OpenHeading3: IHTMLWriter;
    function OpenHeading4: IHTMLWriter;
    function OpenHeading5: IHTMLWriter;
    function OpenHeading6: IHTMLWriter;

    function AddHeading1Text(aString: string): IHTMLWriter;
    function AddHeading2Text(aString: string): IHTMLWriter;
    function AddHeading3Text(aString: string): IHTMLWriter;
    function AddHeading4Text(aString: string): IHTMLWriter;
    function AddHeading5Text(aString: string): IHTMLWriter;
    function AddHeading6Text(aString: string): IHTMLWriter;
{$ENDREGION}
{$REGION 'CSS Formatting Methods'}
    // CSS Formatting
    function AddStyle(aStyle: string): IHTMLWriter;
    function AddClass(aClass: string): IHTMLWriter;
    function AddID(aID: string): IHTMLWriter;
{$ENDREGION}
{$REGION 'Miscellaneous Methods'}
    function AddAttribute(aString: string; aValue: string = cEmptyString): IHTMLWriter;
    function AddLineBreak(const aClearValue: TClearValue = cvNoValue; aUseEmptyTag: TIsEmptyTag = ietIsEmptyTag): IHTMLWriter;
    function AddHardRule(const aAttributes: string = cEmptyString; aUseEmptyTag: TIsEmptyTag = ietIsEmptyTag): IHTMLWriter;
    function CRLF: IHTMLWriter;
    function Indent(aNumberofSpaces: integer): IHTMLWriter;
    function OpenComment: IHTMLWriter;
    function AddText(aString: string): IHTMLWriter;
    function AddRawText(aString: string): IHTMLWriter;
    function AsHTML: string;
    function AddComment(aCommentText: string): IHTMLWriter;
    function OpenScript: IHTMLWriter;

    function AddScript(aScriptText: string): IHTMLWriter;

    function OpenNoScript: IHTMLWriter;
    function OpenLink: IHTMLWriter;
{$ENDREGION}
{$REGION 'CloseTag methods'}
    { TODO -oNick : Add more specialized close tags CloseTable, CloseList, etc. }
    function CloseTag(aUseCRLF: TUseCRLFOptions = ucoNoCRLF): IHTMLWriter;
    function CloseComment: IHTMLWriter;
    function CloseList: IHTMLWriter;
    function CloseTable: IHTMLWriter;
    function CloseForm: IHTMLWriter;
    function CloseDocument: IHTMLWriter;
{$ENDREGION}
{$REGION 'Image Methods'}
    function OpenImage: IHTMLWriter; overload;
    function OpenImage(aImageSource: string): IHTMLWriter; overload;
    function AddImage(aImageSource: string): IHTMLWriter;
{$ENDREGION}
{$REGION 'Anchor Methods'}
    function OpenAnchor: IHTMLWriter; overload;
    function OpenAnchor(aName: string): IHTMLWriter; overload;
    function OpenAnchor(const aHREF: string; aText: string): IHTMLWriter; overload;
    function AddAnchor(const aHREF: string; aText: string): IHTMLWriter; overload;
{$ENDREGION}
{$REGION 'Table Support Methods'}
    function OpenTable: IHTMLWriter; overload;
    function OpenTable(aBorder: integer): IHTMLWriter; overload;
    function OpenTable(aBorder: integer; aCellPadding: integer): IHTMLWriter; overload;
    function OpenTable(aBorder: integer; aCellPadding: integer; aCellSpacing: integer): IHTMLWriter; overload;
    function OpenTable(aBorder: integer; aCellPadding: integer; aCellSpacing: integer; aWidth: THTMLWidth): IHTMLWriter; overload;

    function OpenTableRow: IHTMLWriter;
    function OpenTableHeader: IHTMLWriter;
    function OpenTableData: IHTMLWriter;
    function AddTableData(aText: string): IHTMLWriter;
    function OpenCaption: IHTMLWriter;
    function OpenColGroup: IHTMLWriter;
    function OpenCol: IHTMLWriter;
    function OpenTableHead: IHTMLWriter;
    function OpenTableBody: IHTMLWriter;
    function OpenTableFoot: IHTMLWriter;
{$ENDREGION}
{$REGION 'Form Methods'}
    function OpenForm(aActionURL: string = cEmptyString; aMethod: TFormMethod = fmGet): IHTMLWriter;
    function OpenInput: IHTMLWriter; overload;
    function OpenInput(aType: TInputType; aName: string = cEmptyString): IHTMLWriter; overload;
    function OpenButton(aName: string): IHTMLWriter;
    function OpenLabel: IHTMLWriter; overload;
    function OpenLabel(aFor: string): IHTMLWriter; overload;
    function OpenSelect(aName: string): IHTMLWriter;
    function OpenTextArea(aName: string; aCols: integer; aRows: integer): IHTMLWriter;
    function OpenOptGroup(aLabel: string): IHTMLWriter;
    function OpenOption: IHTMLWriter;
{$ENDREGION}
{$REGION 'FieldSet/Legend'}
    function OpenFieldSet: IHTMLWriter;
    function OpenLegend: IHTMLWriter;
    function AddLegend(aText: string): IHTMLWriter;
{$ENDREGION}
{$REGION 'IFrame support'}
    function OpenIFrame: IHTMLWriter; overload;
    function OpenIFrame(aURL: string): IHTMLWriter; overload;
    function OpenIFrame(aURL: string; aWidth: THTMLWidth; aHeight: integer): IHTMLWriter; overload;
    function AddIFrame(aURL: string; aAlternateText: string): IHTMLWriter; overload;
    function AddIFrame(aURL: string; aAlternateText: string; aWidth: THTMLWidth; aHeight: integer): IHTMLWriter; overload;
{$ENDREGION}
{$REGION 'List Methods'}
    function OpenUnorderedList(aBulletShape: TBulletShape = bsNone): IHTMLWriter;
    function OpenOrderedList(aNumberType: TNumberType = ntNone): IHTMLWriter;
    function OpenListItem: IHTMLWriter;

    function AddListItem(aText: string): IHTMLWriter;
{$ENDREGION}
{$REGION 'Storage Methods'}
    procedure LoadFromFile(const FileName: string); overload; virtual;
    procedure LoadFromFile(const FileName: string; Encoding: TEncoding); overload; virtual;
    procedure LoadFromStream(Stream: TStream); overload; virtual;
    procedure LoadFromStream(Stream: TStream; Encoding: TEncoding); overload; virtual;
    procedure SaveToFile(const FileName: string); overload; virtual;
    procedure SaveToFile(const FileName: string; Encoding: TEncoding); overload; virtual;
    procedure SaveToStream(Stream: TStream); overload; virtual;
    procedure SaveToStream(Stream: TStream; Encoding: TEncoding); overload; virtual;
{$ENDREGION}
    function OpenFrameset: IHTMLWriter;
    function OpenFrame: IHTMLWriter;
    function OpenNoFrames: IHTMLWriter;
    function OpenMap: IHTMLWriter;
    function OpenArea(aAltText: string): IHTMLWriter;
    function OpenObject: IHTMLWriter;
    function OpenParam(aName: string; aValue: string = cEmptyString): IHTMLWriter; // name parameter is required

    function OpenDefinitionList: IHTMLWriter;
    function OpenDefinitionTerm: IHTMLWriter;
    function OpenDefinitionItem: IHTMLWriter;

    class function Write: IHTMLWriter;
    property Attribute[const Name: string; const Value: string]: IHTMLWriter read GetAttribute; default;
    property ErrorLevels: THTMLErrorLevels read GetErrorLevels write SetErrorLevels;
    property HTML: TStringBuilder read GetHTML;

  end;

  { THTMLWriter }

constructor THTMLWriter.Create(aHTMLWriter: THTMLWriter);
begin
  inherited Create; ;
  FHTML := TStringBuilder.Create;
  HTML.Append(aHTMLWriter.HTML.ToString);
  FCurrentTagName := aHTMLWriter.FCurrentTagName;
  FTagState := aHTMLWriter.FTagState;
  FFormState := aHTMLWriter.FFormState;
  FTableState := aHTMLWriter.FTableState;
  FErrorLevels := aHTMLWriter.FErrorLevels;
  FCanHaveAttributes := aHTMLWriter.FCanHaveAttributes;
  FClosingTag := aHTMLWriter.FClosingTag;
end;

function THTMLWriter.CloseBracket: IHTMLWriter;
begin
  if (tsBracketOpen in FTagState) and (not InCommentTag) then
  begin
    FHTML := FHTML.Append(cCloseBracket);
    Include(FTagState, tsTagOpen);
    Exclude(FTagState, tsBracketOpen);
  end;
  Result := Self;
end;

function THTMLWriter.CloseComment: IHTMLWriter;
begin
  CheckInCommentTag;
  Result := CloseTag;
end;

function THTMLWriter.CloseDocument: IHTMLWriter;
begin
  CheckCurrentTagIsHTMLTag;
  Result := CloseTag;
end;

function THTMLWriter.CloseForm: IHTMLWriter;
begin
  CheckInFormTag;
  Result := CloseTag;
end;

function THTMLWriter.CloseList: IHTMLWriter;
begin
  CheckInListTag;
  Result := CloseTag;
end;

function THTMLWriter.CloseTable: IHTMLWriter;
begin
  CheckInTableTag;
  Result := CloseTag;
end;

function THTMLWriter.CloseTag(aUseCRLF: TUseCRLFOptions = ucoNoCRLF): IHTMLWriter;
var
  TempText: string;
begin
  if tsTagClosed in FTagState then
  begin
    raise ETryingToCloseClosedTag.Create(strClosingClosedTag);
  end;

  if (not InSlashOnlyTag) and (not InCommentTag) then
  begin
    CloseBracket;
  end;

  CloseTheTag;

  CleanUpTagState;

  if Self.FParent <> nil then
  begin
    TempText := Self.HTML.ToString;
    Result := Self.FParent;
    Result.HTML.Clear;
    Result.HTML.Append(TempText);
  end
  else
  begin
    Result := Self;
    Exclude(FTagState, tsTagClosed);
  end;

  if aUseCRLF = ucoUseCRLF then
  begin
    Result.HTML.Append(cCRLF);
  end;
end;

constructor THTMLWriter.Create(aTagName: string; aCloseTagType: TCloseTagType = ctNormal; aCanAddAttributes: TCanHaveAttributes = chaCanHaveAttributes);
begin
  if StringIsEmpty(aTagName) then
  begin
    InitializeEmptyHTMLWriter;
  end
  else
  begin
    InitializeHTMLWriter(aCloseTagType, aTagName);
  end;
end;

constructor THTMLWriter.CreateDocument(aDocType: THTMLDocType);
begin
  inherited Create;
  CreateDocument;
  FHTML := FHTML.Insert(0, THTMLDocTypeStrings[aDocType]);
end;

function THTMLWriter.CRLF: IHTMLWriter;
begin
  CloseBracket;
  FHTML.Append(cCRLF);
  Result := Self;
end;

constructor THTMLWriter.CreateDocument;
begin
  Create(cHTML, ctNormal, chaCanHaveAttributes);
end;

destructor THTMLWriter.Destroy;
begin
  FHTML.Free;
  inherited;
end;

function THTMLWriter.GetAttribute(const Name, Value: string): IHTMLWriter;
begin
  Result := Self.AddAttribute(Name, Value);
end;

function THTMLWriter.GetErrorLevels: THTMLErrorLevels;
begin
  Result := FErrorLevels;
end;

function THTMLWriter.GetHTML: TStringBuilder;
begin
  Result := FHTML;
end;

function THTMLWriter.HasTableContent: Boolean;
begin
  Result := (tbsTableHasData in FTableState);
end;

function THTMLWriter.InBodyTag: Boolean;
begin
  Result := tsInBodyTag in FTagState;
end;

function THTMLWriter.InCommentTag: Boolean;
begin
  Result := tsCommentOpen in FTagState;
end;

function THTMLWriter.InDefList: Boolean;
begin
  Result := tsInDefinitionList in FTagState;
end;

function THTMLWriter.Indent(aNumberofSpaces: integer): IHTMLWriter;
var
  i: integer;
begin
  for i := 1 to aNumberofSpaces do
  begin
    FHTML.Append(cSpace);
  end;
  Result := Self;
end;

function THTMLWriter.InFieldSetTag: Boolean;
begin
  Result := tsInFieldSetTag in FTagState;
end;

function THTMLWriter.InFormTag: Boolean;
begin
  Result := fsInFormTag in FFormState;
end;

function THTMLWriter.TableIsOpen: Boolean;
begin
  Result := tbsInTable in FTableState;
end;

function THTMLWriter.InFrameSetTag: Boolean;
begin
  Result := tsInFramesetTag in FTagState;
end;

function THTMLWriter.TagIsOpen: Boolean;
begin
  Result := tsTagOpen in FTagState;
end;

class function THTMLWriter.Write: IHTMLWriter;
begin
  Result := THTMLWriter.CreateDocument;
end;

procedure THTMLWriter.RemoveDefinitionFlags;
begin
  Exclude(FTagState, tsInDefinitionList);
  Exclude(FTagState, tsHasDefinitionTerm);
  Exclude(FTagState, tsDefTermIsCurrent);
  Exclude(FTagState, tsDefItemIsCurrent);
end;

procedure THTMLWriter.InitializeEmptyHTMLWriter();
begin
  FCanHaveAttributes := chaCanHaveAttributes;
  FHTML := TStringBuilder.Create;
  //FHTML := FHTML.Append(cOpenBracket).Append(FCurrentTagName);
  FTagState := FTagState;
  FErrorLevels := [elErrors];
  //SetClosingTagValue(aCloseTagType, aTagName);
end;

procedure THTMLWriter.InitializeHTMLWriter(aCloseTagType: TCloseTagType; aTagName: string);
begin
  FCurrentTagName := aTagName;
  FCanHaveAttributes := chaCanHaveAttributes;
  FHTML := TStringBuilder.Create;
  FHTML := FHTML.Append(cOpenBracket).Append(FCurrentTagName);
  FTagState := FTagState + [tsBracketOpen];
  FErrorLevels := [elErrors];
  SetClosingTagValue(aCloseTagType, aTagName);
end;

function THTMLWriter.InHeadTag: Boolean;
begin
  Result := tsInHeadTag in FTagState;
end;

function THTMLWriter.InListTag: Boolean;
begin
  Result := tsInListTag in FTagState;
end;

function THTMLWriter.InMapTag: Boolean;
begin
  Result := tsInMapTag in FTagState;
end;

function THTMLWriter.InObjectTag: Boolean;
begin
  Result := tsInObjectTag in FTagState;
end;

function THTMLWriter.InOptGroup: Boolean;
begin
  Result := fsInOptGroup in FFormState;
end;

function THTMLWriter.InSelectTag: Boolean;
begin
  Result := fsInSelect in FFormState;
end;

function THTMLWriter.InSlashOnlyTag: Boolean;
begin
  Result := FClosingTag = TTagMaker.MakeSlashCloseTag;
end;

function THTMLWriter.InTableRowTag: Boolean;
begin
  Result := tbsInTableRowTag in FTableState;
end;

function THTMLWriter.TableHasColTag: Boolean;
begin
  Result := tbsTableHasCol in FTableState;
end;

function THTMLWriter.InTableTag: Boolean;
begin
  Result := tbsInTable in FTableState;
end;

procedure THTMLWriter.IsDeprecatedTag(aName: string; aDeprecationLevel: THTMLErrorLevel);
begin
  if aDeprecationLevel in ErrorLevels then
  begin
    raise ETagIsDeprecatedHTMLWriterException.Create(Format(strDeprecatedTag, [aName, THTMLErrorLevelStrings[aDeprecationLevel]]));
  end;
end;

function THTMLWriter.OpenBold: IHTMLWriter;
begin
  Result := OpenFormatTag(ftBold);
end;

function THTMLWriter.OpenButton(aName: string): IHTMLWriter;
begin
  CheckInFormTag;
  Result := AddTag(cButton).AddAttribute(cName, aName);
end;

function THTMLWriter.OpenCenter: IHTMLWriter;
begin
  IsDeprecatedTag(TFormatTypeStrings[ftCenter], elStrictHTML4);
  Result := OpenFormatTag(ftCenter);
end;

function THTMLWriter.OpenCite: IHTMLWriter;
begin
  Result := OpenFormatTag(ftCitation);
end;

function THTMLWriter.OpenEmphasis: IHTMLWriter;
begin
  Result := OpenFormatTag(ftEmphasis);
end;

function THTMLWriter.OpenFieldSet: IHTMLWriter;
var
  Temp: THTMLWriter;
begin
  CheckInFormTag;
  Temp := THTMLWriter.Create(Self);
  Temp.FTagState := Temp.FTagState + [tsInFieldSetTag];
  Temp.FParent := Self.FParent;
  Result := Temp.AddTag(cFieldSet);
end;

function THTMLWriter.OpenFont: IHTMLWriter;
begin
  IsDeprecatedTag(TFormatTypeStrings[ftFont], elStrictHTML4);
  Result := OpenFormatTag(ftFont);
end;

function THTMLWriter.OpenForm(aActionURL: string = cEmptyString; aMethod: TFormMethod = fmGet): IHTMLWriter;
var
  Temp: THTMLWriter;
begin
  Include(FFormState, fsInFormTag);
  Temp := THTMLWriter.Create(Self);
  Temp.FParent := Self.FParent;
  Result := Temp.AddTag(cForm);
  if not StringIsEmpty(aActionURL) then
  begin
    Result := Result[cAction, aActionURL];
  end;
  if aMethod <> fmNone then
  begin
    Result := Result[cMethod, TFormMethodStrings[aMethod]]
  end;
end;

function THTMLWriter.OpenFormatTag(aFormatType: TFormatType; aCanAddAttributes: TCanHaveAttributes = chaCannotHaveAttributes): IHTMLWriter;
begin
  Result := AddTag(TFormatTypeStrings[aFormatType], ctNormal, chaCannotHaveAttributes);
end;

function THTMLWriter.OpenFrame: IHTMLWriter;
begin
  IsDeprecatedTag(cFrameset, elStrictHTML5);
  CheckInFramesetTag;
  Result := AddTag(cFrame);
end;

function THTMLWriter.OpenFrameset: IHTMLWriter;
var
  Temp: THTMLWriter;
begin
  Temp := THTMLWriter.Create(Self);
  Temp.FParent := Self.FParent;
  Include(Temp.FTagState, tsInFramesetTag);
  IsDeprecatedTag(cFrameset, elStrictHTML5);
  Result := Temp.AddTag(cFrameset);
end;

function THTMLWriter.OpenHeading1: IHTMLWriter;
begin
  Result := AddTag(THeadingTypeStrings[htHeading1]);
end;

function THTMLWriter.OpenHeading2: IHTMLWriter;
begin
  Result := AddTag(THeadingTypeStrings[htHeading2]);
end;

function THTMLWriter.OpenHeading3: IHTMLWriter;
begin
  Result := AddTag(THeadingTypeStrings[htHeading3]);
end;

function THTMLWriter.OpenHeading4: IHTMLWriter;
begin
  Result := AddTag(THeadingTypeStrings[htHeading4]);
end;

function THTMLWriter.OpenHeading5: IHTMLWriter;
begin
  Result := AddTag(THeadingTypeStrings[htHeading5]);
end;

function THTMLWriter.OpenHeading6: IHTMLWriter;
begin
  Result := AddTag(THeadingTypeStrings[htHeading6]);
end;

function THTMLWriter.OpenImage: IHTMLWriter;
begin
  Result := AddTag(cImage, ctEmpty);
end;

function THTMLWriter.OpenIFrame: IHTMLWriter;
begin
  Result := AddTag(cIFrame);
end;

function THTMLWriter.OpenIFrame(aURL: string): IHTMLWriter;
begin
  Result := OpenIFrame.AddAttribute(cSource, aURL);
end;

function THTMLWriter.OpenIFrame(aURL: string; aWidth: THTMLWidth; aHeight: integer): IHTMLWriter;
begin
  Result := OpenIFrame(aURL).AddAttribute(aWidth.WidthString).AddAttribute(cHeight, IntToStr(aHeight));
end;

function THTMLWriter.OpenImage(aImageSource: string): IHTMLWriter;
begin
  Result := AddTag(cImage, ctEmpty).AddAttribute(cSource, aImageSource);
end;

function THTMLWriter.OpenInput(aType: TInputType; aName: string = cEmptyString): IHTMLWriter;
begin
  CheckInFormTag;
  Result := OpenInput.AddAttribute(cType, TInputTypeStrings[aType]);
  if StringIsNotEmpty(aName) then
  begin
    Result := Result[cName, aName];
  end;
end;

function THTMLWriter.OpenInsert: IHTMLWriter;
begin
  Result := OpenFormatTag(ftInsert);
end;

function THTMLWriter.AddImage(aImageSource: string): IHTMLWriter;
begin
  Result := OpenImage(aImageSource).CloseTag;
end;

function THTMLWriter.OpenInput: IHTMLWriter;
begin
  CheckInFormTag;
  Result := AddTag(cInput, ctEmpty);
end;

function THTMLWriter.AddInsertText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftInsert);
end;

function THTMLWriter.OpenItalic: IHTMLWriter;
begin
  Result := OpenFormatTag(ftItalic);
end;

function THTMLWriter.OpenKeyboard: IHTMLWriter;
begin
  Result := OpenFormatTag(ftKeyboard);
end;

function THTMLWriter.OpenLabel: IHTMLWriter;
begin
  CheckInFormTag;
  Result := AddTag(cLabel);
end;

function THTMLWriter.OpenLabel(aFor: string): IHTMLWriter;
begin
  Result := OpenLabel[cFor, aFor];
end;

function THTMLWriter.OpenLegend: IHTMLWriter;
begin
  CheckInFieldSetTag;
  Result := AddTag(cLegend);
end;

function THTMLWriter.OpenLink: IHTMLWriter;
begin
  Result := AddTag(cLink, ctEmpty);
end;

function THTMLWriter.OpenListItem: IHTMLWriter;
begin
  CheckInListTag;
  Result := AddTag(cListItem);
end;

function THTMLWriter.OpenMap: IHTMLWriter;
var
  Temp: THTMLWriter;
begin
  Temp := THTMLWriter.Create(Self);
  Temp.FParent := Self.FParent;
  Include(Temp.FTagState, tsInMapTag);
  Result := Temp.AddTag(cMap);
end;

function THTMLWriter.OpenMeta: IHTMLWriter;
begin
  CheckInHeadTag;
  Result := AddTag(cMeta, ctEmpty);
end;

function THTMLWriter.OpenNoFrames: IHTMLWriter;
begin
  IsDeprecatedTag(cFrameset, elStrictHTML5);
  Result := AddTag(cNoFrames);
end;

function THTMLWriter.OpenNoScript: IHTMLWriter;
begin
  Result := AddTag(cNoScript);
end;

function THTMLWriter.OpenStrike: IHTMLWriter;
begin
  IsDeprecatedTag(TFormatTypeStrings[ftStrike], elStrictHTML4);
  Result := OpenFormatTag(ftStrike);
end;

function THTMLWriter.OpenStrong: IHTMLWriter;
begin
  Result := OpenFormatTag(ftStrong);
end;

function THTMLWriter.OpenTable: IHTMLWriter;
begin
  Result := OpenTable(-1, -1, -1);
end;

function THTMLWriter.OpenTable(aBorder: integer): IHTMLWriter;
begin
  Result := OpenTable(aBorder, -1, -1);
end;

function THTMLWriter.OpenTable(aBorder: integer; aCellPadding: integer): IHTMLWriter;
begin
  Result := OpenTable(aBorder, aCellPadding, -1);
end;

function THTMLWriter.OpenTable(aBorder, aCellPadding, aCellSpacing: integer): IHTMLWriter;
begin
  Result := OpenTable(aBorder, aCellPadding, aCellSpacing, THTMLWidth.Create(-1, False));
end;

function THTMLWriter.OpenTable(aBorder: integer; aCellPadding: integer; aCellSpacing: integer; aWidth: THTMLWidth): IHTMLWriter;
var
  Temp: THTMLWriter;
begin
  Temp := THTMLWriter.Create(Self);
  Temp.FParent := Self.FParent;
  Temp.FTableState := Temp.FTableState + [tbsInTable];

  Result := Temp.AddTag(cTable);
  if aBorder >= 0 then
  begin
    Result := Result.AddAttribute(cBorder, IntToStr(aBorder));
  end;
  if aCellPadding >= 0 then
  begin
    Result := Result.AddAttribute(cCellPadding, IntToStr(aCellPadding));
  end;
  if aCellSpacing >= 0 then
  begin
    Result := Result.AddAttribute(cCellSpacing, IntToStr(aCellSpacing));
  end;
  if aWidth.Width >= 0 then
  begin
    if aWidth.IsPercentage then
    begin
      Result := Result.AddAttribute(cWidth, aWidth.AsPercentage);
    end
    else
    begin
      Result := Result.AddAttribute(aWidth.WidthString);
    end;
  end;
end;

function THTMLWriter.OpenTableBody: IHTMLWriter;
begin
  CheckInTableTag;
  Result := AddTag(cTableBody);
end;

function THTMLWriter.OpenTableData: IHTMLWriter;
begin
  CheckInTableTag;
  Result := AddTag(cTableData);
end;

function THTMLWriter.OpenTableFoot: IHTMLWriter;
begin
  CheckInTableTag;
  Result := AddTag(cTableFoot);
end;

function THTMLWriter.OpenTableHead: IHTMLWriter;
begin
  CheckInTableTag;
  Result := AddTag(cTableHead);
end;

function THTMLWriter.OpenTableHeader: IHTMLWriter;
begin
  CheckInTableRowTag;
  Result := AddTag(cTableHeader);
end;

function THTMLWriter.OpenTableRow: IHTMLWriter;
var
  Temp: THTMLWriter;
begin
  CheckInTableTag;
  Temp := THTMLWriter.Create(Self);
  Temp.FParent := Self.FParent;
  Temp.FTableState := Temp.FTableState + [tbsInTableRowTag, tbsTableHasData];
  Result := Temp.AddTag(cTableRow);
end;

function THTMLWriter.OpenTeletype: IHTMLWriter;
begin
  IsDeprecatedTag(TFormatTypeStrings[ftTeletype], elStrictHTML5);
  Result := OpenFormatTag(ftTeletype);
end;

function THTMLWriter.OpenTextArea(aName: string; aCols: integer; aRows: integer): IHTMLWriter;
begin
  CheckInFormTag;
  Result := AddTag(cTextArea)[cName, aName][cCols, IntToStr(aCols)][cRows, IntToStr(aRows)];
end;

function THTMLWriter.OpenTitle: IHTMLWriter;
begin
  CheckInHeadTag;
  Result := AddTag(cTitle);
end;

function THTMLWriter.OpenUnderline: IHTMLWriter;
begin
  IsDeprecatedTag(TFormatTypeStrings[ftUnderline], elStrictHTML4);
  Result := OpenFormatTag(ftUnderline);
end;

function THTMLWriter.OpenUnorderedList(aBulletShape: TBulletShape = bsNone): IHTMLWriter;
var
  Temp: THTMLWriter;
begin
  Temp := THTMLWriter.Create(Self);
  Temp.FParent := Self.FParent;
  Temp.FTagState := Temp.FTagState + [tsInListTag];
  Result := Temp.AddTag(cUnorderedList);
  if aBulletShape <> bsNone then
  begin
    Result := Result.AddAttribute(cType, TBulletShapeStrings[aBulletShape]);
  end;
end;

function THTMLWriter.OpenVariable: IHTMLWriter;
begin
  Result := OpenFormatTag(ftVariable);
end;

procedure THTMLWriter.SaveToFile(const FileName: string);
begin
  SaveToFile(FileName, nil);
end;

procedure THTMLWriter.SaveToFile(const FileName: string; Encoding: TEncoding);
var
  Stream: TStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stream, Encoding);
  finally
    Stream.Free;
  end;
end;

procedure THTMLWriter.LoadFromFile(const FileName: string; Encoding: TEncoding);
var
  Stream: TStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(Stream, Encoding);
  finally
    Stream.Free;
  end;
end;

procedure THTMLWriter.LoadFromFile(const FileName: string);
var
  Stream: TStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure THTMLWriter.LoadFromStream(Stream: TStream);
begin
  LoadFromStream(Stream, nil);
end;

procedure THTMLWriter.LoadFromStream(Stream: TStream; Encoding: TEncoding);
var
  SS: TStringStream;
begin
  if Encoding = nil then
  begin
    Encoding := TEncoding.Default;
  end;
  SS := TStringStream.Create(cEmptyString, Encoding);
  try
    SS.LoadFromStream(Stream);
    FHTML.Clear;
    FHTML := FHTML.Append(SS.DataString);
  finally
    SS.Free;
  end;
end;

procedure THTMLWriter.SaveToStream(Stream: TStream; Encoding: TEncoding);
var
  SS: TStringStream;
begin
  if Encoding = nil then
  begin
    Encoding := TEncoding.Default;
  end;
  SS := TStringStream.Create(FHTML.ToString, Encoding);
  try
    Stream.CopyFrom(SS, SS.Size);
  finally
    SS.Free;
  end;
end;

procedure THTMLWriter.SetErrorLevels(const Value: THTMLErrorLevels);
begin
  FErrorLevels := Value;
end;

procedure THTMLWriter.SetClosingTagValue(aCloseTagType: TCloseTagType; aString: string = cEmptyString);
begin
  case aCloseTagType of
    ctNormal:
      FClosingTag := TTagMaker.MakeCloseTag(aString);
    ctEmpty:
      FClosingTag := TTagMaker.MakeSlashCloseTag;
    ctComment:
      FClosingTag := TTagMaker.MakeCommentCloseTag;
  end;
end;

procedure THTMLWriter.SaveToStream(Stream: TStream);
begin
  SaveToStream(Stream, nil);
end;

function THTMLWriter.OpenObject: IHTMLWriter;
var
  Temp: THTMLWriter;
begin
  Temp := THTMLWriter.Create(Self);
  Temp.FParent := Self.FParent;
  Include(Temp.FTagState, tsInObjectTag);
  Result := Temp.AddTag(cObject);
end;

function THTMLWriter.OpenOptGroup(aLabel: string): IHTMLWriter;
begin
  CheckInSelectTag;
  Include(FFormState, fsInOptGroup);
  Result := AddTag(cOptGroup)[cLabel, aLabel];
end;

function THTMLWriter.OpenOption: IHTMLWriter;
begin
  CheckInSelectTag;
  Result := AddTag(cOption);
end;

function THTMLWriter.OpenOrderedList(aNumberType: TNumberType): IHTMLWriter;
var
  Temp: THTMLWriter;
begin
  Temp := THTMLWriter.Create(Self);
  Temp.FParent := Self.FParent;
  Temp.FTagState := Temp.FTagState + [tsInListTag];
  Result := Temp.AddTag(cOrderedList);
  if aNumberType <> ntNone then
  begin
    Result := Result.AddAttribute(cType, TNumberTypeStrings[aNumberType]);
  end;
end;

procedure THTMLWriter.CleanUpTagState;
begin
  FTagState := FTagState + [tsTagClosed] - [tsTagOpen, tsBracketOpen];

  if TableIsOpen then
  begin
    FTableState := [];
  end;

  if (FCurrentTagName = cObject) and InObjectTag then
  begin
    Exclude(FTagState, tsInObjectTag);
  end;

  if (FCurrentTagName = cMap) and InMapTag then
  begin
    Exclude(FTagState, tsInMapTag);
  end;

  if (FCurrentTagName = cFrameset) and InFrameSetTag then
  begin
    Exclude(FTagState, tsInFramesetTag);
  end;

  if (FCurrentTagName = cFieldSet) and InFieldSetTag then
  begin
    Exclude(FTagState, tsInFieldSetTag);
  end;

  if (FCurrentTagName = cComment) and InCommentTag then
  begin
    Exclude(FTagState, tsCommentOpen);
  end;

  if (FCurrentTagName = cForm) and InFormTag then
  begin
    Exclude(FFormState, fsInFormTag);
  end;

  if (FCurrentTagName = cUnorderedList) and InListTag then
  begin
    Exclude(FTagState, tsInListTag);
  end;

  if (FCurrentTagName = cOrderedList) and InListTag then
  begin
    Exclude(FTagState, tsInListTag);
  end;

  if (FCurrentTagName = cTable) and InTableTag then
  begin
    Exclude(FTableState, tbsInTable);
  end;

  if (FCurrentTagName = cHead) and InHeadTag then
  begin
    Exclude(FTagState, tsInHeadTag);
  end;

  if (FCurrentTagName = cBody) and InBodyTag then
  begin
    Exclude(FTagState, tsInBodyTag);
  end;

  if (FCurrentTagName = cTableRow) and InTableRowTag then
  begin
    Exclude(FTableState, tbsInTableRowTag);
  end;

  if (FCurrentTagName = cSelect) and InSelectTag then
  begin
    Exclude(FFormState, fsInSelect);
  end;

  if (FCurrentTagName = cOptGroup) and InOptGroup then
  begin
    Exclude(FFormState, fsInOptGroup);
  end;

  if (FCurrentTagName = cDL) and InDefList then
  begin
    RemoveDefinitionFlags;
  end;

  FCurrentTagName := cEmptyString;
end;

function THTMLWriter.AddTableData(aText: string): IHTMLWriter;
begin
  CheckInTableRowTag;
  Result := OpenTableData.AddText(aText).CloseTag;
end;

function THTMLWriter.AddTag(aString: string; aCloseTagType: TCloseTagType = ctNormal; aCanAddAttributes: TCanHaveAttributes = chaCanHaveAttributes): IHTMLWriter;
var
  Temp: THTMLWriter;
begin
  CloseBracket;
  Temp := THTMLWriter.Create(aString, aCloseTagType, aCanAddAttributes);
  Temp.FParent := Self.FParent;
  Temp.FTagState := Self.FTagState + [tsBracketOpen];
  Temp.FFormState := Self.FFormState;
  Temp.FTableState := Self.FTableState;
  // take Self tag, add the new tag, and make it the HTML for the return
  Self.HTML.Append(Temp.AsHTML);
  Temp.HTML.Clear;
  Temp.HTML.Append(Self.AsHTML);
  Temp.FParent := Self;
  Result := Temp;
end;

function THTMLWriter.OpenComment: IHTMLWriter;
var
  Temp: THTMLWriter;
  TempStr: string;
begin
  CloseBracket;
  Temp := THTMLWriter.Create(cComment, ctComment, chaCannotHaveAttributes);
  Temp.FParent := Self.FParent;
  Temp.FTagState := Self.FTagState + [tsBracketOpen];
  Temp.FFormState := Self.FFormState;
  Self.HTML.Append(Temp.AsHTML);
  Temp.HTML.Clear;
  TempStr := AsHTML;
  Temp.HTML.Append(TempStr).Append(cSpace);
  Temp.FTagState := Temp.FTagState + [tsCommentOpen];
  Temp.FParent := Self;
  Result := Temp;
end;

function THTMLWriter.OpenCode: IHTMLWriter;
begin
  Result := OpenFormatTag(ftCode);
end;

function THTMLWriter.OpenCol: IHTMLWriter;
begin
  if not TableIsOpen then
  begin
    raise ETableTagNotOpenHTMLWriterException.Create(strCantOpenColOutsideTable);
  end;
  CheckBeforeTableContent;

  Include(FTableState, tbsTableHasCol);

  Result := AddTag(cCol, ctEmpty);
end;

function THTMLWriter.OpenColGroup: IHTMLWriter;
begin
  if not TableIsOpen then
  begin
    raise ETableTagNotOpenHTMLWriterException.Create(strCantOpenCaptionOutsideTable);
  end;

  CheckBeforeTableContent;

  Include(FTableState, tbsTableHasColGroup);

  Result := AddTag(cColGroup);
end;

function THTMLWriter.AsHTML: string;
begin
  Result := FHTML.ToString;
end;

function THTMLWriter.AddTeletypeText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftTeletype);
end;

function THTMLWriter.AddText(aString: string): IHTMLWriter;
begin
  CloseBracket;
  FHTML := FHTML.Append(aString);
  Result := Self;
end;

function THTMLWriter.AddTitle(aTitleText: string): IHTMLWriter;
begin
  CheckInHeadTag;
  Result := OpenTitle.AddText(aTitleText).CloseTag;
end;

function THTMLWriter.AddHardRule(const aAttributes: string = cEmptyString; aUseEmptyTag: TIsEmptyTag = ietIsEmptyTag): IHTMLWriter;
begin
  CloseBracket;
  FHTML := FHTML.Append(cOpenBracket).Append(cHardRule);
  if not StringIsEmpty(aAttributes) then
  begin
    FHTML := FHTML.Append(cSpace).Append(aAttributes);
  end;
  case aUseEmptyTag of
    ietIsEmptyTag:
      FHTML := FHTML.Append(TTagMaker.MakeSlashCloseTag);
    ietIsNotEmptyTag:
      FHTML := FHTML.Append(cCloseBracket);
  end;
  Result := Self;
end;

function THTMLWriter.OpenHead: IHTMLWriter;
var
  Temp: THTMLWriter;
begin
  Temp := THTMLWriter.Create(Self);
  Temp.FParent := Self.FParent;
  Temp.FTagState := Temp.FTagState + [tsInHeadTag];
  Result := Temp.AddTag(cHead, ctNormal, chaCanHaveAttributes);
end;

function THTMLWriter.AddHeading1Text(aString: string): IHTMLWriter;
begin
  Result := AddHeadingText(aString, htHeading1);
end;

function THTMLWriter.AddHeading2Text(aString: string): IHTMLWriter;
begin
  Result := AddHeadingText(aString, htHeading2);
end;

function THTMLWriter.AddHeading3Text(aString: string): IHTMLWriter;
begin
  Result := AddHeadingText(aString, htHeading3);
end;

function THTMLWriter.AddHeading4Text(aString: string): IHTMLWriter;
begin
  Result := AddHeadingText(aString, htHeading4);
end;

function THTMLWriter.AddHeading5Text(aString: string): IHTMLWriter;
begin
  Result := AddHeadingText(aString, htHeading5);
end;

function THTMLWriter.AddHeading6Text(aString: string): IHTMLWriter;
begin
  Result := AddHeadingText(aString, htHeading6);
end;

function THTMLWriter.OpenAnchor: IHTMLWriter;
begin
  Result := AddTag(cAnchor);
end;

function THTMLWriter.OpenAbbreviation: IHTMLWriter;
begin
  Result := OpenFormatTag(ftAbbreviation);
end;

function THTMLWriter.OpenAcronym: IHTMLWriter;
begin
  IsDeprecatedTag(TFormatTypeStrings[ftAcronym], elStrictHTML5);
  Result := OpenFormatTag(ftAcronym);
end;

function THTMLWriter.OpenAddress: IHTMLWriter;
begin
  Result := OpenFormatTag(ftAddress);
end;

function THTMLWriter.OpenAnchor(const aHREF: string; aText: string): IHTMLWriter;
begin
  Result := OpenAnchor.AddAttribute(cHREF, aHREF).AddText(aText);
end;

function THTMLWriter.OpenAnchor(aName: string): IHTMLWriter;
begin
  Result := OpenAnchor[cName, aName];
end;

function THTMLWriter.OpenArea(aAltText: string): IHTMLWriter;
begin
  CheckInMapTag;
  Result := AddTag(cArea, ctEmpty)[cAlt, aAltText];
end;

procedure THTMLWriter.CloseTheTag;
begin
  if TagIsOpen or InCommentTag then
  begin
    if StringIsEmpty(FClosingTag) <> true then
    begin
      FHTML.Append(FClosingTag);
    end;
  end;
end;

function THTMLWriter.OpenBase: IHTMLWriter;
begin
  CheckInHeadTag;
  Result := AddTag(cBase, ctEmpty);
end;

function THTMLWriter.OpenBaseFont: IHTMLWriter;
begin
  IsDeprecatedTag(cBaseFont, elStrictHTML4);
  CheckInHeadTag;
  Result := AddTag(cBaseFont, ctEmpty);
end;

function THTMLWriter.OpenBDO: IHTMLWriter;
begin
  Result := OpenFormatTag(ftBDO);
end;

function THTMLWriter.OpenBig: IHTMLWriter;
begin
  IsDeprecatedTag(TFormatTypeStrings[ftBig], elStrictHTML5);
  Result := OpenFormatTag(ftBig);
end;

function THTMLWriter.OpenBlockQuote: IHTMLWriter;
begin
  Result := AddTag(cBlockQuote, ctNormal, chaCanHaveAttributes);
end;

function THTMLWriter.OpenBody: IHTMLWriter;
begin
  Result := AddTag(cBody, ctNormal, chaCanHaveAttributes);
end;

function THTMLWriter.AddBase(aHREF: string): IHTMLWriter;
begin
  CheckInHeadTag;
  Result := OpenBase.AddAttribute(cHREF, aHREF).CloseTag;
end;

function THTMLWriter.AddBase(aTarget: TTargetType; aFrameName: string = cEmptyString): IHTMLWriter;
begin
  if aTarget = ttFrameName then
  begin
    Result := OpenBase.AddAttribute(cTarget, aFrameName).CloseTag;
  end
  else
  begin
    Result := OpenBase.AddAttribute(cTarget, TTargetTypeStrings[aTarget]).CloseTag;
  end;
end;

function THTMLWriter.AddBDOText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftBDO);
end;

function THTMLWriter.AddBigText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftBig);
end;

function THTMLWriter.AddBlockQuoteText(aString: string): IHTMLWriter;
begin
  Result := AddTag(cBlockQuote, ctNormal, chaCannotHaveAttributes).AddText(aString).CloseTag;
end;

function THTMLWriter.AddBoldText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftBold)
end;

function THTMLWriter.OpenCaption: IHTMLWriter;
var
  Temp: THTMLWriter;
begin
  if not TableIsOpen then
  begin
    raise ETableTagNotOpenHTMLWriterException.Create(strCantOpenCaptionOutsideTable);
  end;
  CheckBeforeTableContent;
  CheckNoOtherTableTags;
  CheckNoColTag;

  Temp := THTMLWriter.Create(Self);
  Temp.FTableState := Temp.FTableState + [tbsTableHasCaption];
  Temp.FParent := Self.FParent;

  Result := Temp.AddTag(cCaption);
end;

function THTMLWriter.AddCenterText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftCenter);
end;

function THTMLWriter.AddCitationText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftCitation);
end;

function THTMLWriter.AddClass(aClass: string): IHTMLWriter;
begin
  Result := AddAttribute(cClass, aClass);
end;

function THTMLWriter.AddCodeText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftCode);
end;

function THTMLWriter.AddComment(aCommentText: string): IHTMLWriter;
begin
  Result := OpenComment.AddText(aCommentText).CloseComment;
end;

function THTMLWriter.AddDefinitionText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftDefinition);
end;

function THTMLWriter.AddDeleteText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftDelete);
end;

function THTMLWriter.AddDivText(aString: string): IHTMLWriter;
begin
  Result := AddTag(TBlockTypeStrings[btDiv], ctNormal, chaCannotHaveAttributes).AddText(aString).CloseTag;
end;

function THTMLWriter.AddDivTextWithClass(aString, aClass: string): IHTMLWriter;
begin
  Result := OpenDiv.AddClass(aClass).AddText(aString).CloseTag();
end;

function THTMLWriter.AddDivTextWithID(aString, aID: string): IHTMLWriter;
begin
  Result := OpenDiv.AddID(aID).AddText(aString).CloseTag;
end;

function THTMLWriter.AddDivTextWithStyle(aString, aStyle: string): IHTMLWriter;
begin
  Result := OpenDiv.AddStyle(aStyle).AddText(aString).CloseTag;
end;

function THTMLWriter.AddEmphasisText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftEmphasis)
end;

function THTMLWriter.AddSampleText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftSample);
end;

function THTMLWriter.AddScript(aScriptText: string): IHTMLWriter;
begin
  Result := OpenScript.AddText(aScriptText).CloseTag;
end;

function THTMLWriter.AddSmallText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftSmall);
end;

function THTMLWriter.AddSpanText(aString: string): IHTMLWriter;
begin
  Result := AddTag(TBlockTypeStrings[btSpan], ctNormal, chaCannotHaveAttributes).AddText(aString).CloseTag;
end;

function THTMLWriter.AddSpanTextWithClass(aString, aClass: string): IHTMLWriter;
begin
  Result := OpenSpan.AddClass(aClass).AddText(aString).CloseTag();
end;

function THTMLWriter.AddSpanTextWithID(aString, aID: string): IHTMLWriter;
begin
  Result := OpenSpan.AddID(aID).AddText(aString).CloseTag;
end;

function THTMLWriter.AddSpanTextWithStyle(aString, aStyle: string): IHTMLWriter;
begin
  Result := OpenSpan.AddStyle(aStyle).AddText(aString).CloseTag;
end;

function THTMLWriter.AddStrikeText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftStrike);
end;

function THTMLWriter.AddStrongText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftStrong)
end;

function THTMLWriter.AddUnderlinedText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftUnderline)
end;

function THTMLWriter.AddVariableText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftVariable)
end;

function THTMLWriter.AddID(aID: string): IHTMLWriter;
begin
  Result := AddAttribute(cID, aID);
end;

function THTMLWriter.AddIFrame(aURL, aAlternateText: string): IHTMLWriter;
begin
  Result := OpenIFrame(aURL).AddText(aAlternateText).CloseTag;
end;

function THTMLWriter.AddIFrame(aURL, aAlternateText: string; aWidth: THTMLWidth; aHeight: integer): IHTMLWriter;
begin
  Result := OpenIFrame(aURL, aWidth, aHeight).AddText(aAlternateText).CloseTag;
end;

function THTMLWriter.AddItalicText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftItalic)
end;

function THTMLWriter.AddKeyboardText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftKeyboard)
end;

function THTMLWriter.AddLegend(aText: string): IHTMLWriter;
begin
  Result := OpenLegend.AddText(aText).CloseTag;
end;

function THTMLWriter.AddLineBreak(const aClearValue: TClearValue = cvNoValue; aUseEmptyTag: TIsEmptyTag = ietIsEmptyTag): IHTMLWriter;
begin
  CloseBracket;
  FHTML := FHTML.Append(cOpenBracket).Append(cBreak);
  if aClearValue <> cvNoValue then
  begin
    FHTML := FHTML.Append(cSpace).AppendFormat('%s="%s"', [cClear, TClearValueStrings[aClearValue]]);
  end;
  case aUseEmptyTag of
    ietIsEmptyTag:
      FHTML := FHTML.Append(TTagMaker.MakeSlashCloseTag);
    ietIsNotEmptyTag:
      FHTML := FHTML.Append(cCloseBracket);
  end;
  Result := Self;
end;

function THTMLWriter.AddListItem(aText: string): IHTMLWriter;
begin
  Result := OpenListItem.AddText(aText).CloseTag;
end;

procedure THTMLWriter.CheckBeforeTableContent;
begin
  if CheckForErrors and HasTableContent then
  begin
    raise EBadTagAfterTableContentHTMLWriter.Create(strBadTagAfterTableContent);
  end;
end;

procedure THTMLWriter.CheckBracketOpen(aString: string);
begin
  if (not(tsBracketOpen in FTagState)) and CheckForErrors then
  begin
    raise EOpenTagRequiredHTMLWriterException.CreateFmt(StrATagsBracketMust, [Self.FCurrentTagName, aString]);
  end;
end;

procedure THTMLWriter.CheckInTableTag;
begin
  if (not InTableTag) and CheckForErrors then
  begin
    raise ENotInTableTagException.Create(strMustBeInTable);
  end;
end;

procedure THTMLWriter.CheckNoOtherTableTags;
begin
  // At this point, FTableState must be exactly [tbsInTable] and nothing else....
  // Note that this means that InTableTag won't work here..
  if CheckForErrors and (not(FTableState = [tbsInTable])) then
  begin
    raise ECaptionMustBeFirstHTMLWriterException.Create(strCaptionMustBeFirst);
  end;
end;

procedure THTMLWriter.CheckNoColTag;
begin
  if CheckForErrors and (TableHasColTag) then
  begin
    raise ECaptionMustBeFirstHTMLWriterException.Create(strCaptionMustBeFirst);
  end;
end;

procedure THTMLWriter.CheckInTableRowTag;
begin
  if (not InTableRowTag) and CheckForErrors then
  begin
    raise ENotInTableTagException.Create(strMustBeInTableRow);
  end;
end;

procedure THTMLWriter.CheckInListTag;
begin
  if (not InListTag) and CheckForErrors then
  begin
    raise ENotInListTagException.Create(strMustBeInList);
  end;
end;

procedure THTMLWriter.CheckInMapTag;
begin
  if (not InMapTag) and CheckForErrors then
  begin
    raise ENotInMapTagHTMLException.Create(strNotInMapTag);
  end;
end;

procedure THTMLWriter.CheckInObjectTag;
begin
  if (not InObjectTag) and CheckForErrors then
  begin
    raise ENotInObjectTagException.Create(strMustBeInObject);
  end;
end;

procedure THTMLWriter.CheckInSelectTag;
begin
  if (not InSelectTag) and CheckForErrors then
  begin
    raise ENotInSelectTextHTMLWriterException.Create(strMustBeInSelectTag);
  end;
end;

procedure THTMLWriter.CheckIfNestedDefList;
begin
  if InDefList and CheckForErrors then
  begin
    raise ECannotNestDefinitionListsHTMLWriterException.Create(strCannotNestDefLists);
  end;
end;

procedure THTMLWriter.CheckInCommentTag;
begin
  if (not InCommentTag) and CheckForErrors then
  begin
    raise ENotInCommentTagException.Create(strMustBeInComment);
  end;
end;

procedure THTMLWriter.CheckInDefList;
begin
  if (not InDefList) and CheckForErrors then
  begin
    raise ENotInDefinitionListHTMLError.Create(strMustBeInDefinitionList);
  end;
end;

procedure THTMLWriter.CheckInFieldSetTag;
begin
  if (not InFieldSetTag) and CheckForErrors then
  begin
    raise ENotInFieldsetTagException.Create(strNotInFieldTag);
  end;
end;

procedure THTMLWriter.CheckCurrentTagIsHTMLTag;
begin
  if (FCurrentTagName <> cHTML) and CheckForErrors then
  begin
    raise EClosingDocumentWithOpenTagsHTMLException.Create(strOtherTagsOpen);
  end;
end;

procedure THTMLWriter.CheckDefItemIsCurrent;
begin
  if CheckForErrors and (not (tsDefItemIsCurrent in FTagState)) then
  begin
    raise ECannotAddDefItemWithoutDefTermHTMLWriterException.Create(strCannotAddDefItemWithoutDefTerm);
  end;
end;

procedure THTMLWriter.CheckDefTermIsCurrent;
begin
  if CheckForErrors and (not (tsDefTermIsCurrent in FTagState)) then
  begin
    raise ECannotAddDefItemWithoutDefTermHTMLWriterException.Create(strCannotAddDefItemWithoutDefTerm);
  end;
end;

function THTMLWriter.CheckForErrors: Boolean;
begin
  Result := elErrors in ErrorLevels;
end;

procedure THTMLWriter.CheckInFormTag;
begin
  if CheckForErrors then
  begin
  end;
end;

procedure THTMLWriter.CheckInFramesetTag;
begin
  if (not InFrameSetTag) and CheckForErrors then
  begin
    raise ENotInFrameSetHTMLException.Create(strNotInFrameSet);
  end;
end;

procedure THTMLWriter.CheckInHeadTag;
begin
  if (not InHeadTag) and CheckForErrors then
  begin
    raise EHeadTagRequiredHTMLException.Create(strAMetaTagCanOnly);
  end;
end;

function THTMLWriter.AddMetaNamedContent(aName, aContent: string): IHTMLWriter;
begin
  CheckInHeadTag;
  Result := AddAttribute(cName, aName).AddAttribute(cContent, aContent);
end;

function THTMLWriter.AddParagraphText(aString: string): IHTMLWriter;
begin
  Result := AddTag(TBlockTypeStrings[btParagraph], ctNormal, chaCannotHaveAttributes).AddText(aString).CloseTag;
end;

function THTMLWriter.AddParagraphTextWithClass(aString, aClass: string): IHTMLWriter;
begin
  Result := OpenParagraph.AddClass(aClass).AddText(aString).CloseTag();
end;

function THTMLWriter.AddParagraphTextWithID(aString, aID: string): IHTMLWriter;
begin
  Result := OpenParagraph.AddID(aID).AddText(aString).CloseTag;
end;

function THTMLWriter.AddParagraphTextWithStyle(aString, aStyle: string): IHTMLWriter;
begin
  Result := OpenParagraph.AddStyle(aStyle).AddText(aString).CloseTag;
end;

function THTMLWriter.AddPreformattedText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftPreformatted)
end;

function THTMLWriter.AddQuotationText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftQuotation)
end;

function THTMLWriter.AddRawText(aString: string): IHTMLWriter;
begin
  FHTML := FHTML.Append(aString);
  Result := Self;
end;

function THTMLWriter.OpenParagraphWithID(aID: string): IHTMLWriter;
begin
  Result := OpenParagraph.AddID(aID);
end;

function THTMLWriter.OpenParagraph: IHTMLWriter;
begin
  Result := AddTag(TBlockTypeStrings[btParagraph], ctNormal, chaCanHaveAttributes);
end;

function THTMLWriter.OpenParagraphWithStyle(aStyle: string): IHTMLWriter;
begin
  Result := OpenParagraph.AddStyle(aStyle);
end;

function THTMLWriter.OpenParam(aName: string; aValue: string = cEmptyString): IHTMLWriter;
begin
  CheckInObjectTag;
  if StringIsEmpty(aName) then
  begin
    raise EParamNameRequiredHTMLWriterException.Create(strParamNameRequired);
  end;
  Result := AddTag(cParam)[cName, aName];
  if StringIsNotEmpty(aValue) then
  begin
    Result := Result[cValue, aValue];
  end;
end;

function THTMLWriter.OpenPre: IHTMLWriter;
begin
  Result := OpenFormatTag(ftPreformatted);
end;

function THTMLWriter.OpenQuotation: IHTMLWriter;
begin
  Result := OpenFormatTag(ftQuotation);
end;

function THTMLWriter.OpenSample: IHTMLWriter;
begin
  Result := OpenFormatTag(ftSample);
end;

function THTMLWriter.OpenScript: IHTMLWriter;
begin
  Result := AddTag(cScript);
end;

function THTMLWriter.OpenSelect(aName: string): IHTMLWriter;
begin
  CheckInFormTag;
  Include(FFormState, fsInSelect);
  Result := AddTag(cSelect)[cName, aName];
end;

function THTMLWriter.OpenSmall: IHTMLWriter;
begin
  Result := OpenFormatTag(ftSmall);
end;

function THTMLWriter.OpenSpan: IHTMLWriter;
begin
  Result := AddTag(TBlockTypeStrings[btSpan], ctNormal, chaCanHaveAttributes);
end;

function THTMLWriter.AddStyle(aStyle: string): IHTMLWriter;
begin
  Result := AddAttribute(cStyle, aStyle);
end;

function THTMLWriter.OpenDefinition: IHTMLWriter;
begin
  Result := OpenFormatTag(ftDefinition);
end;

function THTMLWriter.OpenDefinitionList: IHTMLWriter;
begin
  CheckIfNestedDefList;
  Include(FTagState, tsInDefinitionList);
  Result := AddTag(cDL);
end;

function THTMLWriter.OpenDefinitionTerm: IHTMLWriter;
var
  Temp: THTMLWriter;
begin
  CheckInDefList;
  Temp := THTMLWriter.Create(Self);
  Temp.FParent := Self.FParent;
  Include(Temp.FTagState, tsDefTermIsCurrent);
  Result := Temp.AddTag(cDT);
end;

function THTMLWriter.OpenDefinitionItem: IHTMLWriter;
begin
  try
    CheckDefTermIsCurrent;
  except
    on E: ECannotAddDefItemWithoutDefTermHTMLWriterException do
    begin
      CheckDefItemIsCurrent;
    end;
  end;
  Exclude(FTagState, tsDefTermIsCurrent);
  Include(FTagState, tsDefItemIsCurrent);
  Result := AddTag(cDD);
end;

function THTMLWriter.OpenDelete: IHTMLWriter;
begin
  Result := OpenFormatTag(ftDelete);
end;

function THTMLWriter.OpenDiv: IHTMLWriter;
begin
  Result := AddTag(TBlockTypeStrings[btDiv], ctNormal, chaCanHaveAttributes);
end;

function THTMLWriter.AddFontText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftFont);
end;

function THTMLWriter.AddFormattedText(aString: string; aFormatType: TFormatType): IHTMLWriter;
begin
  Result := AddTag(TFormatTypeStrings[aFormatType], ctNormal, chaCannotHaveAttributes).AddText(aString).CloseTag;
end;

function THTMLWriter.AddHeadingText(aString: string; aHeadingType: THeadingType): IHTMLWriter;
begin
  Result := AddTag(THeadingTypeStrings[aHeadingType], ctNormal, chaCannotHaveAttributes).AddText(aString).CloseTag;
end;

function THTMLWriter.AddAbbreviationText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftAbbreviation);
end;

function THTMLWriter.AddAcronymText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftAcronym);
end;

function THTMLWriter.AddAddressText(aString: string): IHTMLWriter;
begin
  Result := AddFormattedText(aString, ftAddress);
end;

function THTMLWriter.AddAnchor(const aHREF: string; aText: string): IHTMLWriter;
begin
  Result := OpenAnchor[cHREF, aHREF].AddText(aText).CloseTag;
end;

function THTMLWriter.AddAttribute(aString: string; aValue: string = cEmptyString): IHTMLWriter;
begin
  CheckBracketOpen(aString);
  FHTML := FHTML.Append(cSpace).Append(aString);
  if aValue <> cEmptyString then
  begin
    FHTML := FHTML.Append(Format('="%s"', [aValue]));
  end;
  Result := Self;
end;

// Interface Access functions

function HTMLWriterCreateDocument: IHTMLWriter;
begin
  Result := THTMLWriter.CreateDocument;
end;

function HTMLWriterCreate(aTagName: string = ''; aCloseTagType: TCloseTagType = ctNormal; aCanAddAttributes: TCanHaveAttributes = chaCanHaveAttributes): IHTMLWriter;
begin
  Result := THTMLWriter.Create(aTagName, aCloseTagType, aCanAddAttributes);
end;

function HTMLWriterCreateDocument(aDocType: THTMLDocType): IHTMLWriter; overload;
begin
  Result := THTMLWriter.CreateDocument(aDocType);
end;

end.

