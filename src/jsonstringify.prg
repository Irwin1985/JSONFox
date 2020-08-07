&& ======================================================================== &&
&& Stringify
&& EBNF		object 	= '{' format kvp | {',' format kvp} '}'
&& 			format 	= JSPACE * nTimes
&& 			kvp		= KEY ':' value | {',' KEY ':' value}
&&			value	= STRING | NUMBER | BOOLEAN | NULL | array | object
&& 			array	= '[' value | {',' value} ']'
&& ======================================================================== &&
Define Class JSONStringify As Custom
	#Define CRLF Chr(13) + Chr(10)
	Hidden sc
	Hidden Token
	Hidden utils
&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
	Function Init
		Lparameters toSC As Object
		Set Procedure To "JsonUtils" Additive
		With This
			.sc    = toSC
			.Token = toSC.TokenList
			.utils = Createobject("JsonUtils")
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function Stringify
&& ======================================================================== &&
	Function Stringify As Memo
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
				lcJSON = "{" + CRLF + .JSFormat(nSpaceBlock)
				lcJSON = lcJSON + .kvp(nSpaceBlock)
				Do While .sc.Token.Code = .Token.Comma
					.sc.NextToken()
					lcJSON = lcJSON + "," + CRLF + .JSFormat(nSpaceBlock)
					lcJSON = lcJSON + .kvp(nSpaceBlock)
				EndDo
				lcJSON = lcJSON + CRLF + .JSFormat(tnSpace) + "}"
			Else
				lcJSON = "{}"
			Endif
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

			Return '"' + lcProp + '": ' + .Value(tnSpaceIdent)
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
				vNewVal = '"' + Alltrim(.sc.Token.Value) + '"'
				.sc.NextToken()
			Case .sc.Token.Code = .Token.Integer
				vNewVal = Alltrim(Str(.sc.Token.Value))
				.sc.NextToken()
			Case .sc.Token.Code = .Token.Float
				vNewVal = Transform(.sc.Token.Value)
				.sc.NextToken()
			Case .sc.Token.Code = .Token.True
				vNewVal = "true"
				.sc.NextToken()
			Case .sc.Token.Code = .Token.False
				vNewVal = "false"
				.sc.NextToken()
			Case .sc.Token.Code = .Token.LeftCurleyBracket
				vNewVal = .Object(tnSpaceBlock)
			Case .sc.Token.Code = .Token.LeftBracket
				vNewVal = .Array(tnSpaceBlock)
			Case .sc.Token.Code = .Token.Null
				vNewVal = "null"
				.sc.NextToken()
			Otherwise
				lcMsg = "Parse error on line " + Alltrim(Str(.sc.Token.LineNumber)) + ": Unexpected Token '" + .sc.TokenToStr(.sc.Token.Code) + "'"
				Error lcMsg
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
				lcArrayStr = "[" + CRLF + .JSFormat(lnBlock)
				lcArrayStr = lcArrayStr + .Value(lnBlock)
				Do While .sc.Token.Code = .Token.Comma
					.sc.NextToken()
					lcArrayStr = lcArrayStr + "," + CRLF + .JSFormat(lnBlock)
					lcArrayStr = lcArrayStr + .Value(lnBlock)
				EndDo
				lcArrayStr = lcArrayStr + CRLF + .JSFormat(tnIdentation) + "]"
			Else
				lcArrayStr = "[]"
			Endif
			.utils.Match(.sc, .Token.RightBracket)			
		Endwith
		Return lcArrayStr
	Endfunc
&& ======================================================================== &&
&& Hidden Function JSFormat
&& ======================================================================== &&
	Hidden Function JSFormat As String
		Lparameters tnSpaceMult As Integer
		Return Space(tnSpaceMult * 2)
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
