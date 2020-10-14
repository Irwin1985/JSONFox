#include "JSONFox.h"
&& ======================================================================== &&
&& Class JsonLexer
&& ======================================================================== &&
Define Class JsonLexer As Custom

	#Define EOF_CHAR 		Chr(255)
	#Define CR				Chr(13)
	#Define LF				Chr(10)
	#Define CRLF			CR + LF
	#Define _SPACE			Space(1)
	#Define _HORIZONTAL_TAB	Chr(9)
	#Define _DOUBLE_QUOTE	Chr(34)

	Hidden Reader
	Hidden cLook
	Hidden nLineNumber
	Hidden nColNumber
	Token 		= .Null.
	Queue		= .Null.

&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
	Function Init
		With This
			.Reader 	= Createobject("StreamReader")
			.Token 		= Createobject("JSONClassToken")
			.Queue		= CreateObject("FoxQueue")
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function NextToken
&& ======================================================================== &&
	Function NextToken As Object
		With This
			If .Queue.Count() > 0
				.Token = .Queue.Dequeue()
				Return
			EndIf
			.SkipBlanks()
			.Token.LineNumber   = .nLineNumber
			.Token.ColumnNumber = .nColNumber
			Do Case
			Case .cLook = '"'
				.GetString()
			Case This.cLook = "-" Or Isdigit(.cLook)
				If This.cLook = "-"
					If Isdigit(This.Reader.Peek())
						.GetNumber()
					Else
						Error "unexpected character '" + This.cLook + "'"
					Endif
				Else
					.GetNumber()
				Endif
			Case .cLook = 't' And .Reader.Peek() = 'r'
				.GetTrue()
			Case .cLook = 'n'
				.GetNull()
			Case .cLook = 'f' And .Reader.Peek() = 'a'
				.GetFalse()
			Case .cLook = EOF_CHAR
				.Token.Code = T_ENDOFSTREAM
			Otherwise
				.GetSpecial()
			Endcase
		Endwith
	Endfunc
&& ======================================================================== &&
&& Hidden Function GetString
&& ======================================================================== &&
	Hidden Function GetString As Void
		With This
			.Token.Value = ''
			.NextChar() && eat '"'
			llShowMsg = .f.
			Do While .cLook != EOF_CHAR
				If .cLook = '\'
					.NextChar() && eat '\'
					Do Case
					Case .cLook = '\'
						.Token.Value = .Token.Value + "\"
					Case .cLook = 'n'
						.Token.Value = .Token.Value + CRLF
					Case .cLook = 'r'
						.Token.Value = .Token.Value + CR
					Case .cLook = 't'
						.Token.Value = .Token.Value + _HORIZONTAL_TAB
					Case .cLook = '"'
						llShowMsg = .t.
						.Token.Value = .Token.Value + _DOUBLE_QUOTE
					Case .cLook = 'u'
						.Token.Value = .Token.Value + .GetUnicode()
						Loop
					Otherwise
						.Token.Value = .Token.Value + '\' + .cLook
					Endcase
					.NextChar()
				Else
					If .cLook = '"'
						.NextChar() && eat '"'
						Exit
					Else
						.Token.Value = .Token.Value + .cLook
						.NextChar()
					Endif
				Endif
			Enddo
			.SkipBlanks()
			If .cLook = ':'
				.Token.Code = T_KEY
			Else
				.Token.Code = T_STRING
			EndIf
		Endwith
	Endfunc
