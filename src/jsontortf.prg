&& ======================================================================== &&
&& JSONToRTF
&& EBNF		object 	= '{' format kvp | {',' format kvp} '}'
&& 			format 	= JSPACE * nTimes
&& 			kvp		= KEY ':' value | {',' KEY ':' value}
&&			value	= STRING | NUMBER | BOOLEAN | NULL | array | object
&& 			array	= '[' value | {',' value} ']'
&& ======================================================================== &&
Define Class JSONToRTF As Custom
	#Define CRLF Chr(13) + Chr(10) + "\par"
	Hidden sc
	Hidden Token
	Hidden utils
	lIndent = .t.
	lShowErrors = .T.
	lError = .f.
	cErrorMsg = ""
&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
	Function Init
		Lparameters toSC As Object
		Set Procedure To "JsonUtils" Additive
		With This
			.sc     = toSC
			.Token  = toSC.TokenCode
			.utils  = Createobject("JsonUtils")
			.lError = .f.
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function StrToRTF
&& ======================================================================== &&
	Function StrToRTF As Memo
		Lparameters tnIndent as Boolean
		This.lIndent = tnIndent
		this.lError 	= .F.
		this.cErrorMsg 	= ""
		Return This.Object(0)
	Endfunc
&& ======================================================================== &&
&& Function Object
&& EBNF		object 	= '{' format kvp | {',' format kvp} '}'
&& 			format 	= JSPACE * nTimes
&& 			kvp		= KEY ':' value | {',' KEY ':' value}
&&			value	= STRING | NUMBER | BOOLEAN | NULL | array | object
&& 			array	= '[' value | {',' value} ']'
&& ======================================================================== &&
	Hidden Function Object As VOID
		Lparameters tnSpace As Integer
		With This
			.utils.Match(.sc, .Token.LeftCurleyBracket)
			If .sc.Token.Code != .Token.RightCurleyBracket
				Local nSpaceBlock, lcJSON As String
				nSpaceBlock = tnSpace + 1
				lcJSON = "\{" + Iif(This.lIndent, CRLF, "") + .JSFormat(nSpaceBlock)
				lcJSON = lcJSON + .kvp(nSpaceBlock)
				Do While .sc.Token.Code = .Token.Comma
					.sc.NextToken()
					lcJSON = lcJSON + "," + Iif(This.lIndent, CRLF, "") + .JSFormat(nSpaceBlock)
					lcJSON = lcJSON + .kvp(nSpaceBlock)
				Enddo
				lcJSON = lcJSON + Iif(This.lIndent, CRLF, "") + .JSFormat(tnSpace) + "\}"
			Else
				lcJSON = "\{\}"
			EndIf
			.utils.Match(.sc, .Token.RightCurleyBracket)
		Endwith
		Return lcJSON
	Endfunc
&& ======================================================================== &&
&& Hidden Function kvp
&& EBNF		kvp	= KEY ':' value | {',' KEY ':' value}
&& ======================================================================== &&
	Hidden Function kvp
		Lparameters tnSpaceIdent As Integer
		With This
			Local lcProp As String
			lcProp = .sc.Token.Value
			.sc.NextToken()
			.utils.Match(.sc, .Token.Colon)

			Return '\cf2 "' + lcProp + '"\cf1: ' + .Value(tnSpaceIdent)
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function Value
&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | array | object | NULL
&& ======================================================================== &&
	Hidden Function Value As Variant
		Lparameters tnSpaceBlock As Integer
		vNewVal = ""
		With This
			Do Case
			Case .sc.Token.Code = .Token.String
				vNewVal = '\cf5 "' + Alltrim(.sc.Token.Value) + '"\cf1'
				.sc.NextToken()
			Case .sc.Token.Code = .Token.Integer
				vNewVal = "\cf3 " + Alltrim(Str(.sc.Token.Value)) + "\cf1"
				.sc.NextToken()
			Case .sc.Token.Code = .Token.Float
				vNewVal = "\cf3 " + Transform(.sc.Token.Value) + "\cf1"
				.sc.NextToken()
			Case .sc.Token.Code = .Token.True
				vNewVal = "\cf4 true\cf1"
				.sc.NextToken()
			Case .sc.Token.Code = .Token.False
				vNewVal = "\cf4 false\cf1"
				.sc.NextToken()
			Case .sc.Token.Code = .Token.LeftCurleyBracket
				vNewVal = .Object(tnSpaceBlock)
			Case .sc.Token.Code = .Token.LeftBracket
				vNewVal = .Array(tnSpaceBlock)
			Case .sc.Token.Code = .Token.Null
				vNewVal = "null"
				.sc.NextToken()
			Otherwise
				.lError = .T.
				lcMsg = "Parse error on line " + Alltrim(Str(.sc.Token.LineNumber)) + ": Unexpected Token '" + .sc.TokenToStr(.sc.Token.Code) + "'"
				If .lShowErrors
					Error lcMsg
				EndIf
				.cErrorMsg = lcMsg
			Endcase
		Endwith
		Return vNewVal
	Endfunc
&& ======================================================================== &&
&& Function Array
&& EBNF -> 	array = '[' value | { ',' value }  ']'
&& ======================================================================== &&
	Hidden Function Array As VOID
		Lparameters tnIdentation As Integer
		Local lcArrayStr As String
		lcArrayStr = ""
		With This
			.utils.Match(.sc, .Token.LeftBracket)
			If .sc.Token.Code != .Token.RightBracket
				Local lnBlock As Integer
				lnBlock = tnIdentation + 1
				lcArrayStr = "[" + Iif(This.lIndent, CRLF, "") + .JSFormat(lnBlock)
				lcArrayStr = lcArrayStr + .Value(lnBlock)
				Do While .sc.Token.Code = .Token.Comma
					.sc.NextToken()
					lcArrayStr = lcArrayStr + "," + Iif(This.lIndent, CRLF, "") + .JSFormat(lnBlock)
					lcArrayStr = lcArrayStr + .Value(lnBlock)
				Enddo
				lcArrayStr = lcArrayStr + Iif(This.lIndent, CRLF, "") + .JSFormat(tnIdentation) + "]"
			Else
				lcArrayStr = "[]"
			EndIf
			.utils.Match(.sc, .Token.RightBracket)
		Endwith
		Return lcArrayStr
	Endfunc
&& ======================================================================== &&
&& Hidden Function JSFormat
&& ======================================================================== &&
	Hidden Function JSFormat As String
		Lparameters tnSpaceMult As Integer
		Return Iif(This.lIndent, Space(tnSpaceMult * 2), "")
	Endfunc
&& ======================================================================== &&
&& Function Destroy
&& ======================================================================== &&
	Function Destroy
		Try
			This.sc = .Null.
		Catch
		Endtry
		Try
			This.Token = .Null.
		Catch
		Endtry
		Try
			This.utils = .Null.
		Catch
		Endtry
		Try
			Clear Class JsonUtils
		Catch
		Endtry
		Try
			Release Procedure JsonUtils
		Catch
		Endtry
	Endfunc
Enddefine