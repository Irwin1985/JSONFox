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
	TokenCode 	= .Null.
	Token 		= .Null.
	PeekToken   = .Null.
&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
	Function Init
		Set Procedure To "StreamReader" Additive
		Set Procedure To "EnumType"		Additive
		This.Reader = Createobject("StreamReader")
		Local lcEnum As String
		TEXT to lcEnum noshow
			EndOfStream = 0,
			LeftCurleyBracket,
			RightCurleyBracket,
			LeftBracket,
			RightBracket,
			Colon,
			Comma,
			String,
			Integer,
			Float,
			True,
			False,
			Null,
			Key,
			Value
		ENDTEXT
* Create both 'TokenCode' and 'Token' Object
		With This
			.TokenCode  = Enum(lcEnum)
			.Token = Createobject("Empty")
			=AddProperty(.Token, "lineNumber", 0)
			=AddProperty(.Token, "columnNumber", 0)
			=AddProperty(.Token, "Code", 0)
			=AddProperty(.Token, "Value", "")
			.PeekToken = .Token
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function NextToken
&& ======================================================================== &&
	Function NextToken As Object
		With This
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
				.Token.Code = .TokenCode.EndOfStream
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
			.NextChar()
			Do While .cLook != EOF_CHAR
				If .cLook = '\'
					.NextChar()
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
						.NextChar()
						Exit
					Else
						.Token.Value = .Token.Value + .cLook
						.NextChar()
					Endif
				Endif
			Enddo
			.SkipBlanks()
			If .cLook = ':'
				.Token.Code = .TokenCode.Key
			Else
				.Token.Code = .TokenCode.String
			Endif
			.Token.Value = Strconv(.Token.Value, 11)
		Endwith
	Endfunc
&& ======================================================================== &&
&& Hidden Function GetSpecial
&& ======================================================================== &&
	Hidden Function GetSpecial As Void
		With This
			Do Case
			Case .cLook = '{'
				.Token.Code = .TokenCode.LeftCurleyBracket
			Case .cLook = '}'
				.Token.Code = .TokenCode.RightCurleyBracket
			Case .cLook = '['
				.Token.Code = .TokenCode.LeftBracket
			Case .cLook = ']'
				.Token.Code = .TokenCode.RightBracket
			Case .cLook = ':'
				.Token.Code = .TokenCode.Colon
			Case .cLook = ','
				.Token.Code = .TokenCode.Comma
			Otherwise
				Error "unrecongnised character '" + Transform(.cLook) + "' ASCII '" + Transform(Asc(.cLook)) + "'"
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
			.NextChar()
			Local lcUnicode As String
			lcUnicode = "0x"
			Do While .IsHex(.cLook) Or Isdigit(.cLook)
				lcUnicode = lcUnicode + .cLook
				.NextChar()
				If Len(lcUnicode) = 6
					Exit
				Endif
			Enddo
		Endwith
		Try
			lcUnicode = Chr(&lcUnicode)
		Catch
			Error "parse error: invalid hex format '" + Transform(lcUnicode) + "'"
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
			If This.cLook = "-"
				lnSign = -1
				This.Match("-")
			Endif
			lnDecimals = Set("Decimals")
			Set Decimals To 0
			.Token.Code = .TokenCode.Integer && Integer assumed

			If .cLook != "."
				Do While Isdigit(.cLook)
					lnDigit  = Val(.cLook)
					lnNumber = lnNumber * 10 + lnDigit
					.NextChar()
				Enddo
			Endif
			.Token.Value = lnNumber

			If .cLook = "."
				.NextChar() && consume "."
				lnScale = 1
				Do While Isdigit(.cLook)
					lnScale  = lnScale * 0.1
					lnDigit  = Val(.cLook)
					lnNumber = lnNumber + (lnScale * lnDigit)
					.NextChar()
				Enddo
				.Token.Value = lnNumber
				.Token.Code  = This.TokenCode.Float
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
			.Match("t")
			.Match("r")
			.Match("u")
			.Match("e")
			.Token.Code  = .TokenCode.True
			.Token.Value = .T.
		Endwith
	Endfunc
&& ======================================================================== &&
&& Hidden Function GetFalse
&& ======================================================================== &&
	Hidden Function GetFalse As Void
		With This
			.Match("f")
			.Match("a")
			.Match("l")
			.Match("s")
			.Match("e")
			.Token.Code = .TokenCode.False
			.Token.Value = .F.
		Endwith
	Endfunc
&& ======================================================================== &&
&& Hidden Function GetNull
&& ======================================================================== &&
	Hidden Function GetNull As Void
		With This
			.Match("n")
			.Match("u")
			.Match("l")
			.Match("l")
			.Token.Code = .TokenCode.Null
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
		Lparameters tcString As String
		With This
			.Reader.SetString(tcString)
			.StartScanner()
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function ScanFile
&& ======================================================================== &&
	Function ScanFile As Void
		Lparameters tcFile As String
		If File(tcFile)
			With This
				.Reader.SetString(Filetostr(tcFile))
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
					If .cLook != LF
						Error "Expecting line feed character"
					Endif
				Endif
			Endif
		Endwith
	Endfunc