&& ======================================================================== &&
&& Hidden Function GetSpecial
&& ======================================================================== &&
	Hidden Function GetSpecial As Void
		With This
			Do Case
			Case .cLook = '{'
				.Token.Code = T_LEFTCURLEYBRACKET
			Case .cLook = '}'
				.Token.Code = T_RIGHTCURLEYBRACKET
			Case .cLook = '['
				.Token.Code = T_LEFTBRACKET
			Case .cLook = ']'
				.Token.Code = T_RIGHTBRACKET
			Case .cLook = ':'
				.Token.Code = T_COLON
			Case .cLook = ','
				.Token.Code = T_COMMA
			Otherwise
				Error "unrecongnised character '" + Transform(.cLook) + "' ASCII '" + Transform(Asc(.cLook)) + "' line: " + Alltrim(Str(.nLineNumber)) + ", col: " + Alltrim(Str(.nColNumber))
			Endcase
			.NextChar()
		Endwith
	Endfunc
&& ======================================================================== &&
&& Hidden Function SkipBlanks
&& ======================================================================== &&
	Hidden Function SkipBlanks As Void
		Do While Inlist(This.cLook, Chr(32), Chr(9))
			This.NextChar()
		Enddo
	Endfunc
&& ======================================================================== &&
&& Hidden Function GetUnicode
&& ======================================================================== &&
	Hidden Function GetUnicode As Void
		With This
			lcHexStr = '\' + .cLook
			.NextChar()
			Local lcUnicode As String
			lcUnicode = "0x"
			Do While .IsHex(.cLook) Or Isdigit(.cLook)
				If Len(lcUnicode) = 6
					Exit
				Endif
				lcUnicode = lcUnicode + .cLook
				lcHexStr = lcHexStr + .cLook
				.NextChar()
			Enddo
		EndWith
		Try
			lcUnicode = Chr(&lcUnicode)
		Catch
			Try
				lcUnicode = Strconv(lcHexStr, 16)
			Catch
				Error "parse error: invalid hex format '" + Transform(lcUnicode) + "'"
			EndTry
		Endtry
		Return lcUnicode
	Endfunc
&& ======================================================================== &&
&& Hidden Function IsHex
&& ======================================================================== &&
	Hidden Function IsHex As Boolean
		Lparameters tcLook As String
		Return Between(Asc(tcLook), Asc("A"), Asc("F")) Or Between(Asc(tcLook), Asc("a"), Asc("f"))
	Endfunc
&& ======================================================================== &&
&& Hidden Function GetNumber
&& ======================================================================== &&
	Hidden Function GetNumber As Void
		With This
			Local lnNumber As Integer, lnDecimals As Integer, lnSign As Integer
			lnNumber = 0
			lnSign   = 1
			If This.cLook = '-'
				lnSign = -1
				This.Match('-')
			Endif
			lnDecimals = Set("Decimals")
			Set Decimals To 0
			.Token.Code = T_INTEGER && Integer assumed

			If .cLook != '.'
				Do While Isdigit(.cLook)
					lnDigit  = Val(.cLook)
					lnNumber = lnNumber * 10 + lnDigit
					.NextChar()
				Enddo
			Endif
			.Token.Value = lnNumber

			If .cLook = '.'
				.NextChar() && consume '.'
				lnScale = 1
				Do While Isdigit(.cLook)
					lnScale  = lnScale * 0.1
					lnDigit  = Val(.cLook)
					lnNumber = lnNumber + (lnScale * lnDigit)
					.NextChar()
				Enddo
				.Token.Value = lnNumber
				.Token.Code  = T_FLOAT
			Endif
			.Token.Value = .Token.Value * lnSign
			Set Decimals To lnDecimals
		Endwith
	Endfunc
&& ======================================================================== &&
&& Hidden Function GetTrue
&& ======================================================================== &&
	Hidden Function GetTrue As Void
		With This
			.Match('t')
			.Match('r')
			.Match('u')
			.Match('e')
			.Token.Code  = T_TRUE
			.Token.Value = .T.
		Endwith
	Endfunc
&& ======================================================================== &&
&& Hidden Function GetFalse
&& ======================================================================== &&
	Hidden Function GetFalse As Void
		With This
			.Match('f')
			.Match('a')
			.Match('l')
			.Match('s')
			.Match('e')
			.Token.Code = T_FALSE
			.Token.Value = .F.
		Endwith
	Endfunc
