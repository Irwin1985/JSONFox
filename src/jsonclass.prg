* JSONClass
define class JSONClass as session
	datasession 	= 1
	LastErrorText 	= ""
	lError 			= .f.
	lShowErrors 	= .t.
	version 		= "13.1"
	hidden lInternal
	hidden lTablePrompt
	dimension aCustomArray[1]
&& >>>>>>> IRODG 07/01/21
* Set this property to .T. if you want the lexer uses JSONFoxHelper.dll
	NETScanner = .f.
&& <<<<<<< IRODG 07/01/21

&& >>>>>>> IRODG 02/27/24
	JScriptScanner = .f.
	UseArrayObjects = .t.
&& <<<<<<< IRODG 02/27/24

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

		local loJSONObj&&, loEnv
		loJSONObj = .null.
		dimension this.aCustomArray[1]
		this.aCustomArray[1] = .null.
		try
			&&loEnv = this.saveEnvironment()
			this.ResetError()
			local lexer, parser
			do case
			case this.NETScanner
				lexer = createobject("NetScanner", tcJsonStr)
			case this.JScriptScanner
				lexer = createobject("JScriptScanner", tcJsonStr)
			otherwise
				lexer = createobject("Tokenizer", tcJsonStr)
			endcase
			parser = createobject("Parser", lexer, this.UseArrayObjects)
			loJSONObj = parser.Parse()
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			&&this.restoreEnvironment(loEnv)
			store .null. to lexer, parser
			release lexer, parser
		endtry
		if type('loJSONObj', 1) == 'A'
			local i
			for i = 1 to alen(loJSONObj, 1)
				dimension this.aCustomArray[i]
				this.aCustomArray[i] = loJSONObj[i]
			endfor
			return @this.aCustomArray
		else
			return loJSONObj
		endif
	endfunc

* tokenize
	function dumpTokens
		lparameters tcJsonStr as memo, tcOutput as string
		&&local loEnv
		try
			&&loEnv = this.saveEnvironment()
			this.ResetError()
			local lexer, nativeScanner
			do case
			case this.NETScanner
				lexer = createobject("NetScanner", tcJsonStr)
			case this.JScriptScanner
				lexer = createobject("JScriptScanner", tcJsonStr)
			otherwise
				nativeScanner = .t.
				lexer = createobject("Tokenizer", tcJsonStr)
			endcase
			local laTokenCollection
			laTokenCollection = lexer.scanTokens()
			if file(tcOutput)
				delete file (tcOutput)
			endif
			for each loToken in laTokenCollection.Tokens
				strtofile(tokenStr(loToken), tcOutput, 1)
			endfor
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			&&this.restoreEnvironment(loEnv)
			release lexer, laTokenCollection
		endtry
	endfunc

* Stringify
	function Stringify as memo
		lparameters tvNewVal as Variant, tcFlags as string, tlParseUtf8 as Boolean, tlTrimChars as Boolean
		this.ResetError()
		local llParseUtf8, lcTypeFlag, loJSONStr as memo&&, loEnv
		lcTypeFlag = type('tcFlags')
		llParseUtf8 = iif(lcTypeFlag = 'L', tcFlags, tlParseUtf8)
		loJSONStr = ""
		if vartype(tvNewVal) = "O"
			try
				&&loEnv = this.saveEnvironment()
				local objToJson
				objToJson = createobject("ObjectToJson")
				tvNewVal = objToJson.Encode(@tvNewVal, iif(lcTypeFlag != 'C', .f., tcFlags))
			catch to loEx
				this.ShowExceptionError(loEx)
			finally
				&&this.restoreEnvironment(loEnv)
				objToJson = .null.
				release objToJson
			endtry
		endif
		try
			&&loEnv = this.saveEnvironment()
			local lexer, parser
			lexer = createobject("Tokenizer", tvNewVal)
			parser = createobject("JSONStringify", lexer)
			loJSONStr = parser.Stringify(llParseUtf8, tlTrimChars)
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			&&this.restoreEnvironment(loEnv)
			store .null. to lexer, parser
			release lexer, parser
		endtry
		return loJSONStr
	endfunc

