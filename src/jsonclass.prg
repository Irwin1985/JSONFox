* JSONClass
define class JSONClass as session
	datasession 	= 1
	LastErrorText 	= ""
	lError 			= .f.
	lShowErrors 	= .t.
	version 		= "8.0"
	hidden lInternal
	hidden lTablePrompt
	&& >>>>>>> IRODG 07/01/21
	* Set this property to .T. if you want the lexer uses JSONFoxHelper.dll
	NETScanner = .f.
	&& <<<<<<< IRODG 07/01/21

	*Function Init
	function init
		with this
			.ResetError()
			.lTablePrompt = set("TablePrompt") == "ON"
			set tableprompt off
		endwith
	endfunc

	* Parse the string text as JSON
	function Parse as memo
		lparameters tcJsonStr as memo
		local loJSONObj as object
		loJSONObj = .null.
		try
			this.ResetError()
			local lexer, parser
			if this.NETScanner
				lexer = createobject("NetScanner", tcJsonStr)
			else
				lexer = createobject("Tokenizer", tcJsonStr)
			endif
			parser = createobject("Parser", lexer)
			loJSONObj = parser.Parse()
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			store .null. to lexer, parser
			release lexer, parser
		endtry
		return loJSONObj
	endfunc

	* Stringify
	function Stringify as memo
		lparameters tvNewVal as Variant, tcFlags as string, tlParseUtf8
		this.ResetError()
		local llParseUtf8, lcTypeFlag, loJSONStr as memo
		lcTypeFlag = type('tcFlags')
		llParseUtf8 = iif(lcTypeFlag = 'L', tcFlags, tlParseUtf8)
		loJSONStr = ""

		if vartype(tvNewVal) = "O"
			try
				local objToJson
				objToJson = createobject("ObjectToJson")
				tvNewVal = objToJson.Encode(@tvNewVal, iif(lcTypeFlag != 'C', .f., tcFlags))
			catch to loEx
				this.ShowExceptionError(loEx)
			finally
				objToJson = .null.
				release objToJson
			endtry
		endif

		try
			local lexer, parser
			lexer = createobject("Tokenizer", tvNewVal)
			parser = createobject("JSONStringify", lexer)
			loJSONStr = parser.Stringify(llParseUtf8)
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			store .null. to lexer, parser
			release lexer, parser
		endtry
		return loJSONStr
	endfunc

	* JSONToRTF
	function JSONToRTF as memo
		lparameters tvNewVal as Variant, tnIndent as Boolean
		this.ResetError()
		if vartype(tvNewVal) = 'O'
			try
				local objToJson
				objToJson = createobject("ObjectToJson")
				tvNewVal = objToJson.Encode(@tvNewVal)
			catch to loEx
				this.ShowExceptionError(loEx)
			finally
				objToJson = .null.
				release objToJson
			endtry
		endif
		local loJSONStr as memo
		loJSONStr = ''
		try
			this.lError = .f.
			this.LastErrorText = ''
			local lexer, parser
			lexer = createobject("Tokenizer", tvNewVal)
			parser = createobject("JSONToRTF", lexer)
			parser.lShowErrors = this.lShowErrors
			loJSONStr = parser.StrToRTF(tnIndent)
			this.lError = parser.lError
			this.LastErrorText = parser.cErrorMsg
		catch to loEx
			this.ShowExceptionError(loEx)
			this.lError = .t.
			this.LastErrorText = loEx.message
		finally
			store .null. to lexer, parser
			release lexer, parser
		endtry
		return loJSONStr
	endfunc

	* JSONViewer
	function JSONViewer as Void
		lparameters tcJsonStr as memo, tlStopExecution as Boolean
		do form frmJSONViewer with tcJsonStr, tlStopExecution
		if tlStopExecution
			read events
		endif
	endfunc
	*  ====================== Old JSONFox Functions =========================== *
	*  . . . . . . . . . . For backward compatibility . . . . . . . . . . . .
	*  ======================================================================== *
	&& ======================================================================== &&
	&& Function Encode
	&& <<Deprecated>> please use Stringify function instead.
	&& ======================================================================== &&
	function Encode(toObj as object, tcFlags as string) as memo
		local loEncode
		loEncode = createobject("ObjectToJson")
		return loEncode.Encode(@toObj, tcFlags)
	endfunc
	&& ======================================================================== &&
	&& Function decode
	&& <<Deprecated>> please use Parse function instead.
	&& ======================================================================== &&
	function Decode(tcJsonStr as memo) as object
		return this.Parse(tcJsonStr)
	endfunc
	&& ======================================================================== &&
	&& Function LoadFile
	&& <<Deprecated>> please use Parse function instead.
	&& ======================================================================== &&
	function LoadFile(tcJsonFile as string) as object
		return this.Decode(filetostr(tcJsonFile))
	endfunc
	* ArrayToXML
	function ArrayToXML(tcArray as memo) as string
		local lcOut as string, lcCursor
		lcOut = ''
		lcCursor = SYS(2015)
		if vartype(tcArray) = 'O'
			try
				local objToJson
				objToJson = createobject("ObjectToJson")
				tcArray = objToJson.Encode(@tcArray)
			catch to loEx
				this.ShowExceptionError(loEx)
			finally
				objToJson = .null.
				release objToJson
			endtry
		endif
		try
			this.jsonToCursor(tcArray, lcCursor, set("Datasession"))
			if used(lcCursor)
				=cursortoxml(lcCursor, 'lcOut', 1, 0, 0, '1')
			endif
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			use in (select(lcCursor))
		endtry
		return lcOut
	endfunc
	* XMLToJson
	function XMLToJson(tcXML as memo) as memo
		local lcJsonXML as memo, loParser
		lcJsonXML = ''
		try
			this.ResetError()
			=xmltocursor(tcXML, 'qXML')
			loParser = createobject("CursorToArray")
			loParser.CurName 	 = "qXML"
			loParser.nSessionID = set("Datasession")
			lcJsonXML = loParser.CursorToArray()
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			loParser = .null.
			release loParser
			use in (select("qXML"))
		endtry
		return lcJsonXML
	endfunc
	* CursorToJSON
	function CursorToJSON as memo
		lparameters tcCursor as string, tbCurrentRow as Boolean, tnDataSession as integer, tlJustArray as Boolean
		local lcJsonXML as memo, loParser, lcCursor
		lcJsonXML = ''
		lcCursor  = SYS(2015)
		try
			this.ResetError()
			tcCursor = evl(tcCursor, alias())
			tnDataSession = evl(tnDataSession, set("Datasession"))
			set datasession to tnDataSession
			if tbCurrentRow
				lnRecno = recno(tcCursor)
				select * from (tcCursor) where recno() = lnRecno into cursor (lcCursor)
			else
				select * from (tcCursor) into cursor (lcCursor)
			endif
			loParser = createobject("CursorToArray")
			loParser.CurName 	 = lcCursor
			loParser.nSessionID  = tnDataSession
			lcJsonXML = loParser.CursorToArray()
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			loParser = .null.
			release loParser
			use in (select(lcCursor))
		endtry
		lcOutput = iif(tlJustArray, lcJsonXML, '{"' + lower(alltrim(tcCursor)) + '":' + lcJsonXML + '}')
		return lcOutput
	endfunc
	* JSONToCursor
	function jsonToCursor(tcJsonStr as memo, tcCursor as string, tnDataSession as integer) as Void
		try
			local lexer, parser
			this.ResetError()
			if !empty(tcCursor)
				tnDataSession = evl(tnDataSession, set("Datasession"))
				lexer = createobject("Tokenizer", tcJsonStr)
				parser = createobject("ArrayToCursor", lexer)
				parser.CurName 	  = tcCursor
				parser.nSessionID = tnDataSession
				parser.array()
			else
				if this.lShowErrors
					wait "Invalid cursor name." window nowait
				endif
			endif
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			store .null. to lexer, parser
			release lexer, parser
		endtry
	endfunc
	* CursorStructure
	function CursorStructure
		lparameters tcCursor as string, tnDataSession as integer, tlCopyExtended as Boolean
		local lcOutput as memo
		lcOutput = ''
		try
			this.ResetError()
			loStructureToJSON = createobject("StructureToJSON")
			tcCursor = evl(tcCursor, alias())
			tnDataSession = evl(tnDataSession, set("Datasession"))
			loStructureToJSON.CurName 	= tcCursor
			loStructureToJSON.nSessionID  = tnDataSession
			loStructureToJSON.lExtended   = tlCopyExtended
			lcOutput = loStructureToJSON.StructureToJSON()
		catch to loEx
			this.ShowExceptionError(loEx)
		endtry
		return lcOutput
	endfunc
	* tokenize
	function dumpTokens	
		lparameters tcJsonStr as memo
		local loJSONObj as object
		loJSONObj = .null.
		try
			this.ResetError()
			local loLexer, loToken, lcTokens as memo
			loLexer = createobject("Tokenizer", tcJsonStr)
			loToken = loLexer.Next_Token()
			lcTokens = ''
			do while loToken.type != 0
				lcTokens = lcTokens + loLexer.tokenStr(loToken) + CHR(13) + CHR(10)
				loToken = loLexer.Next_Token()
			enddo
			lcTokens = lcTokens + loLexer.tokenStr(loToken) + CHR(13) + CHR(10)
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			store .null. to lexer, parser
			release lexer, parser
		endtry
		_cliptext = lcTokens
		return lcTokens
	endfunc
	* LastErrorText_Assign
	function LastErrorText_Assign
		lparameters vNewVal
		with this
			if .lInternal
				.lInternal = .f.
				.LastErrorText = m.vNewVal
			endif
		endwith
	endfunc
	* ShowExceptionError
	function ShowExceptionError(toEx as exception) as Void
		with this
			.lError = .t.
			if .lShowErrors
				wait "ErrorNo: " 	+ str(toEx.errorno) 	+ chr(13) + ;
					"Message: " 	+ toEx.message 			+ chr(13) + ;
					"LineNo: " 		+ str(toEx.lineno) 		+ chr(13) + ;
					"Procedure: " 	+ toEx.procedure window nowait
			endif
			.lInternal = .t.
			.LastErrorText = toEx.message
		endwith
	endfunc
	* ResetError
	hidden function ResetError as Void
		this.lError = .f.
	endfunc
	* Destroy
	function destroy
		try
			if this.lTablePrompt
				lcTablePrompt = this.lTablePrompt
				set tableprompt &lcTablePrompt
			endif
		catch
		endtry
		&& >>>>>>> IRODG 12/28/21
		try
			removeproperty(_screen, 'json')
		catch
		endtry
		try
			removeproperty(_screen, 'jsonutils')
		catch
		endtry
		try
			removeproperty(_screen, 'oregex')
		catch
		endtry
		try
			removeproperty(_screen, 'toml')
		catch
		endtry
		&& <<<<<<< IRODG 12/28/21
	endfunc
enddefine