&& ======================================================================== &&
&& Hidden Function GetNull
&& ======================================================================== &&
	Hidden Function GetNull As Void
		With This
			.Match('n')
			.Match('u')
			.Match('l')
			.Match('l')
			.Token.Code = T_NULL
			.Token.Value = .Null.
		Endwith
	Endfunc
&& ======================================================================== &&
&& Hidden Expected
&& ======================================================================== &&
	Hidden Function Expected As Void
		Lparameters tcExpected As String
		With This
			Error "expected '" + tcExpected + "' got '" + .cLook + "' Line: " + Alltrim(Str(.nLineNumber)) + " Column: " + Alltrim(Str(.nColNumber))
		Endwith
	Endfunc
&& ======================================================================== &&
&& Hidden Function Match
&& ======================================================================== &&
	Hidden Function Match(tcChar As Character)
		With This
			If .cLook == tcChar
				.NextChar()
			Else
				.Expected(tcChar)
			Endif
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function ScanString
&& ======================================================================== &&
	Function ScanString As Void
		Lparameters tcString As String, tlDontConvert As Boolean
		With This
			.Reader.SetString(Iif(!tlDontConvert, Strconv(tcString, 11), tcString))
			.StartScanner()
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function ScanFile
&& ======================================================================== &&
	Function ScanFile As Void
		Lparameters tcFile As String, tlDontConvert As Boolean
		If File(tcFile)
			With This
				.Reader.SetString(Iif(!tlDontConvert, Strconv(Filetostr(tcFile), 11), Filetostr(tcFile)))
				.StartScanner()
			Endwith
		Endif
	Endfunc
&& ======================================================================== &&
&& Hidden Function StartScanner
&& ======================================================================== &&
	Hidden Function StartScanner As Void
		With This
			.nLineNumber = 1
			.nColNumber  = 0
			.NextChar()
		Endwith
	Endfunc
&& ======================================================================== &&
&& Hidden Function NextChar
&& ======================================================================== &&
	Hidden Function NextChar
		With This
			.GetChar()
			If .cLook = LF
				.cLook		   = _SPACE
				.nLineNumber   = .nLineNumber + 1
				.nColNumber = 0
			Endif
		Endwith
	Endfunc
&& ======================================================================== &&
&& Hidden Function ReadCharFromInput
&& ======================================================================== &&
	Hidden Function ReadCharFromInput As Character
		With This
			If !.Reader.EndOfStream
				.nColNumber = .nColNumber + 1
				.cLook = .Reader.Read()
			Else
				.cLook = EOF_CHAR
			Endif
		Endwith
	Endfunc
&& ======================================================================== &&
&& Hidden Function GetChar
&& ======================================================================== &&
	Hidden Function GetChar As Void
		With This
			.ReadCharFromInput()
			If Inlist(.cLook, CR, LF)
				If .cLook = CR
					.ReadCharFromInput()
* the LF character is not mandatory.
				Endif
			Endif
		Endwith
	Endfunc
&& ======================================================================== &&
&& ToString
&& ======================================================================== &&
	Function ToString As String
		lcTokenStr = ''
		With This
			Do Case
			Case .Token.Code = T_LEFTCURLEYBRACKET
				lcTokenStr = "special: <'{'>"
			Case .Token.Code = T_RIGHTCURLEYBRACKET
				lcTokenStr = "special: <'}'>"
			Case .Token.Code = T_LEFTBRACKET
				lcTokenStr = "special: <'['>"
			Case .Token.Code = T_RIGHTBRACKET
				lcTokenStr = "special: <']'>"
			Case .Token.Code = T_COLON
				lcTokenStr = "special: <':'>"
			Case .Token.Code = T_COMMA
				lcTokenStr = "special: <','>"
			Case .Token.Code = T_STRING
				lcTokenStr = "string: <'" + Transform(.Token.Value) + "'>"
			Case .Token.Code = T_INTEGER
				lcTokenStr = "integer: <'" + Transform(.Token.Value) + "'>"
			Case .Token.Code = T_FLOAT
				lcTokenStr = "float: <'" + Transform(.Token.Value) + "'>"
			Case .Token.Code = T_TRUE
				lcTokenStr = "boolean: <'true'>"
			Case .Token.Code = T_FALSE
				lcTokenStr = "boolean: <'false'>"
			Case .Token.Code = T_NULL
				lcTokenStr = "null: <'null'>"
			Case .Token.Code = T_KEY
				lcTokenStr = "key: <'" + Transform(.Token.Value) + "'>"
			Case .Token.Code = T_VALUE
				lcTokenStr = "value: <'" + Transform(.Token.Value) + "'>"
			Endcase
		Endwith
		Return lcTokenStr
	Endfunc
