* JSONFox - Self-contained standalone facade
* Usage: jsonFox = NEWOBJECT("JSONFox", "JsonFox.fxp")
define class JSONFox as session
	datasession     = 1
	lError          = .f.
	cLastError      = ""
	UseArrayObjects = .t.
	version         = "13.1"
	hidden oUtils
	hidden lTablePrompt
	dimension aCustomArray[1]

	function init
		this.aCustomArray[1] = .null.
		this.oUtils       = createobject("JSONUtils")
		this.lTablePrompt = set("TablePrompt") == "ON"
		set tableprompt off
	endfunc

	* -- Internal helpers --

	hidden function CreateLexer(tcSource)
		local loLexer
		loLexer = createobject("Tokenizer", tcSource)
		loLexer.oUtils = this.oUtils
		return loLexer
	endfunc

	hidden function ResetError
		this.lError    = .f.
		this.cLastError = ""
	endfunc

	hidden function SetError(tcMsg)
		this.lError    = .t.
		this.cLastError = tcMsg
	endfunc

	hidden function saveEnvironment
		local loEnv
		loEnv = createobject("Collection")
		loEnv.add(set("POINT"),     "point")
		loEnv.add(set("SEPARATOR"), "separator")
		set point to '.'
		set separator to ','
		return loEnv
	endfunc

	hidden procedure restoreEnvironment(toEnv)
		try
			set point to toEnv("point")
			set separator to toEnv("separator")
		catch
		endtry
	endproc

	* -- Public API --

	* Parse
	* Fail-fast: JSON syntax errors propagate as VFP errors so the caller
	* can wrap in TRY/CATCH if needed; type errors are immediate.
	function Parse(tcJsonStr)
		local loResult, loLexer, loParser
		loResult = .null.
		this.ResetError()
		dimension this.aCustomArray[1]
		this.aCustomArray[1] = .null.
		if !inlist(vartype(tcJsonStr), 'C', 'M')
			error "JSONFox.Parse: argument must be a string."
		endif
		loLexer  = this.CreateLexer(tcJsonStr)
		loParser = createobject("Parser", loLexer, this.UseArrayObjects)
		loParser.oUtils = this.oUtils
		loResult = loParser.Parse()
		store .null. to loLexer, loParser
		release loLexer, loParser
		if type('loResult', 1) == 'A'
			local i
			for i = 1 to alen(loResult, 1)
				dimension this.aCustomArray[i]
				this.aCustomArray[i] = loResult[i]
			endfor
			return @this.aCustomArray
		endif
		return loResult
	endfunc

	* Stringify
	function Stringify(tvNewVal, tcFlags, tlParseUtf8, tlTrimChars)
		local lcResult, lcTypeFlag, llParseUtf8, loObjToJson, loLexer, loParser
		lcResult    = ""
		this.ResetError()
		lcTypeFlag  = vartype(tcFlags)
		llParseUtf8 = iif(lcTypeFlag = 'L', tcFlags, tlParseUtf8)
		if vartype(tvNewVal) = "O"
			loObjToJson = createobject("ObjectToJson")
			loObjToJson.oUtils = this.oUtils
			tvNewVal = loObjToJson.Encode(@tvNewVal, iif(lcTypeFlag != 'C', .f., tcFlags))
			loObjToJson = .null.
			release loObjToJson
		endif
		loLexer  = this.CreateLexer(tvNewVal)
		loParser = createobject("JSONStringify", loLexer)
		loParser.oUtils = this.oUtils
		lcResult = loParser.Stringify(llParseUtf8, tlTrimChars)
		store .null. to loLexer, loParser
		release loLexer, loParser
		return lcResult
	endfunc

	* CursorToJSON - soft errors: invalid/closed cursor sets lError
	function CursorToJSON(tcCursor, tbCurrentRow, tnDataSession, tlJustArray, tlParseUtf8, tlTrimChars)
		local lcResult, lcTmp, lnRecno, loParser
		lcResult = ""
		this.ResetError()
		try
			tcCursor      = evl(tcCursor, alias())
			tnDataSession = evl(tnDataSession, set("Datasession"))
			if empty(tcCursor) or !used(tcCursor)
				this.SetError("CursorToJSON: cursor '" + tcCursor + "' is not in use.")
				return ""
			endif
			set datasession to tnDataSession
			lcTmp = sys(2015)
			if tbCurrentRow
				lnRecno = recno(tcCursor)
				select * from (tcCursor) where recno() = lnRecno into cursor (lcTmp)
			else
				select * from (tcCursor) into cursor (lcTmp)
			endif
			loParser = createobject("CursorToArray")
			loParser.CurName    = lcTmp
			loParser.nSessionID = tnDataSession
			loParser.ParseUTF8  = m.tlParseUtf8
			loParser.TrimChars  = m.tlTrimChars
			loParser.oUtils     = this.oUtils
			lcResult = loParser.CursorToArray()
			loParser = .null.
			release loParser
			use in (select(lcTmp))
		catch to loEx
			this.SetError(loEx.message)
		endtry
		return iif(m.tlJustArray, lcResult, '{"' + lower(alltrim(tcCursor)) + '":' + lcResult + '}')
	endfunc

	* JSONToCursor
	* Fail-fast: empty cursor name; soft: parse/data errors set lError
	function JSONToCursor(tcJsonStr, tcCursor, tnDataSession)
		local loEnv, loLexer, loParser
		this.ResetError()
		if empty(tcCursor)
			error "JSONFox.JSONToCursor: cursor name cannot be empty."
		endif
		loEnv = this.saveEnvironment()
		try
			tnDataSession = evl(tnDataSession, set("Datasession"))
			loLexer  = this.CreateLexer(tcJsonStr)
			loParser = createobject("ArrayToCursor", loLexer)
			loParser.oUtils     = this.oUtils
			loParser.CurName    = tcCursor
			loParser.nSessionID = tnDataSession
			loParser.array()
		catch to loEx
			this.SetError(loEx.message)
		finally
			this.restoreEnvironment(loEnv)
			store .null. to loLexer, loParser
			release loLexer, loParser
		endtry
	endfunc

	* CursorToJSONObject
	function CursorToJSONObject(tcCursor, tbCurrentRow, tnDataSession)
		local loResult, lcTmp, lnRecno, loParser
		loResult = .null.
		this.ResetError()
		try
			tcCursor      = evl(tcCursor, alias())
			tnDataSession = evl(tnDataSession, set("Datasession"))
			if empty(tcCursor) or !used(tcCursor)
				this.SetError("CursorToJSONObject: cursor '" + tcCursor + "' is not in use.")
				return .null.
			endif
			set datasession to tnDataSession
			lcTmp = sys(2015)
			if tbCurrentRow
				lnRecno = recno(tcCursor)
				select * from (tcCursor) where recno() = lnRecno into cursor (lcTmp)
			else
				select * from (tcCursor) into cursor (lcTmp)
			endif
			loParser = createobject("CursorToJsonObject")
			loParser.CurName    = lcTmp
			loParser.nSessionID = tnDataSession
			loResult = loParser.CursorToJSONObject()
			loParser = .null.
			release loParser
			use in (select(lcTmp))
		catch to loEx
			this.SetError(loEx.message)
		endtry
		if type('loResult', 1) == 'A'
			local i
			for i = 1 to alen(loResult, 1)
				dimension this.aCustomArray[i]
				this.aCustomArray[i] = loResult[i]
			endfor
			return @this.aCustomArray
		endif
		return loResult
	endfunc

	* CursorStructure
	function CursorStructure(tcCursor, tnDataSession, tlCopyExtended, tlJustArray)
		local lcResult, loEnv, loClass
		lcResult = ""
		this.ResetError()
		loEnv = this.saveEnvironment()
		try
			tcCursor      = evl(tcCursor, alias())
			tnDataSession = evl(tnDataSession, set("Datasession"))
			if empty(tcCursor)
				this.SetError("CursorStructure: cursor name cannot be empty.")
				return ""
			endif
			loClass = createobject("StructureToJSON")
			loClass.oUtils     = this.oUtils
			loClass.CurName    = tcCursor
			loClass.nSessionID = tnDataSession
			loClass.lExtended  = m.tlCopyExtended
			loClass.lJustArray = m.tlJustArray
			lcResult = loClass.StructureToJSON()
			loClass = .null.
			release loClass
		catch to loEx
			this.SetError(loEx.message)
		finally
			this.restoreEnvironment(loEnv)
		endtry
		return lcResult
	endfunc

	* MasterDetailToJSON
	function MasterDetailToJSON(tcMaster, tcDetail, tcExpr, tcDetailAttribute, tnSessionID)
		local loClass, loResult, lcResult
		lcResult = ""
		this.ResetError()
		try
			tnSessionID = evl(tnSessionID, set("Datasession"))
			set datasession to tnSessionID
			loClass  = createobject("CursorToJsonObject")
			loResult = loClass.MasterDetailToJSON(tcMaster, tcDetail, tcExpr, tcDetailAttribute, tnSessionID)
			loClass  = .null.
			release loClass
		catch to loEx
			this.SetError(loEx.message)
		endtry
		lcResult = this.Stringify(@loResult, "", .t., .t.)
		return lcResult
	endfunc

	* ArrayToXML
	function ArrayToXML(tcArray)
		local lcResult, lcTmp, loObjToJson
		lcResult = ""
		this.ResetError()
		lcTmp = sys(2015)
		if vartype(tcArray) = 'O'
			loObjToJson = createobject("ObjectToJson")
			loObjToJson.oUtils = this.oUtils
			tcArray = loObjToJson.Encode(@tcArray)
			loObjToJson = .null.
			release loObjToJson
		endif
		try
			this.JSONToCursor(tcArray, lcTmp, set("Datasession"))
			if !this.lError and used(lcTmp)
				=cursortoxml(lcTmp, 'lcResult', 1, 0, 0, '1')
			endif
		catch to loEx
			this.SetError(loEx.message)
		finally
			use in (select(lcTmp))
		endtry
		return lcResult
	endfunc

	* XMLToJson
	function XMLToJson(tcXML)
		local lcResult, loParser
		lcResult = ""
		this.ResetError()
		try
			=xmltocursor(tcXML, 'qXML')
			loParser = createobject("CursorToArray")
			loParser.CurName    = "qXML"
			loParser.nSessionID = set("Datasession")
			loParser.ParseUTF8  = .t.
			loParser.TrimChars  = .t.
			loParser.oUtils     = this.oUtils
			lcResult = loParser.CursorToArray()
		catch to loEx
			this.SetError(loEx.message)
		finally
			loParser = .null.
			release loParser
			use in (select("qXML"))
		endtry
		return lcResult
	endfunc

	function destroy
		try
			if this.lTablePrompt
				lcTablePrompt = this.lTablePrompt
				set tableprompt &lcTablePrompt
			endif
		catch
		endtry
	endfunc

enddefine
