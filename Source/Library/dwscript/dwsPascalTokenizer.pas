{**********************************************************************}
{                                                                      }
{    "The contents of this file are subject to the Mozilla Public      }
{    License Version 1.1 (the "License"); you may not use this         }
{    file except in compliance with the License. You may obtain        }
{    a copy of the License at http://www.mozilla.org/MPL/              }
{                                                                      }
{    Software distributed under the License is distributed on an       }
{    "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express       }
{    or implied. See the License for the specific language             }
{    governing rights and limitations under the License.               }
{                                                                      }
{    Copyright Creative IT.                                            }
{    Current maintainer: Eric Grange                                   }
{                                                                      }
{**********************************************************************}
unit dwsPascalTokenizer;

{$I dws.inc}

interface

uses dwsTokenizer, dwsStrings;

type
   TPascalTokenizerStateRules = class(TTokenizerRules)
      private
         sStart, sComment, sCommentF, sSlashComment, sSlashComment0 : TState;
         sBracketLeft, sBlockCommentBracket, sBlockCommentBracket1 : TState;
         sBlockCommentSlash, sBlockCommentSlash1 : TState;
         sSwitch, sSwitchNameF, sChar0, sCharF, sCharHex, sCharHexF : TState;
         sNameF, sNameEscapedF, sNameEscapedS: TState;
         sIntF, sIntPoint, sIntPointF, sIntExp, sIntExp0, sIntExpF, sHex, sHexF: TState;
         sAssign0 : TState;
         sStringSingle, sStringSingleF : TState;
         sStringDouble, sStringDoubleF : TState;
         sStringIndentDouble, sStringIndentDoubleF : TState;
         sStringIndentSingle, sStringIndentSingleF : TState;
         sGreaterF, sSmallerF, sDotDot: TState;

      protected
         function StartState : TState; override;

      public
         constructor Create; override;

   end;

const
   cPascalReservedNames : TTokenTypes = [
      ttStrVal, ttIntVal, ttFloatVal, ttDOT, ttDOTDOT,

      ttPLUS, ttMINUS,
      ttTIMES, ttDIVIDE, ttPERCENT, ttCARET, ttAT, ttDOLLAR,
      ttEQ, ttNOTEQ, ttGTR, ttGTREQ, ttLESS, ttLESSEQ,
      ttLESSLESS, ttGTRGTR,
      ttSEMI, ttCOMMA, ttCOLON,
      ttASSIGN, ttPLUS_ASSIGN, ttMINUS_ASSIGN, ttTIMES_ASSIGN, ttDIVIDE_ASSIGN,
      ttPERCENT_ASSIGN, ttCARET_ASSIGN, ttAT_ASSIGN,
      ttBLEFT, ttBRIGHT, ttALEFT, ttARIGHT, ttCRIGHT,

      ttAND, ttARRAY, ttAS, ttBEGIN, ttBREAK,
      ttCASE, ttCLASS, ttCONST, ttCONSTRUCTOR, ttCONTINUE,
      ttDESTRUCTOR, ttDIV, ttDO, ttDOWNTO,
      ttELSE, ttEND, ttEXCEPT, ttEXIT,
      ttFALSE, ttFINALLY, ttFOR, ttFUNCTION, ttIF, ttIMPLEMENTATION, ttIMPLIES,
      ttIN, ttINHERITED, ttINTERFACE, ttIS, ttMOD, ttNEW, ttNIL, ttNOT, ttOBJECT,
      ttOF, ttOPERATOR, ttOR, ttOVERLOAD, ttPROCEDURE, ttPROPERTY, ttRAISE, ttRECORD,
      ttREINTRODUCE, ttREPEAT, ttRESOURCESTRING, ttSAR, ttSET, ttSHL, ttSHR,
      ttTHEN, ttTRUE, ttTRY, ttTYPE,
      ttUNIT, ttUNTIL, ttUSES, ttVAR, ttWHILE, ttXOR
      ];

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

const
   cOPS = ['+', '-', '*', '/', '=', '<', '>', '@', '%', '^'];
   cSPACE = [' ', #9, #13, #10, #0];
   cSPEC = ['(', ')', ',', ';', '[', ']', '}', '!'];
   cSTOP = cSPEC + cOPS + cSPACE + [':', '.', '{'];
   cANYCHAR = [#0..#255];
   cNAM = ['A'..'Z', 'a'..'z', '_', #127];
   cINT = ['0'..'9'];
   cHEX = cINT + ['A'..'F', 'a'..'f'];
   cStart = ['''', '"', '#', ':', '$', '.'] + cNAM + cINT + cOPS;

// ------------------
// ------------------ TPascalTokenizerStateRules ------------------
// ------------------

// Create
//
constructor TPascalTokenizerStateRules.Create;
begin
   inherited;

   ReservedNames:=cPascalReservedNames;

   sStart:=CreateState;
   sComment:=CreateState;
   sCommentF:=CreateState;
   sSwitch:=CreateState;
   sSwitchNameF:=CreateState;
   sSlashComment0:=CreateState;
   sSlashComment:=CreateState;
   sBracketLeft:=CreateState;
   sBlockCommentBracket:=CreateState;
   sBlockCommentBracket1:=CreateState;
   sBlockCommentSlash:=CreateState;
   sBlockCommentSlash1:=CreateState;
   sChar0:=CreateState;
   sCharF:=CreateState;
   sCharHex:=CreateState;
   sCharHexF:=CreateState;
   sNameF:=CreateState;
   sNameEscapedS:=CreateState;
   sNameEscapedF:=CreateState;
   sIntF:=CreateState;
   sIntPoint:=CreateState;
   sIntPointF:=CreateState;
   sIntExp:=CreateState;
   sIntExp0:=CreateState;
   sIntExpF:=CreateState;
   sHex:=CreateState;
   sHexF:=CreateState;
   sStringSingle:=CreateState;
   sStringSingleF:=CreateState;
   sStringDouble:=CreateState;
   sStringDoubleF:=CreateState;
   sStringIndentSingle:=CreateState;
   sStringIndentSingleF:=CreateState;
   sStringIndentDouble:=CreateState;
   sStringIndentDoubleF:=CreateState;
   sAssign0:=CreateState;
   sGreaterF:=CreateState;
   sSmallerF:=CreateState;
   sDotDot:=CreateState;

   sStart.AddTransition(cSPACE, TSeekTransition.Create(sStart, [], caNone));
   sStart.AddTransition(cNAM, TConsumeTransition.Create(sNameF, [toStart], caNone));
   sStart.AddTransition(['&'], TSeekTransition.Create(sNameEscapedS, [toStart], caNone));
   sStart.AddTransition(cINT, TConsumeTransition.Create(sIntF, [toStart], caNone));
   sStart.AddTransition([''''], TSeekTransition.Create(sStringSingle, [toStart], caNone));
   sStart.AddTransition(['"'], TSeekTransition.Create(sStringDouble, [toStart], caNone));
   sStart.AddTransition(['#'], TSeekTransition.Create(sChar0, [toStart], caNone));
   sStart.AddTransition([':', '+', '-', '*', '@', '%', '^'], TConsumeTransition.Create(sAssign0, [toStart], caNone));
   sStart.AddTransition(['='], TConsumeTransition.Create(sStart, [toStart, toFinal], caName));
   sStart.AddTransition(cSPEC-['('], TConsumeTransition.Create(sStart, [toStart, toFinal], caName));
   sStart.AddTransition(['('], TConsumeTransition.Create(sBracketLeft, [toStart], caNone));
   sStart.AddTransition(['/'], TConsumeTransition.Create(sSlashComment0, [toStart], caNone));
   sStart.AddTransition(['<'], TConsumeTransition.Create(sSmallerF, [toStart], caNone));
   sStart.AddTransition(['>'], TConsumeTransition.Create(sGreaterF, [toStart], caNone));
   sStart.AddTransition(['.'], TConsumeTransition.Create(sDotDot, [toStart], caNone));
   sStart.AddTransition(['{'], TSeekTransition.Create(sComment, [], caNone));
   sStart.AddTransition(['$'], TConsumeTransition.Create(sHex, [toStart], caNone));
   sStart.SetElse(TErrorTransition.Create(TOK_InvalidChar));

   sComment.AddTransition(['}'], TSeekTransition.Create(sStart, [], caClear));
   sComment.AddTransition(['$'], TSeekTransition.Create(sSwitch, [], caNone));
   sComment.SetElse(TSeekTransition.Create(sCommentF, [], caNone));

   sCommentF.AddTransition(['}'], TSeekTransition.Create(sStart, [], caClear));
   sCommentF.SetElse(TSeekTransition.Create(sCommentF, [], caNone));

   sSwitch.AddTransition(cNAM, TConsumeTransition.Create(sSwitchNameF, [toStart], caNone));
   sSwitch.SetElse(TErrorTransition.Create(TOK_NameOfSwitchExpected));

   sSwitchNameF.AddTransition(cNAM + cINT, TConsumeTransition.Create(sSwitchNameF, [], caNone));
   sSwitchNameF.AddTransition(cSTOP, TCheckTransition.Create(sStart, [toFinal], caSwitch));
   sSwitchNameF.SetElse(TErrorTransition.Create(TOK_InvalidChar));

   sSlashComment0.AddTransition(['/'], TSeekTransition.Create(sSlashComment, [], caNone));
   sSlashComment0.AddTransition(['='], TConsumeTransition.Create(sStart, [toFinal], caName));
   sSlashComment0.AddTransition(['*'], TConsumeTransition.Create(sBlockCommentSlash, [], caNone));
   sSlashComment0.SetElse(TCheckTransition.Create(sStart, [toFinal], caName));

   sSlashComment.AddTransition([#10], TSeekTransition.Create(sStart, [], caClear));
   sSlashComment.SetElse(TSeekTransition.Create(sSlashComment, [], caNone));

   sBracketLeft.AddTransition(['*'], TSeekTransition.Create(sBlockCommentBracket, [], caNone));
   sBracketLeft.SetElse(TCheckTransition.Create(sStart, [toFinal], caName));

   sBlockCommentBracket.AddTransition(['*'], TSeekTransition.Create(sBlockCommentBracket1, [], caNone));
   sBlockCommentBracket.SetElse(TSeekTransition.Create(sBlockCommentBracket, [], caNone));

   sBlockCommentBracket1.AddTransition([')'], TSeekTransition.Create(sStart, [], caClear));
   sBlockCommentBracket1.AddTransition(['*'], TSeekTransition.Create(sBlockCommentBracket1, [], caNone));
   sBlockCommentBracket1.SetElse(TSeekTransition.Create(sBlockCommentBracket, [], caNone));

   sBlockCommentSlash.AddTransition(['*'], TSeekTransition.Create(sBlockCommentSlash1, [], caNone));
   sBlockCommentSlash.SetElse(TSeekTransition.Create(sBlockCommentSlash, [], caNone));

   sBlockCommentSlash1.AddTransition(['/'], TSeekTransition.Create(sStart, [], caClear));
   sBlockCommentSlash1.AddTransition(['*'], TSeekTransition.Create(sBlockCommentSlash1, [], caNone));
   sBlockCommentSlash1.SetElse(TSeekTransition.Create(sBlockCommentSlash, [], caNone));

   sChar0.AddTransition(cINT, TConsumeTransition.Create(sCharF, [], caNone));
   sChar0.AddTransition(['$'], TConsumeTransition.Create(sCharHex, [], caNone));
   sChar0.AddTransition([''''], TSeekTransition.Create(sStringIndentSingle, [], caNone));
   sChar0.AddTransition(['"'], TSeekTransition.Create(sStringIndentDouble, [], caNone));
   sChar0.SetElse(TErrorTransition.Create(TOK_NumberExpected));

   sCharF.AddTransition(cINT, TConsumeTransition.Create(sCharF, [], caNone));
   sCharF.AddTransition(['''', '"'], TCheckTransition.Create(sStart, [], caChar));
   sCharF.AddTransition(['#'], TCheckTransition.Create(sStart, [], caChar));
   sCharF.AddTransition(cSTOP, TCheckTransition.Create(sStart, [toFinal], caChar));
   sCharF.SetElse(TErrorTransition.Create(TOK_InvalidChar));

   sCharHex.AddTransition(cHEX, TConsumeTransition.Create(sCharHexF, [], caNone));
   sCharHex.SetElse(TErrorTransition.Create(TOK_HexDigitExpected));

   sCharHexF.AddTransition(cHEX, TConsumeTransition.Create(sCharHexF, [], caNone));
   sCharHexF.AddTransition(['''', '"'], TCheckTransition.Create(sStart, [], caCharHex));
   sCharHexF.AddTransition(['#'], TCheckTransition.Create(sStart, [], caCharHex));
   sCharHexF.AddTransition(cSTOP, TCheckTransition.Create(sStart, [toFinal], caCharHex));
   sCharHexF.SetElse(TErrorTransition.Create(TOK_HexDigitExpected));

   sNameF.AddTransition(cNAM + cINT, TConsumeTransition.Create(sNameF, [], caNone));
   sNameF.AddTransition(cSTOP, TCheckTransition.Create(sStart, [toFinal], caName));
   sNameF.SetElse(TErrorTransition.Create(TOK_InvalidChar));

   sNameEscapedS.AddTransition(cNAM, TConsumeTransition.Create(sNameEscapedF, [toStart], caNone));
   sNameEscapedS.SetElse(TErrorTransition.Create(TOK_InvalidChar));

   sNameEscapedF.AddTransition(cNAM+cINT, TConsumeTransition.Create(sNameEscapedF, [], caNone));
   sNameEscapedF.AddTransition(cSTOP, TCheckTransition.Create(sStart, [toFinal], caNameEscaped));
   sNameEscapedF.SetElse(TErrorTransition.Create(TOK_InvalidChar));

   sIntF.AddTransition(cINT, TConsumeTransition.Create(sIntF, [], caNone));
   sIntF.AddTransition(['.'], TConsumeTransition.Create(sIntPoint, [], caNone));
   sIntF.AddTransition(['E', 'e'], TConsumeTransition.Create(sIntExp, [], caNone));
   sIntF.AddTransition(cSTOP, TCheckTransition.Create(sStart, [toFinal], caInteger));
   sIntF.SetElse(TErrorTransition.Create(TOK_NumberPointExponentExpected));

   sIntPoint.AddTransition(['.'], TCheckTransition.Create(sDotDot, [toFinal], caInteger));
   sIntPoint.AddTransition(cINT, TConsumeTransition.Create(sIntPointF, [], caNone));
   sIntPoint.SetElse(TErrorTransition.Create(TOK_NumberExpected));

   sIntPointF.AddTransition(cINT, TConsumeTransition.Create(sIntPointF, [], caNone));
   sIntPointF.AddTransition(['E', 'e'], TConsumeTransition.Create(sIntExp, [], caNone));
   sIntPointF.AddTransition(cSTOP, TCheckTransition.Create(sStart, [toFinal], caFloat));
   sIntPointF.SetElse(TErrorTransition.Create(TOK_NumberExponentExpected));

   sIntExp.AddTransition(['+', '-'], TConsumeTransition.Create(sIntExp0, [], caNone));
   sIntExp.AddTransition(cINT, TConsumeTransition.Create(sIntExpF, [], caNone));
   sIntExp.SetElse(TErrorTransition.Create(TOK_NumberSignExpected));

   sIntExp0.AddTransition(cINT, TConsumeTransition.Create(sIntExpF, [], caNone));
   sIntExp0.SetElse(TErrorTransition.Create(TOK_NumberExpected));

   sIntExpF.AddTransition(cINT, TConsumeTransition.Create(sIntExpF, [], caNone));
   sIntExpF.AddTransition(cSTOP, TCheckTransition.Create(sStart, [toFinal], caFloat));
   sIntExpF.SetElse(TErrorTransition.Create(TOK_NumberExpected));

   sHex.AddTransition(cHEX, TConsumeTransition.Create(sHexF, [], caNone));
   sHex.AddTransition(['('], TCheckTransition.Create(sStart, [toFinal], caName));
   sHex.SetElse(TErrorTransition.Create(TOK_HexDigitExpected));

   sHexF.AddTransition(cHEX, TConsumeTransition.Create(sHexF, [], caNone));
   sHexF.AddTransition(cSTOP, TCheckTransition.Create(sStart, [toFinal], caHex));
   sHexF.SetElse(TErrorTransition.Create(TOK_HexDigitExpected));

   sStringSingle.AddTransition(cANYCHAR - ['''', #13, #10], TConsumeTransition.Create(sStringSingle, [], caNone));
   sStringSingle.AddTransition([''''], TSeekTransition.Create(sStringSingleF, [], caNone));
   sStringSingle.AddTransition([#0, #13, #10], TErrorTransition.Create(TOK_StringTerminationError));

   sStringSingleF.AddTransition([''''], TConsumeTransition.Create(sStringSingle, [], caNone));
   sStringSingleF.AddTransition(['#'], TCheckTransition.Create(sStart, [], caString));
   sStringSingleF.AddTransition(cSTOP, TCheckTransition.Create(sStart, [toFinal], caString));
   sStringSingleF.SetElse(TErrorTransition.Create(TOK_InvalidChar));

   sStringDouble.AddTransition(cANYCHAR - ['"', #0], TConsumeTransition.Create(sStringDouble, [], caNone));
   sStringDouble.AddTransition(['"'], TSeekTransition.Create(sStringDoubleF, [], caNone));
   sStringDouble.AddTransition([#0], TErrorTransition.Create(TOK_HereDocTerminationError));

   sStringDoubleF.AddTransition(['"'], TConsumeTransition.Create(sStringDouble, [], caNone));
   sStringDoubleF.AddTransition(['#'], TCheckTransition.Create(sStart, [], caString));
   sStringDoubleF.AddTransition(cSTOP, TCheckTransition.Create(sStart, [toFinal], caString));
   sStringDoubleF.SetElse(TErrorTransition.Create(TOK_InvalidChar));

   sStringIndentSingle.AddTransition(cANYCHAR - ['''', #0], TConsumeTransition.Create(sStringIndentSingle, [], caNone));
   sStringIndentSingle.AddTransition([''''], TSeekTransition.Create(sStringIndentSingleF, [], caNone));
   sStringIndentSingle.AddTransition([#0], TErrorTransition.Create(TOK_HereDocTerminationError));

   sStringIndentSingleF.AddTransition([''''], TConsumeTransition.Create(sStringIndentSingle, [], caNone));
   sStringIndentSingleF.AddTransition(['#'], TCheckTransition.Create(sStart, [], caMultiLineString));
   sStringIndentSingleF.AddTransition(cSTOP, TCheckTransition.Create(sStart, [toFinal], caMultiLineString));
   sStringIndentSingleF.SetElse(TErrorTransition.Create(TOK_InvalidChar));

   sStringIndentDouble.AddTransition(cANYCHAR - ['"', #0], TConsumeTransition.Create(sStringIndentDouble, [], caNone));
   sStringIndentDouble.AddTransition(['"'], TSeekTransition.Create(sStringIndentDoubleF, [], caNone));
   sStringIndentDouble.AddTransition([#0], TErrorTransition.Create(TOK_HereDocTerminationError));

   sStringIndentDoubleF.AddTransition(['"'], TConsumeTransition.Create(sStringIndentDouble, [], caNone));
   sStringIndentDoubleF.AddTransition(['#'], TCheckTransition.Create(sStart, [], caMultiLineString));
   sStringIndentDoubleF.AddTransition(cSTOP, TCheckTransition.Create(sStart, [toFinal], caMultiLineString));
   sStringIndentDoubleF.SetElse(TErrorTransition.Create(TOK_InvalidChar));

   sAssign0.AddTransition(['='], TConsumeTransition.Create(sStart, [toFinal], caName));
   sAssign0.AddTransition(cStart + cSTOP, TCheckTransition.Create(sStart, [toFinal], caName));
   sAssign0.SetElse(TErrorTransition.Create(TOK_EqualityExpected));

   sGreaterF.AddTransition(['='], TConsumeTransition.Create(sStart, [toFinal], caName));
   sGreaterF.AddTransition(['>'], TConsumeTransition.Create(sStart, [toFinal], caName));
   sGreaterF.AddTransition(cStart + cSTOP, TCheckTransition.Create(sStart, [toFinal], caName));
   sGreaterF.SetElse(TErrorTransition.Create(TOK_EqualityExpected));

   sSmallerF.AddTransition(['='], TConsumeTransition.Create(sStart, [toFinal], caName));
   sSmallerF.AddTransition(['>'], TConsumeTransition.Create(sStart, [toFinal], caName));
   sSmallerF.AddTransition(['<'], TConsumeTransition.Create(sStart, [toFinal], caName));
   sSmallerF.AddTransition(cStart + cSTOP, TCheckTransition.Create(sStart, [toFinal], caName));
   sSmallerF.SetElse(TErrorTransition.Create(TOK_GreaterEqualityExpected));

   sDotDot.AddTransition(['.'], TConsumeTransition.Create(sStart, [toFinal], caDotDot));
   sDotDot.SetElse(TCheckTransition.Create(sStart, [toFinal], caName));

   PrepareStates;
end;

// StartState
//
function TPascalTokenizerStateRules.StartState : TState;
begin
   Result:=sStart;
end;

end.
