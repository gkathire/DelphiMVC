 unit HTMLWriterIntf;
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
      HTMLWriterUtils
    , Classes
    , SysUtils
    , LoadSaveIntf
    ;

type
  /// <summary>An interface for creating HTML.  IHTMLWriter uses the fluent interface. It can be used to create either
  /// complete HTML documents or chunks of HTML.  By using the fluent interface, you can link together number of methods
  /// to create a complete document.</summary>
  /// <remarks>
  /// <para>Most methods begin with either "Open" or "Add". Methods that start with "Open" will
  /// add  &lt;tag  to the HTML stream, leaving it ready for the addition of attributes or other content. The
  /// system will automatically close the tag when necessary.</para>
  /// <para>Methods that start with "Add" will normally take paramenters and then add content within a complete tag
  /// pair. For example, a call to AddBoldText('blah') will result in  &lt;b&gt;blah&lt;/b&gt;  being added to
  /// the HTML stream.</para>
  /// <para>Some things to note:</para>
  /// <list type="bullet">
  /// <item>Any tag that is opened will need to be closed via  CloseTag</item>
  /// <item>Any tag that is added via a  AddXXXX  call will close itself.</item>
  /// <item>The rule to follow: Close what you open. Additions take care of themselves.</item>
  /// <item>Certain tags like  &lt;meta&gt;  and  &lt;base&gt;  can only be added inside
  /// at  &lt;head&gt;  tag.</item>
  /// <item>Tags such as  &lt;td&gt;,  &lt;tr&gt;  can only be added inside of
  /// a  &lt;table&gt;  tag.</item>
  /// <item>The same is true for list items inside lists.</item>
  /// </list>
  /// </remarks>
  IHTMLWriter = interface(ILoadSave)
  ['{7D6CC975-3FAB-453C-8BAB-45D6E55DE376}']
    function GetAttribute(const Name, Value: string): IHTMLWriter;
    function GetErrorLevels: THTMLErrorLevels;
    procedure SetErrorLevels(const Value: THTMLErrorLevels);
    function GetHTML: TStringBuilder;
    function AddTag(aString: string; aCloseTagType: TCloseTagType = ctNormal; aCanAddAttributes: TCanHaveAttributes = chaCanHaveAttributes): IHTMLWriter;
    /// <summary>Opens a&lt;head&gt; tag to the document.  </summary>
    function OpenHead: IHTMLWriter;
    /// <summary>Opens a &lt;meta&gt; tag.</summary>
    /// <exception cref="EHeadTagRequiredHTMLException">Raised if an attempt is made  to call this method
    /// when not inside a &lt;head&gt; tag.</exception>
    /// <remarks>Note that this method can only be called from within &lt;head&gt; tag.   If it is called from
    /// anywhere else, it will raise an exception.</remarks>
    function OpenMeta: IHTMLWriter;
    /// <summary>Opens a &lt;base /&gt; tag.</summary>
    /// <exception cref="EHeadTagRequiredHTMLException">Raised if this tag is added outside of the &lt;head&gt;
    /// tag.</exception>
    /// <remarks>This tag will always be closed with the '/&gt;' tag. In addition, this tag can only be added inside of
    /// a &lt;head&gt; tag.</remarks>
    function OpenBase: IHTMLWriter;
    function OpenBaseFont: IHTMLWriter;
    ///	<summary>Adds a &lt;base /&gt; tag to the HTML.</summary>
    ///	<remarks>Note: This method can only be called inside an open &lt;head&gt; tag.</remarks>
    function AddBase(aTarget: TTargetType; aFrameName: string = ''): IHTMLWriter; overload;
    ///	<summary>Creates a &lt;base&gt; tag with an HREF="" attribute.</summary>
    ///	<param name="aHREF">The HREF to be added to the &lt;base&gt; tag as an attribute.</param>
    function AddBase(aHREF: string): IHTMLWriter; overload;
    /// <summary>Opens a &lt;title&gt; tag.</summary>
    function OpenTitle: IHTMLWriter;
    /// <summary>Adds a &lt;title&gt; tag including the passed in text.</summary>
    /// <param name="aTitleText">The text to be placed inside the &lt;title&gt;&lt;/title&gt; tag</param>
    /// <remarks>There is no need to close this tag manually.   All "AddXXXX" methods close themselves.</remarks>
    function AddTitle(aTitleText: string): IHTMLWriter;
    function AddMetaNamedContent(aName: string; aContent: string): IHTMLWriter;
    /// <summary>Opens a &lt;body&gt; tag.</summary>
    function OpenBody: IHTMLWriter;
   /// <summary>Opens a &lt;p&gt; tag.  </summary>
    function OpenParagraph: IHTMLWriter;
    /// <summary>Opens a &lt;p&gt; tag and gives it the passed in style="" attribute</summary>
    /// <param name="aStyle">The CSS-based text to be included in the style attribute for the &lt;p&gt; tag.</param>
    function OpenParagraphWithStyle(aStyle: string): IHTMLWriter;
    function OpenParagraphWithID(aID: string): IHTMLWriter;
    /// <summary>Opens a &lt;span&gt; tag.</summary>
    function OpenSpan: IHTMLWriter;
    /// <summary>Opens a &lt;div&gt; tag.</summary>
    function OpenDiv: IHTMLWriter;
    /// <summary>Opens a &lt;blockquote&gt; tag.</summary>
    function OpenBlockQuote: IHTMLWriter;
    /// <summary>Adds the passed in text to the HTML inside of a &lt;p&gt; tag.</summary>
    /// <param name="aString">The text to be added into the &lt;p&gt; tag.</param>
    function AddParagraphText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text into a &lt;p&gt; tag and adds in the given Style attribute.</summary>
    /// <param name="aString">The text to be added within the &lt;p&gt; tag.</param>
    /// <param name="aStyle">The value for the Style attribute  to be added to the &lt;p&gt; tag.</param>
    function AddParagraphTextWithStyle(aString: string; aStyle: string): IHTMLWriter;
    function AddParagraphTextWithID(aString: string; aID: string): IHTMLWriter;
    function AddParagraphTextWithClass(aString: string; aClass: string): IHTMLWriter;
    /// <summary>Adds text inside of a &lt;span&gt; tag.</summary>
    /// <param name="aString">The text to be added inside of the &lt;span&gt;&lt;/span&gt; tag.</param>
    function AddSpanText(aString: string): IHTMLWriter;
    function AddSpanTextWithStyle(aString: string; aStyle: string): IHTMLWriter;
    function AddSpanTextWithID(aString: string; aID: string): IHTMLWriter;
    function AddSpanTextWithClass(aString: string; aID: string): IHTMLWriter;
    ///	<summary>Adds the passed in text to a &lt;div&gt;&lt;/div&gt; tag.</summary>
    ///	<param name="aString">The text to be added inside the &lt;div&gt;&lt;/div&gt; tag</param>
    function AddDivText(aString: string): IHTMLWriter;
    ///	<summary>Creates a &lt;div&gt; tag with a "style=" attribute.</summary>
    ///	<param name="aString">The text to be placed in the &lt;div&gt; tag.</param>
    ///	<param name="aStyle">A string representing the CSS style information for the &lt;div&gt; tag.</param>
    function AddDivTextWithStyle(aString: string; aStyle: string): IHTMLWriter;
    ///	<summary>Creates a &lt;div&gt; tag with a "id=" attribute.</summary>
    ///	<param name="aString">The text to be placed in the &lt;div&gt; tag.</param>
    ///	<param name="aID">As string containing the id value for the &lt;div&gt; tag.</param>
    function AddDivTextWithID(aString: string; aID: string): IHTMLWriter;
    ///	<summary>Creates a &lt;div&gt; tag with a "class=" attribute.</summary>
    ///	<param name="aString">The text to be placed in the &lt;div&gt; tag.</param>
    ///	<param name="aID">As string containing the class value for the &lt;div&gt; tag.</param>
    function AddDivTextWithClass(aString: string; aClass: string): IHTMLWriter;
    /// <summary>Opens up a &lt;b&gt; tag. Once a tag is open, it can be added to as desired.</summary>
    function OpenBold: IHTMLWriter;
    /// <summary>Opens up a &lt;i&gt; tag. Once a tag is open, it can be added to as desired.</summary>
    function OpenItalic: IHTMLWriter;
    /// <summary>Opens up a &lt;u&gt; tag. Once a tag is open, it can be added to as desired.</summary>
    function OpenUnderline: IHTMLWriter;
    /// <summary>Opens a &lt;em&gt; tag.</summary>
    function OpenEmphasis: IHTMLWriter;
    /// <summary>Opens a &lt;strong&gt; tag.</summary>
    function OpenStrong: IHTMLWriter;
    /// <summary>Opens a &lt;pre&gt; tag.</summary>
    function OpenPre: IHTMLWriter;
    /// <summary>Opens a &lt;cite&gt; tag.</summary>
    function OpenCite: IHTMLWriter;
    /// <summary>Opens a &lt;acronym&gt; tag.</summary>
    function OpenAcronym: IHTMLWriter;
    /// <summary>Opens an &lt;abbr&gt; tag.</summary>
    function OpenAbbreviation: IHTMLWriter;
    /// <summary>Opens an &lt;addr&gt; tag</summary>
    function OpenAddress: IHTMLWriter;
    /// <summary>Opens a &lt;bdo&gt; tag.</summary>
    function OpenBDO: IHTMLWriter;
    /// <summary>Opens a &lt;big&gt; tag.</summary>
    function OpenBig: IHTMLWriter;
    /// <summary>Opens a &lt;center&gt; tag.</summary>
    function OpenCenter: IHTMLWriter;
    /// <summary>Opens a &lt;code&gt; tag.</summary>
    function OpenCode: IHTMLWriter;
    /// <summary>Opens a &lt;delete&gt; tag.</summary>
    function OpenDelete: IHTMLWriter;
    /// <summary>Opens a &lt;dfn&gt; tag.</summary>
    function OpenDefinition: IHTMLWriter;
    /// <summary>Opens a &lt;font&gt; tag.</summary>
    function OpenFont: IHTMLWriter;
    /// <summary>Opens a &lt;kbd&gt; tag</summary>
    function OpenKeyboard: IHTMLWriter;
    /// <summary>Opens a &lt;q&gt; tag.  </summary>
    function OpenQuotation: IHTMLWriter;
    /// <summary>Opens a &lt;sample&gt; tag.</summary>
    function OpenSample: IHTMLWriter;
    /// <summary>Opens a &lt;small&gt; tag.</summary>
    function OpenSmall: IHTMLWriter;
    /// <summary>Opens a &lt;strike&gt; tag.</summary>
    function OpenStrike: IHTMLWriter;
    /// <summary>Opens a &lt;tt&gt; tag.</summary>
    function OpenTeletype: IHTMLWriter;
    /// <summary>Opens a &lt;var&gt; tag.</summary>
    function OpenVariable: IHTMLWriter;
    /// <summary>Opens a &lt;ins&gt; tag.</summary>
    function OpenInsert: IHTMLWriter;
    /// <summary>Adds a &lt;b&gt;&lt;/b&gt; containing the passed text</summary>
    /// <param name="aString">The text to be placed within the bold tag.</param>
    function AddBoldText(aString: string): IHTMLWriter;
    /// <summary>Adds a &lt;i&gt;&lt;/i&gt; containing the passed text</summary>
    /// <param name="aString">The text to be placed within the italic tag.</param>
    function AddItalicText(aString: string): IHTMLWriter;
    /// <summary>Adds a &lt;u&gt;&lt;/u&gt; containing the passed text</summary>
    /// <param name="aString">The text to be placed within the underline tag.</param>
    function AddUnderlinedText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed text inside of a &lt;em&gt;&lt;/em&gt; tag</summary>
    /// <param name="aString">The text to be added inside the Emphasis tag.</param>
    function AddEmphasisText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;strong&gt;&lt;/strong&gt; tag.</summary>
    /// <param name="aString">The text to be added to the strong tag.</param>
    function AddStrongText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;pre&gt;&lt;/pre&gt; tag</summary>
    /// <param name="aString">The text to be added inside a preformatted tag</param>
    function AddPreformattedText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;cite&lt;&lt;/cite&gt; tag</summary>
    /// <param name="aString">The text to be added inside the Citation tag.</param>
    function AddCitationText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text inside of a &lt;blockquote&gt;&lt;/blockquote&gt; tag.</summary>
    /// <param name="aString">The text to be included inside the block quote tag.</param>
    function AddBlockQuoteText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to an &lt;acronym&gt;&lt;/acronym&gt; tag.</summary>
    /// <param name="aString">The string that will be included in the Acronym tag.</param>
    function AddAcronymText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text inside a &lt;abbr&gt;&lt;/abbr&gt; tag.</summary>
    /// <param name="aString">The text to be added inside the Abbreviation tag.</param>
    function AddAbbreviationText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;addr&gt;&lt;/addr&gt; tag.</summary>
    /// <param name="aString">The text to be included in the Address tag.</param>
    function AddAddressText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;bdo&gt;&lt;/bdo&gt; tag.</summary>
    /// <param name="aString">The text to be added inside the Bi-Directional tag.</param>
    function AddBDOText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;big&gt;&lt;/big&gt; tag.</summary>
    /// <param name="aString">The text to eb added to the Big tag.</param>
    function AddBigText(aString: string): IHTMLWriter;
    /// <summary>Addes the passed in text to a &lt;center&gt;&lt;/center&gt; tag.</summary>
    /// <param name="aString">The text to be added to the Center tag.</param>
    function AddCenterText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;code&gt;&lt;/code&gt; tag.</summary>
    /// <param name="aString">The text to be added to the Code tag.</param>
    function AddCodeText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;delete&gt;&lt;/delete&gt; tag.</summary>
    /// <param name="aString">The text to be added to the Delete tag.</param>
    function AddDeleteText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;dfn&gt;&lt;/dfn&gt; tag.</summary>
    /// <param name="aString">The text to be added inside of the Definition tag.</param>
    function AddDefinitionText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;font&gt;&lt;/font&gt; tag.</summary>
    /// <param name="aString">The text to be included in the Font tag.</param>
    function AddFontText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;kbd&gt;&lt;/kbd&gt; tag.</summary>
    /// <param name="aString">The text to be added to the Keyboard tag.</param>
    function AddKeyboardText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;q&gt;&lt;/q&gt; tag</summary>
    /// <param name="aString">The string that will be included inside the quotation tag.</param>
    function AddQuotationText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;samp&gt;&lt;/samp&gt; tag.</summary>
    /// <param name="aString">The text to be inserted into the sample tag.</param>
    function AddSampleText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;small&gt;&lt;/small&gt; tag</summary>
    /// <param name="aString">The text to be included in a small tag.</param>
    function AddSmallText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text inside a &lt;strike&gt;&lt;/strike&gt; tag</summary>
    /// <param name="aString">The text to be included in the strike tag.</param>
    function AddStrikeText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;tt&gt;&lt;/tt&gt; tag.</summary>
    /// <param name="aString">The text to be added into the teletype tag.</param>
    function AddTeletypeText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;var&gt;&lt;/var&gt; tag</summary>
    /// <param name="aString">The text to be passed to the variable tag.</param>
    function AddVariableText(aString: string): IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;ins&gt;&lt;/ins&gt; tag</summary>
    /// <param name="aString">The text to be passed to the insert tag.</param>
    function AddInsertText(aString: string): IHTMLWriter;
    /// <summary>Opens a &lt;h1&gt; tag.</summary>
    function OpenHeading1: IHTMLWriter;
    /// <summary>Opens a &lt;h2&gt; tag.</summary>
    function OpenHeading2: IHTMLWriter;
    /// <summary>Opens a &lt;h3&gt; tag.</summary>
    function OpenHeading3: IHTMLWriter;
    /// <summary>Opens a &lt;h4&gt; tag.</summary>
    function OpenHeading4: IHTMLWriter;
    /// <summary>Opens a &lt;h5&gt; tag.</summary>
    function OpenHeading5: IHTMLWriter;
    /// <summary>Opens a &lt;h6&gt; tag.</summary>
    function OpenHeading6: IHTMLWriter;
    /// <summary>Inserts a &lt;h1&gt;&lt;/h1&gt; tag and places the given text in it.</summary>
    /// <param name="aString">The text to be placed inside the heading tag.</param>
    function AddHeading1Text(aString: string): IHTMLWriter;
    /// <summary>Inserts a &lt;h2&gt;&lt;/h2&gt; tag and places the given text in it.</summary>
    /// <param name="aString">The text to be placed inside the heading tag.</param>
    function AddHeading2Text(aString: string): IHTMLWriter;
    /// <summary>Inserts a &lt;h3&gt;&lt;/h3&gt; tag and places the given text in it.</summary>
    /// <param name="aString">The text to be placed inside the heading tag.</param>
    function AddHeading3Text(aString: string): IHTMLWriter;
    /// <summary>Inserts a &lt;h4&gt;&lt;/h4&gt; tag and places the given text in it.</summary>
    /// <param name="aString">The text to be placed inside the heading tag.</param>
    function AddHeading4Text(aString: string): IHTMLWriter;
    /// <summary>Inserts a &lt;h5&gt;&lt;/h5&gt; tag and places the given text in it.</summary>
    /// <param name="aString">The text to be placed inside the heading tag.</param>
    function AddHeading5Text(aString: string): IHTMLWriter;
    /// <summary>Inserts a &lt;h6&gt;&lt;/h6&gt; tag and places the given text in it.</summary>
    /// <param name="aString">The text to be placed inside the heading tag.</param>
    function AddHeading6Text(aString: string): IHTMLWriter;
    ///	<summary>Addes a style="" attribute to the current HTML.</summary>
    ///	<param name="aStyle">The string that contains the styling information in CSS format.</param>
    ///	<exception cref="EHTMLWriterOpenTagRequiredException">Raised if this method is called while a tag is not open.</exception>
    ///	<remarks>This method can only be called when a tag is open and ready to take attributes.</remarks>
    function AddStyle(aStyle: string): IHTMLWriter;
    ///	<summary>Adds a class="" attribute to the current tag.</summary>
    ///	<param name="aClass">The name of the class to be added in the attribute.</param>
    ///	<exception cref="EHTMLWriterOpenTagRequiredException">Raised if this method is called while a tag is not open.</exception>
    ///	<remarks>This method can only be called when a tag is open and ready to take attributes.</remarks>
    function AddClass(aClass: string): IHTMLWriter;
    ///	<summary>Adds an id="" attribute to the current tag.</summary>
    ///	<param name="aID">The string containing the ID to be included with the attribute.</param>
    ///	<exception cref="EHTMLWriterOpenTagRequiredException">Raised if this method is called while a tag is not open.</exception>
    ///	<remarks>This method can only be called when a tag is open and ready to take attributes.</remarks>
    function AddID(aID: string): IHTMLWriter;
    /// <summary>Adds an attribute to the current tag.   The tag must have its bracket open.  </summary>
    /// <param name="aString">The name of the attribute to be added.   If this is the only parameter passed in,
    /// then this string should contain the entire attribute string.</param>
    /// <param name="aValue">Optional parameter.   If this value is passed, then the first parameter become the
    /// <i>name</i>, and this one the <i>value</i>, in a <i>name=value</i> pair.</param>
    /// <exception cref="EHTMLWriterOpenTagRequiredException">Raised when this method is called on a tag that doesn't
    /// have it's bracket open.</exception>
    function AddAttribute(aString: string; aValue: string = ''): IHTMLWriter;
    /// <summary>Adds a &lt;br /&gt; tag</summary>
    /// <param name="aClearValue">An optional parameter that determines if a clear attribute will be added.   The
    /// default value is not to include the clear attribute.</param>
    /// <param name="aUseCloseSlash">An optional parameter that determines if the tag will close with a /&gt;.
    /// The default is to do so.</param>
    function AddLineBreak(const aClearValue: TClearValue = cvNoValue; aUseEmptyTag: TIsEmptyTag = ietIsEmptyTag): IHTMLWriter;
    /// <summary>Adds an &lt;hr&gt; tag to the HTML</summary>
    /// <param name="aAttributes">Attributes that should be added to the &lt;hr&gt; tag.</param>
    /// <param name="aUseEmptyTag">Determines if the &lt;hr&gt; tag should be rendered as &lt;hr /&gt;</param>
    function AddHardRule(const aAttributes: string = ''; aUseEmptyTag: TIsEmptyTag = ietIsEmptyTag): IHTMLWriter;
    /// <summary>Adds a Carriage Return and a Line Feed to the HTML.</summary>
    function CRLF: IHTMLWriter;
    /// <summary>Adds spaces to the HTML stream</summary>
    /// <param name="aNumberofSpaces">An integer indicating how many spaces should be added to the HTML.</param>
    function Indent(aNumberofSpaces: integer): IHTMLWriter;
    /// <summary>Opens a &lt;comment&gt; tag</summary>
    function OpenComment: IHTMLWriter;
    /// <summary>Adds any text to the HTML.  </summary>
    /// <param name="aString">The string to be added</param>
    /// <remarks>AddText will close the current tag and then add the text passed in the string parameter</remarks>
    function AddText(aString: string): IHTMLWriter;
    /// <summary>AddRawText will inject the passed in string directly into the HTML.  </summary>
    /// <param name="aString">The text to be added to the HTML</param>
    /// <remarks>AddRawText  will not make any other changes to open tags or open brackets.   It just injects
    /// the passed text directly onto the HTML.</remarks>
    function AddRawText(aString: string): IHTMLWriter;
    /// <summary>Returns a string containing the current HTML for the
    /// HTMLWriter</summary>
    /// <remarks>This property will return the HTML in whatever state it is
    /// in when called.   This may mean that brackets or even tags are
    /// open, attributes hanging undone, etc.  </remarks>
    function AsHTML: string;
    /// <summary>Adds a comment to the HTML stream</summary>
    /// <param name="aCommentText">The text to be added inside the comment</param>
    function AddComment(aCommentText: string): IHTMLWriter;
    /// <summary>Opens a &lt;script&gt; tag</summary>
    function OpenScript: IHTMLWriter;
    /// <summary>Adds the passed in script text to a &lt;script&gt;&lt;/script&gt; tag.</summary>
    /// <param name="aScriptText">The script text to be added inside the Script tag.</param>
    function AddScript(aScriptText: string): IHTMLWriter;
    ///	<summary>Opens a &lt;noscript&gt; tag</summary>
    function OpenNoScript: IHTMLWriter;
    /// <summary>Opens a &lt;link /&gt; tag.</summary>
    function OpenLink: IHTMLWriter;
    /// <summary>Closes an open tag.</summary>
    /// <param name="aUseCRLF">Determines if CRLF should be added after the closing of the tag.</param>
    /// <exception cref="ETryingToCloseClosedTag">Raised if you try to close a tag when no tag is open.</exception>
    function CloseTag(aUseCRLF: TUseCRLFOptions = ucoNoCRLF): IHTMLWriter;
    /// <summary>Closes an open comment tag.</summary>
    function CloseComment: IHTMLWriter;
    /// <summary>Closes an open &lt;list&gt; tag</summary>
    function CloseList: IHTMLWriter;
    /// <summary>Closes an open &lt;table&gt; tag.</summary>
    function CloseTable: IHTMLWriter;
    /// <summary>Closes and open &lt;form&gt; tag.</summary>
    function CloseForm: IHTMLWriter;
    /// <summary>Closes and open &lt;html&gt; tag.</summary>
    function CloseDocument: IHTMLWriter;
    /// <summary>Opens in &lt;img&gt; tag.</summary>
    /// <remarks>This tag will always be closed by " /&gt;"</remarks>
    function OpenImage: IHTMLWriter; overload;
    /// <summary>Opens an &lt;img&gt; tag and adds the 'src' parameter.</summary>
    /// <param name="aImageSource">The URL of the image to be displayed</param>
    function OpenImage(aImageSource: string): IHTMLWriter; overload;
    function AddImage(aImageSource: string): IHTMLWriter;
    function OpenAnchor: IHTMLWriter; overload;
    function OpenAnchor(aName: string): IHTMLWriter; overload;
    function OpenAnchor(const aHREF: string; aText: string): IHTMLWriter; overload;
    function AddAnchor(const aHREF: string; aText: string): IHTMLWriter; overload;
    /// <summary>Opens a &lt;table&gt; tag</summary>
    /// <remarks>You cannot use other table related tags (&lt;tr&gt;, &lt;td&gt;, etc.) until a &lt;table&gt; tag is
    /// open.</remarks>
    function OpenTable: IHTMLWriter; overload;
    /// <summary>Opens a &lt;table&gt; tag and adds the 'border' attribute</summary>
    function OpenTable(aBorder: integer): IHTMLWriter; overload;
    function OpenTable(aBorder: integer; aCellPadding: integer): IHTMLWriter; overload;
    function OpenTable(aBorder: integer; aCellPadding: integer; aCellSpacing: integer): IHTMLWriter; overload;
    function OpenTable(aBorder: integer; aCellPadding: integer; aCellSpacing: integer; aWidth: THTMLWidth): IHTMLWriter; overload;
    /// <summary>Opens a &lt;tr&gt; tag.</summary>
    function OpenTableRow: IHTMLWriter;
    /// <summary>Opens a &lt;td&gt; tag.</summary>
    /// <remarks>This method can only be called when a &lt;tr&gt; tag is open.</remarks>
    function OpenTableData: IHTMLWriter;
    function OpenTableHeader: IHTMLWriter;
    function OpenTableHead: IHTMLWriter;
    function OpenTableBody: IHTMLWriter;
    function OpenTableFoot: IHTMLWriter;
    /// <summary>Adds the given text inside of a &lt;td&gt; tag.</summary>
    /// <exception cref="ENotInTableTagException">Raised when an attempt is made to add something in a table when the appropriate tag is not open.</exception>
    /// <remarks>This tag can only be added while a table row &lt;tr&gt; tag is open. Otherwise, an exception is raised.</remarks>
    function AddTableData(aText: string): IHTMLWriter;
    function OpenCaption: IHTMLWriter;
    function OpenColGroup: IHTMLWriter;
    function OpenCol: IHTMLWriter;
    function OpenForm(aActionURL: string = ''; aMethod: TFormMethod = fmGet): IHTMLWriter;
    function OpenInput: IHTMLWriter; overload;
    function OpenInput(aType: TInputType; aName: string = ''): IHTMLWriter; overload;
    function OpenButton(aName: string): IHTMLWriter;
    function OpenLabel: IHTMLWriter; overload;
    function OpenLabel(aFor: string): IHTMLWriter; overload;
    function OpenSelect(aName: string): IHTMLWriter;
    function OpenOption: IHTMLWriter;
    ///	<summary>Creates and opens a &lt;textarea&gt; tag.</summary>
    ///	<param name="aName">A unique identifier given to the tag.</param>
    ///	<param name="aText">The text to be added inside the &lt;textarea&gt; tag.</param>
    function OpenTextArea(aName: string; aCols: integer; aRows: integer): IHTMLWriter;
    function OpenOptGroup(aLabel: string): IHTMLWriter;
    /// <summary>Opens a &lt;fieldset&gt; tag.</summary>
    function OpenFieldSet: IHTMLWriter;
    /// <summary>Opens a &lt;legend&gt; tag.</summary>
    /// <remarks>This method will raise an exception if called outside of an open &lt;fieldset&gt; tag.</remarks>
    function OpenLegend: IHTMLWriter;
    /// <summary>Adds the passed in text to a &lt;legend&gt;&lt;/legend&gt; tag</summary>
    /// <param name="aText">The text to be included in the Legend tag.</param>
    function AddLegend(aText: string): IHTMLWriter;
    /// <summary>Opens an &lt;iframe&gt; tag.</summary>
    function OpenIFrame: IHTMLWriter; overload;
    /// <summary>Opens an &lt;iframe&gt; tag and adds a url parameter</summary>
    /// <param name="aURL">The value to be added with the url parameter.</param>
    function OpenIFrame(aURL: string): IHTMLWriter; overload;
    function OpenIFrame(aURL: string; aWidth: THTMLWidth; aHeight: integer): IHTMLWriter; overload;
    function AddIFrame(aURL: string; aAlternateText: string): IHTMLWriter; overload;
    function AddIFrame(aURL: string; aAlternateText: string; aWidth: THTMLWidth; aHeight: integer): IHTMLWriter; overload;
    /// <summary>Opens an unordered list tag (&lt;ul&gt;)</summary>
    /// <param name="aBulletShape">An optional parameter indicating the bullet type that the list should use.</param>
    /// <seealso cref="TBulletShape">TBulletShape</seealso>
    function OpenUnorderedList(aBulletShape: TBulletShape = bsNone): IHTMLWriter;
    /// <summary>Opens an ordered list tag (&lt;ol&gt;)</summary>
    /// <param name="aNumberType">An optional parameter indicating the numbering type that the list should use.</param>
    /// <seealso cref="TNumberType">TNumberType</seealso>
    function OpenOrderedList(aNumberType: TNumberType = ntNone): IHTMLWriter;
    /// <summary>Opens a list item (&lt;li&gt;) inside of a list.</summary>
    function OpenListItem: IHTMLWriter;
    /// <summary>Adds a List item (&lt;li&gt;) with the given text</summary>
    /// <param name="aText">The text to be added to the list item.</param>
    function AddListItem(aText: string): IHTMLWriter;
    ///	<summary>Opens a &lt;frameset&gt; tag.</summary>
    ///	<remarks>This tag is not part of the HTML5 specification.</remarks>
    function OpenFrameset: IHTMLWriter;
    /// <summary>Opens a &lt;frame&gt; tag.</summary>
    /// <exception cref="ENotInFrameSetHTMLException">Raised if this is called outside of a &lt;frameset&gt;
    /// tag.</exception>
    ///	<remarks>This tag is not part of the HTML5 specification.</remarks>
    function OpenFrame: IHTMLWriter;
    /// <summary>Opens a &lt;noframes&gt; tag.</summary>
    ///	<remarks>This tag is not part of the HTML5 specification.</remarks>
    function OpenNoFrames: IHTMLWriter;
    /// <summary>Opens a &lt;map /&gt; tag</summary>
    function OpenMap: IHTMLWriter;
    /// <summary>Opens an &lt;area /&gt; tag</summary>
    function OpenArea(aAltText: string): IHTMLWriter;
    /// <summary>Opens an &lt;object&gt; tag</summary>
    function OpenObject: IHTMLWriter;
    /// <summary>Opens a &lt;param&gt; tag</summary>
    /// <param name="aName">The name for the parameter</param>
    /// <param name="aValue">The value to be assigned to the paramter</param>
    /// <remarks>This tag can only be used inside of an &lt;object&gt; tag.</remarks>
    /// <exception cref="ENotInObjectTagException">Raised if this method is called outside of an &lt;object&gt;
    /// tag</exception>
    function OpenParam(aName: string; aValue: string = ''): IHTMLWriter; // name parameter is required

    function OpenDefinitionList: IHTMLWriter;
    function OpenDefinitionTerm: IHTMLWriter;
    function OpenDefinitionItem: IHTMLWriter;

    property Attribute[const Name: string; const Value: string]: IHTMLWriter read GetAttribute; default;
    ///	<summary>Property determining the level of error reporting that the class should provide.</summary>
    property ErrorLevels: THTMLErrorLevels read GetErrorLevels write SetErrorLevels;
    property HTML: TStringBuilder read GetHTML;
end;

implementation

end.





