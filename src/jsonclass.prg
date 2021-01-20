* JSONClass
define class JSONClass as session
	datasession 	= 1
	LastErrorText 	= ""
	lError 			= .f.
	lShowErrors 	= .t.
	version 		= "4.4"
	hidden lInternal
	hidden lTablePrompt

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
			_screen.tokenizer.tokenize(tcJsonStr)
			loJSONObj = _screen.Parser.Parse()
		catch to loEx
			this.ShowExceptionError(loEx)
		endtry
		return loJSONObj
	endfunc
	* Stringify
	function Stringify as memo
		lparameters tvNewVal as Variant, tcFlags as string
		this.ResetError()
		if vartype(tvNewVal) = "O"
			tvNewVal = _screen.ObjectToJson.Encode(@tvNewVal, tcFlags)
		endif
		local loJSONStr as memo
		loJSONStr = ""
		try
			_screen.tokenizer.tokenize(tvNewVal)
			loJSONStr = _screen.JSONStringify.Stringify()
		catch to loEx
			this.ShowExceptionError(loEx)
		endtry
		return loJSONStr
	endfunc
	* JSONToRTF
	function JSONToRTF as memo
		lparameters tvNewVal as Variant, tnIndent as Boolean
		this.ResetError()
		if vartype(tvNewVal) = 'O'
			tvNewVal = _screen.ObjToJson.Encode(@tvNewVal)
		endif
		local loJSONStr as memo
		loJSONStr = ''
		try
			this.lError = .f.
			this.LastErrorText = ''
			_screen.tokenizer.tokenize(tvNewVal)
			_screen.JSONToRTF.lShowErrors = this.lShowErrors
			loJSONStr = _screen.JSONToRTF.StrToRTF(tnIndent)
			this.lError = _screen.JSONToRTF.lError
			this.LastErrorText = _screen.JSONToRTF.cErrorMsg
		catch to loEx
			this.ShowExceptionError(loEx)
			this.lError = .t.
			this.LastErrorText = loEx.message
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
		return _screen.ObjectToJson.Encode(@toObj, tcFlags)
	endfunc
	&& ======================================================================== &&
	&& Function decode
	&& <<Deprecated>> please use Parse function instead.
	&& ======================================================================== &&
	function Decode(tcJsonStr as memo) as object
		local loJSONObj as object
		loJSONObj = .null.
		try
			this.ResetError()
			_screen.tokenizer.tokenize(tcJsonStr)
			loJSONObj = _screen.Parser.Parse()
		catch to loEx
			this.ShowExceptionError(loEx)
		endtry
		return loJSONObj
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
		local lcOut as string
		lcOut = ''
		try
			this.ResetError()
			_screen.tokenizer.tokenize(tcArray)
			_screen.ArrayToCursor.CurName 	 = "qResult"
			_screen.ArrayToCursor.nSessionID = set("Datasession")
			_screen.ArrayToCursor.array()
			=cursortoxml('qResult','lcOut', 1, 0, 0, '1')
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			use in (select("qResult"))
		endtry
		return lcOut
	endfunc
	* XMLToJson
	function XMLToJson(tcXML as memo) as memo
		local lcJsonXML as memo
		lcJsonXML = ''
		try
			this.ResetError()
			=xmltocursor(tcXML, 'qXML')
			_screen.CursorToArray.CurName 	 = "qXML"
			_screen.CursorToArray.nSessionID = set("Datasession")
			lcJsonXML = _screen.CursorToArray.CursorToArray()
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			use in (select("qXML"))
		endtry
		return lcJsonXML
	endfunc
	* CursorToJSON
	function CursorToJSON as memo
		lparameters tcCursor as string, tbCurrentRow as Boolean, tnDataSession as integer, tlJustArray as Boolean
		local lcJsonXML as memo
		lcJsonXML = ''
		try
			this.ResetError()
			tcCursor = evl(tcCursor, alias())
			tnDataSession = evl(tnDataSession, set("Datasession"))
			if tbCurrentRow
				lnRecno = recno(tcCursor)
				select * from (tcCursor) where recno() = lnRecno into cursor qResult
			else
				select * from (tcCursor) into cursor qResult
			endif

			_screen.CursorToArray.CurName 	 = "qResult"
			_screen.CursorToArray.nSessionID = tnDataSession
			lcJsonXML = _screen.CursorToArray.CursorToArray()
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			use in (select("qResult"))
		endtry
		lcOutput = iif(tlJustArray, lcJsonXML, '{"' + lower(alltrim(tcCursor)) + '":' + lcJsonXML + '}')
		return lcOutput
	endfunc
	* JSONToCursor
	function JSONToCursor(tcJsonStr as memo, tcCursor as string, tnDataSession as integer) as Void
		try
			this.ResetError()
			if !empty(tcCursor)
				tnDataSession = evl(tnDataSession, set("Datasession"))
				_screen.tokenizer.tokenize(tcJsonStr)
				_screen.ArrayToCursor.CurName 	 = tcCursor
				_screen.ArrayToCursor.nSessionID = tnDataSession
				_screen.ArrayToCursor.array()
			else
				if this.lShowErrors
					wait "Invalid cursor name." window nowait
				endif
			endif
		catch to loEx
			this.ShowExceptionError(loEx)
		endtry
	endfunc
	* CursorStructure
	function CursorStructure
		lparameters tcCursor as string, tnDataSession as integer, tlCopyExtended as Boolean
		local lcOutput as memo
		lcOutput = ''
		try
			this.ResetError()
			loStructureToJSON = _screen.StructureToJSON
			tcCursor = evl(tcCursor, alias())
			tnDataSession = evl(tnDataSession, set("Datasession"))
			loStructureToJSON.CurName 	= tcCursor
			loStructureToJSON.nSessionID  = tnDataSession
			loStructureToJSON.lExtended   = tlCopyExtended
			lcOutput = loStructureToJSON.StructureToJSON()
		catch to loEx
			this.ShowExceptionError(loEx)
		finally
			use in (select("qResult"))
		endtry
		return lcOutput
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
		_screen.curtokenpos = 1
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
	endfunc
enddefine