* JSONToRTF
	function JSONToRTF as memo
		lparameters tvNewVal as Variant, tnIndent as Boolean
		&&local loEnv

		this.ResetError()
		if vartype(tvNewVal) = 'O'
			try
				&&loEnv = this.saveEnvironment()
				local objToJson
				objToJson = createobject("ObjectToJson")
				tvNewVal = objToJson.Encode(@tvNewVal)
			catch to loEx
				this.ShowExceptionError(loEx)
			finally
				&&this.restoreEnvironment(loEnv)
				objToJson = .null.
				release objToJson
			endtry
		endif
		local loJSONStr as memo
		loJSONStr = ''
		try
			&&loEnv = this.saveEnvironment()
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
			&&this.restoreEnvironment(loEnv)
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
	function Encode(toObj as object, tcFlags as string, tlUtf8 as Boolean, tlTrimChars as Boolean) as memo
		try
			&&local loEnv
			&&loEnv = this.saveEnvironment()
			this.ResetError()

			local loEncode, loResult
			loEncode = createobject("ObjectToJson")
			loResult = loEncode.Encode(@toObj, tcFlags, tlUtf8, tlTrimChars)
			if type('loResult') == 'C' and !empty(loResult)
				loResult = strconv(loResult, 9)
			endif
		catch to loEx
			this.ShowExceptionError(loEx)
			this.lError = .t.
			this.LastErrorText = loEx.message
		finally
			&&this.restoreEnvironment(loEnv)
			loEncode = null
			release loEncode
		endtry
		return loResult
	endfunc
&& ======================================================================== &&
&& Function decode
&& <<Deprecated>> please use Parse function instead.
&& ======================================================================== &&
	function Decode(tcJsonStr as memo) as object
		try
			&&local loEnv, loResult
			&&loEnv = this.saveEnvironment()
			this.ResetError()
			loResult = this.Parse(tcJsonStr)
		catch to loEx
			this.ShowExceptionError(loEx)
			this.lError = .t.
			this.LastErrorText = loEx.message
		finally
			&&this.restoreEnvironment(loEnv)
		endtry
		return loResult
	endfunc
&& ======================================================================== &&
&& Function LoadFile
&& <<Deprecated>> please use Parse function instead.
&& ======================================================================== &&
	function LoadFile(tcJsonFile as string) as object
		try
			&&local loEnv, loResult
			&&loEnv = this.saveEnvironment()
			this.ResetError()
			loResult = this.Decode(filetostr(tcJsonFile))
		catch to loEx
			this.ShowExceptionError(loEx)
			this.lError = .t.
			this.LastErrorText = loEx.message
		finally
			&&this.restoreEnvironment(loEnv)
		endtry
		return loResult
	endfunc
* ArrayToXML
	function ArrayToXML(tcArray as memo) as string
		local lcOut as string, lcCursor&&, loEnv
		lcOut = ''
		lcCursor = sys(2015)
		if vartype(tcArray) = 'O'
			try
				&&loEnv = this.saveEnvironment()
				local objToJson
				objToJson = createobject("ObjectToJson")
				tcArray = objToJson.Encode(@tcArray)
			catch to loEx
				this.ShowExceptionError(loEx)
			finally
				&&this.restoreEnvironment(loEnv)
				objToJson = .null.
				release objToJson
			endtry
		endif
		try
			&&loEnv = this.saveEnvironment()
			this.jsonToCursor(tcArray, lcCursor, set("Datasession"))
			if used(lcCursor)
				=cursortoxml(lcCursor, 'lcOut', 1, 0, 0, '1')
			endif
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			&&this.restoreEnvironment(loEnv)
			use in (select(lcCursor))
		endtry
		return lcOut
	endfunc
* XMLToJson
	function XMLToJson(tcXML as memo) as memo
		local lcJsonXML as memo, loParser&&, loEnv
		lcJsonXML = ''
		try
			&&loEnv = this.saveEnvironment()
			this.ResetError()
			=xmltocursor(tcXML, 'qXML')
			loParser = createobject("CursorToArray")
			loParser.CurName 	= "qXML"
			loParser.nSessionID = set("Datasession")
			loParser.ParseUTF8  = .t.
			loParser.TrimChars  = .t.
			lcJsonXML = loParser.CursorToArray()
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			&&this.restoreEnvironment(loEnv)
			loParser = .null.
			release loParser
			use in (select("qXML"))
		endtry
		return lcJsonXML
	endfunc
* CursorToJSON
	function CursorToJSON as memo
		lparameters tcCursor as string, tbCurrentRow as Boolean, tnDataSession as integer, tlJustArray as Boolean, tlParseUtf8 as Boolean, tlTrimChars as Boolean
		local lcJsonXML as memo, loParser, lcCursor&&, loEnv
		lcJsonXML = ''
		lcCursor  = sys(2015)
		try
			&&loEnv = this.saveEnvironment()
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
&& IRODG 07/10/2023 Inicio
			loParser.ParseUTF8 = tlParseUtf8
&& IRODG 07/10/2023 Fin
&& IRODG 27/10/2023 Inicio
			loParser.TrimChars = tlTrimChars