&& ======================================================================== &&
&& Function TokenToStr
&& ======================================================================== &&
	Function TokenToStr As String
		Lparameters tnToken As Integer
		lcTokenStr As String
		lcTokenStr = ''
		Do Case
		Case tnToken = T_ENDOFSTREAM
			lcTokenStr = 'EOF'
		Case tnToken = T_LEFTCURLEYBRACKET
			lcTokenStr = '{'
		Case tnToken = T_RIGHTCURLEYBRACKET
			lcTokenStr = '}'
		Case tnToken = T_LEFTBRACKET
			lcTokenStr = '['
		Case tnToken = T_RIGHTBRACKET
			lcTokenStr = ']'
		Case tnToken = T_COLON
			lcTokenStr = ':'
		Case tnToken = T_COMMA
			lcTokenStr = ','
		Case tnToken = T_STRING
			lcTokenStr = 'STRING'
		Case tnToken = T_INTEGER
			lcTokenStr = 'INTEGER'
		Case tnToken = T_FLOAT
			lcTokenStr = 'FLOAT'
		Case tnToken = T_TRUE
			lcTokenStr = 'true'
		Case tnToken = T_FALSE
			lcTokenStr = 'false'
		Case tnToken = T_NULL
			lcTokenStr = 'null'
		Case tnToken = T_KEY
			lcTokenStr = 'KEY'
		Case tnToken = T_VALUE
			lcTokenStr = 'VALUE'
		Otherwise
			lcTokenStr = 'UNKNOWN'
		Endcase
		Return lcTokenStr
	Endfunc
&& ======================================================================== &&
&& Function Peek
&& Return the next token without affecting the current one.
&& ======================================================================== &&
	Function Peek (tnTokenNumber As Integer) As Object
		With This
			Set Step On
			Local nCurrentPos As Integer, loCurToken As Object, lcCurLook As Character, loTokenReturn As Object
			tnTokenNumber = Evl(tnTokenNumber, 1)
			loTokenReturn = Createobject("Empty")
			=AddProperty(loTokenReturn, "aTokens(1)", .Null.)
* Save current token values
			nCurrentPos = .Reader.GetPosition()
			loCurToken  = .Token.Clone()
* Save current char
			lcCurLook 	= .cLook
* Iterates N tokens
			For i = 1 To tnTokenNumber
				Dimension loTokenReturn.aTokens(i)
				.NextToken()
				loTokenReturn.aTokens[i] = .Token.Clone()
* Store the peeked token
			Endfor
* Restore the current position
			.Reader.SetPosition(nCurrentPos)
* Restore the current token
			.Token.Update(loCurToken)
			.cLook = lcCurLook
			Return loTokenReturn
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function PushBackToken
&& ======================================================================== &&
	Function PushBackToken(toToken As Object) As Void
		This.Queue.Enqueue(toToken)
	EndFunc
&& ======================================================================== &&
&& Function Destroy
&& ======================================================================== &&
	Function Destroy
		With This
			.Reader 	= .Null.
			.Token 		= .Null.
		Endwith
	Endfunc
Enddefine