&& ======================================================================== &&
&& ToString
&& ======================================================================== &&
	Function ToString As String
		lcTokenStr = ""
		With This
			Do Case
			Case .Token.Code = .TokenCode.LeftCurleyBracket
				lcTokenStr = "special: <'{'>"
			Case .Token.Code = .TokenCode.RightCurleyBracket
				lcTokenStr = "special: <'}'>"
			Case .Token.Code = .TokenCode.LeftBracket
				lcTokenStr = "special: <'['>"
			Case .Token.Code = .TokenCode.RightBracket
				lcTokenStr = "special: <']'>"
			Case .Token.Code = .TokenCode.Colon
				lcTokenStr = "special: <':'>"
			Case .Token.Code = .TokenCode.Comma
				lcTokenStr = "special: <','>"
			Case .Token.Code = .TokenCode.String
				lcTokenStr = "string: <'" + Transform(.Token.Value) + "'>"
			Case .Token.Code = .TokenCode.Integer
				lcTokenStr = "integer: <'" + Transform(.Token.Value) + "'>"
			Case .Token.Code = .TokenCode.Float
				lcTokenStr = "float: <'" + Transform(.Token.Value) + "'>"
			Case .Token.Code = .TokenCode.True
				lcTokenStr = "boolean: <'true'>"
			Case .Token.Code = .TokenCode.False
				lcTokenStr = "boolean: <'false'>"
			Case .Token.Code = .TokenCode.Null
				lcTokenStr = "null: <'null'>"
			Case .Token.Code = .TokenCode.Key
				lcTokenStr = "key: <'" + Transform(.Token.Value) + "'>"
			Case .Token.Code = .TokenCode.Value
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
		Local loTokenCode As Object, lcTokenStr As String
		loTokenCode = This.TokenCode
		lcTokenStr  = ""
		Do Case
		Case tnToken = loTokenCode.EndOfStream
			lcTokenStr = "EOF"
		Case tnToken = loTokenCode.LeftCurleyBracket
			lcTokenStr = "{"
		Case tnToken = loTokenCode.RightCurleyBracket
			lcTokenStr = "}"
		Case tnToken = loTokenCode.LeftBracket
			lcTokenStr = "["
		Case tnToken = loTokenCode.RightBracket
			lcTokenStr = "]"
		Case tnToken = loTokenCode.Colon
			lcTokenStr = ":"
		Case tnToken = loTokenCode.Comma
			lcTokenStr = ","
		Case tnToken = loTokenCode.String
			lcTokenStr = "STRING"
		Case tnToken = loTokenCode.Integer
			lcTokenStr = "INTEGER"
		Case tnToken = loTokenCode.Float
			lcTokenStr = "FLOAT"
		Case tnToken = loTokenCode.True
			lcTokenStr = "true"
		Case tnToken = loTokenCode.False
			lcTokenStr = "false"
		Case tnToken = loTokenCode.Null
			lcTokenStr = "null"
		Case tnToken = loTokenCode.Key
			lcTokenStr = "KEY"
		Case tnToken = loTokenCode.Value
			lcTokenStr = "VALUE"
		Otherwise
			lcTokenStr = "UNKNOWN"
		Endcase
		Return lcTokenStr
	Endfunc
&& ======================================================================== &&
&& Function Peek
&& Return the next token without affecting the current one.
&& ======================================================================== &&
	Function Peek As Object
		With This
			Local nCurrentPos As Integer, loCurToken As Object, lcCurLook As Character
* Default PeekToken values
			With .PeekToken
				.LineNumber   = 0
				.ColumnNumber = 0
				.Code 		  = 0
				.Value 		  = 0
			Endwith
* Save current token values
			nCurrentPos = .Reader.GetPosition()
			loCurToken  = .Token
			lcCurLook   = .cLook
			.NextToken()
* Store the peeked token
			With .PeekToken
				Local loToken As Object
				loToken = This.Token
				.LineNumber   = loToken.LineNumber
				.ColumnNumber = loToken.ColumnNumber
				.Code 		  = loToken.Code
				.Value 		  = loToken.Value
				Release loToken
			Endwith
* Restore the current position
			.Reader.SetPosition(nCurrentPos)
* Restore the current token
			With .Token
				.LineNumber   = loCurToken.LineNumber
				.ColumnNumber = loCurToken.ColumnNumber
				.Code 		  = loCurToken.Code
				.Value 		  = loCurToken.Value
			Endwith
			.cLook = lcCurLook
			Return .PeekToken
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function Destroy
&& ======================================================================== &&
	Function Destroy
		This.Reader = .Null.
		Try
			Clear Class StreamReader
		Catch
		Endtry
		Try
			Release Procedure StreamReader
		Catch
		Endtry
		Try
			Release Procedure EnumType
		Catch
		Endtry
	Endfunc
Enddefine