&& IRODG 27/10/2023 Fin
			lcJsonXML = loParser.CursorToArray()
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			&&this.restoreEnvironment(loEnv)
			loParser = .null.
			release loParser
			use in (select(lcCursor))
		endtry
		lcOutput = iif(tlJustArray, lcJsonXML, '{"' + lower(alltrim(tcCursor)) + '":' + lcJsonXML + '}')
		return lcOutput
	endfunc

* CursorToJSONObject
	function CursorToJSONObject(tcCursor as string, tbCurrentRow as Boolean, tnDataSession as integer) as object
		local loParser, lcCursor, lnRecno, loResult as Variant&&, loEnv
		lcCursor = sys(2015)
		try
			&&loEnv = this.saveEnvironment()
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
			loParser = createobject("CursorToJsonObject")
			loParser.CurName 	 = lcCursor
			loParser.nSessionID  = tnDataSession
			loResult = loParser.CursorToJSONObject()
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			&&this.restoreEnvironment(loEnv)
			loParser = .null.
			release loParser
			use in (select(lcCursor))
		endtry

		if type('loResult', 1) == 'A'
			local i
			for i = 1 to alen(loResult, 1)
				dimension this.aCustomArray[i]
				this.aCustomArray[i] = loResult[i]
			endfor
			return @this.aCustomArray
		else
			return loResult
		endif
	endfunc

	function MasterDetailToJSON(tcMaster as string, tcDetail as string, tcExpr as string, tcDetailAttribute as string, tnSessionID as integer)
		local loClass, loResult, lcResult&&, loEnv
		try
			&&loEnv = this.saveEnvironment()
			this.ResetError()
			tnSessionID = evl(tnSessionID, set("Datasession"))
			set datasession to tnSessionID
			loClass  = createobject("CursorToJsonObject")
			loResult = loClass.MasterDetailToJSON(tcMaster, tcDetail, tcExpr, tcDetailAttribute, tnSessionID)
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			&&this.restoreEnvironment(loEnv)
			loClass = .null.
			release loClass
		endtry
*lcResult = this.stringify(@loResult)
		lcResult = this.Encode(@loResult, "", .t., .t.)
		return lcResult
	endfunc

* JSONToCursor
	function jsonToCursor(tcJsonStr as memo, tcCursor as string, tnDataSession as integer) as Void
		try
			local lexer, parser, loEnv
			this.ResetError()
			loEnv = this.saveEnvironment()
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
			this.restoreEnvironment(loEnv)
			store .null. to lexer, parser
			release lexer, parser
		endtry
	endfunc
* CursorStructure
	function CursorStructure
		lparameters tcCursor as string, tnDataSession as integer, tlCopyExtended as Boolean, tlJustArray as Boolean
		local lcOutput as memo, loEnv
		lcOutput = ''
		try
			loEnv = this.saveEnvironment()
			this.ResetError()
			loStructureToJSON = createobject("StructureToJSON")
			tcCursor = evl(tcCursor, alias())
			tnDataSession = evl(tnDataSession, set("Datasession"))
			loStructureToJSON.CurName 	= tcCursor
			loStructureToJSON.nSessionID  = tnDataSession
			loStructureToJSON.lExtended   = tlCopyExtended
			loStructureToJSON.lJustArray  = tlJustArray
			lcOutput = loStructureToJSON.StructureToJSON()
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			this.restoreEnvironment(loEnv)
		endtry
		return lcOutput
	endfunc
* tokenize
	function dumpTokens2
		lparameters tcJsonStr as memo
		&&local loEnv
		try
			this.ResetError()
			&&loEnv = this.saveEnvironment()
			local loLexer, laTokenCollection, lcTokens as memo, i
			loLexer = createobject("Tokenizer", tcJsonStr)
			laTokenCollection = loLexer.scanTokens()
			lcTokens = ''
			for i = 1 to alen(laTokenCollection.Tokens)
				lcTokens = lcTokens + loLexer.tokenStr(laTokenCollection.Tokens[i]) + chr(13) + chr(10)
			endfor
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			&&this.restoreEnvironment(loEnv)
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

	protected function saveEnvironment
		try
			local loEnv
			loEnv = createobject("Collection")

			loEnv.add(set("POINT"), "point")
			loEnv.add(set("SEPARATOR"), "separator")

			set point to '.'
			set separator to ','
		catch
		endtry
		
		return loEnv
	endproc

	protected procedure restoreEnvironment(toEnv as collection)
		try
			set point to toEnv("point")
			set separator to toEnv("separator")
		catch
		endtry
	endproc
enddefine