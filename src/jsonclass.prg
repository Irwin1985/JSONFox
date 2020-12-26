* JSONClass
Define Class JSONClass As Session
	DataSession 	= 1
	LastErrorText 	= ""
	lError 			= .F.
	lShowErrors 	= .T.
	Version 		= "4.0"
	Hidden lInternal
	Hidden lTablePrompt

	*Function Init
	Function Init
		With This
			.ResetError()
			.lTablePrompt = Set("TablePrompt") == "ON"
			Set TablePrompt Off
		Endwith
	Endfunc
	* Parse the string text as JSON
	Function Parse As Memo
		Lparameters tcJsonStr As Memo
		Local loJSONObj As Object
		loJSONObj = .Null.
		Try
			This.ResetError()
			_Screen.tokenizer.tokenize(tcJsonStr)
			loJSONObj = _Screen.Parser.Parse()
		Catch To loEx
			This.ShowExceptionError(loEx)
		Endtry
		Return loJSONObj
	Endfunc
	* Stringify
	Function Stringify As Memo
		Lparameters tvNewVal As Variant, tcFlags As String
		This.ResetError()
		If Vartype(tvNewVal) = "O"
			tvNewVal = _Screen.ObjectToJson.Encode(@tvNewVal, tcFlags)
		Endif
		Local loJSONStr As Memo
		loJSONStr = ""
		Try
			_Screen.tokenizer.tokenize(tvNewVal)
			loJSONStr = _Screen.JSONStringify.Stringify()
		Catch To loEx
			This.ShowExceptionError(loEx)
		Endtry
		Return loJSONStr
	Endfunc
	* JSONToRTF
	Function JSONToRTF As Memo
		Lparameters tvNewVal As Variant, tnIndent As Boolean
		This.ResetError()
		If Vartype(tvNewVal) = 'O'
			tvNewVal = _Screen.ObjToJson.Encode(@tvNewVal)
		Endif
		Local loJSONStr As Memo
		loJSONStr = ''
		Try
			This.lError = .F.
			This.LastErrorText = ''
			_Screen.tokenizer.tokenize(tvNewVal)
			_Screen.JSONToRTF.lShowErrors = This.lShowErrors
			loJSONStr = _Screen.JSONToRTF.StrToRTF(tnIndent)
			This.lError = _Screen.JSONToRTF.lError
			This.LastErrorText = _Screen.JSONToRTF.cErrorMsg
		Catch To loEx
			This.ShowExceptionError(loEx)
			This.lError = .T.
			This.LastErrorText = loEx.Message
		Endtry
		Return loJSONStr
	Endfunc
	* JSONViewer
	Function JSONViewer As Void
		Lparameters tcJsonStr As Memo, tlStopExecution As Boolean
		Do Form frmJSONViewer With tcJsonStr, tlStopExecution
		If tlStopExecution
			Read Events
		Endif
	Endfunc
	*  ====================== Old JSONFox Functions =========================== *
	*  . . . . . . . . . . For backward compatibility . . . . . . . . . . . .
	*  ======================================================================== *
	&& ======================================================================== &&
	&& Function Encode
	&& <<Deprecated>> please use Stringify function instead.
	&& ======================================================================== &&
	Function Encode(toObj As Object, tcFlags As String) As Memo
		Return _Screen.ObjectToJson.Encode(@toObj, tcFlags)
	Endfunc
	&& ======================================================================== &&
	&& Function decode
	&& <<Deprecated>> please use Parse function instead.
	&& ======================================================================== &&
	Function Decode(tcJsonStr As Memo) As Object
		Local loJSONObj As Object
		loJSONObj = .Null.
		Try
			This.ResetError()
			_Screen.tokenizer.tokenize(tcJsonStr)
			loJSONObj = _Screen.Parser.Parse()
		Catch To loEx
			This.ShowExceptionError(loEx)
		Endtry
		Return loJSONObj
	Endfunc
	&& ======================================================================== &&
	&& Function LoadFile
	&& <<Deprecated>> please use Parse function instead.
	&& ======================================================================== &&
	Function LoadFile(tcJsonFile As String) As Object
		Return This.Decode(Filetostr(tcJsonFile))
	Endfunc
	* ArrayToXML
	Function ArrayToXML(tcArray As Memo) As String
		Local lcOut As String
		lcOut = ''
		Try
			This.ResetError()
			_Screen.tokenizer.tokenize(tcArray)
			_Screen.ArrayToCursor.CurName 	 = "qResult"
			_Screen.ArrayToCursor.nSessionID = Set("Datasession")
			_Screen.ArrayToCursor.Array()
			=Cursortoxml('qResult','lcOut', 1, 0, 0, '1')
		Catch To loEx
			This.ShowExceptionError(loEx)
		Finally
			Use In (Select("qResult"))
		Endtry
		Return lcOut
	Endfunc
	* XMLToJson
	Function XMLToJson(tcXML As Memo) As Memo
		Local lcJsonXML As Memo
		lcJsonXML = ''
		Try
			This.ResetError()
			=Xmltocursor(tcXML, 'qXML')
			_Screen.CursorToArray.CurName 	 = "qXML"
			_Screen.CursorToArray.nSessionID = Set("Datasession")
			lcJsonXML = _Screen.CursorToArray.CursorToArray()
		Catch To loEx
			This.ShowExceptionError(loEx)
		Finally
			Use In (Select("qXML"))
		Endtry
		Return lcJsonXML
	Endfunc
	* CursorToJSON
	Function CursorToJSON As Memo
		Lparameters tcCursor As String, tbCurrentRow As Boolean, tnDataSession As Integer, tlJustArray As Boolean
		Local lcJsonXML As Memo
		lcJsonXML = ''
		Try
			This.ResetError()
			tcCursor = Evl(tcCursor, Alias())
			tnDataSession = Evl(tnDataSession, Set("Datasession"))
			If tbCurrentRow
				lnRecno = Recno(tcCursor)
				Select * From (tcCursor) Where Recno() = lnRecno Into Cursor qResult
			Else
				Select * From (tcCursor) Into Cursor qResult
			Endif

			_Screen.CursorToArray.CurName 	 = "qResult"
			_Screen.CursorToArray.nSessionID = tnDataSession
			lcJsonXML = _Screen.CursorToArray.CursorToArray()
		Catch To loEx
			This.ShowExceptionError(loEx)
		Finally
			Use In (Select("qResult"))
		Endtry
		lcOutput = Iif(tlJustArray, lcJsonXML, '{"' + Lower(Alltrim(tcCursor)) + '":' + lcJsonXML + '}')
		Return lcOutput
	Endfunc
	* JSONToCursor
	Function JSONToCursor(tcJsonStr As Memo, tcCursor As String, tnDataSession As Integer) As Void
		Try
			This.ResetError()
			If !Empty(tcCursor)
				tnDataSession = Evl(tnDataSession, Set("Datasession"))
				_Screen.tokenizer.tokenize(tcJsonStr)
				_Screen.ArrayToCursor.CurName 	 = tcCursor
				_Screen.ArrayToCursor.nSessionID = tnDataSession
				_Screen.ArrayToCursor.Array()
			Else
				If This.lShowErrors
					Wait "Invalid cursor name." Window Nowait
				Endif
			Endif
		Catch To loEx
			This.ShowExceptionError(loEx)
		Endtry
	Endfunc
	* CursorStructure
	Function CursorStructure
		Lparameters tcCursor As String, tnDataSession As Integer, tlCopyExtended As Boolean
		Local lcOutput As Memo
		lcOutput = ''
		Try
			This.ResetError()
			loStructureToJSON = _Screen.StructureToJSON
			tcCursor = Evl(tcCursor, Alias())
			tnDataSession = Evl(tnDataSession, Set("Datasession"))
			loStructureToJSON.CurName 	= tcCursor
			loStructureToJSON.nSessionID  = tnDataSession
			loStructureToJSON.lExtended   = tlCopyExtended
			lcOutput = loStructureToJSON.StructureToJSON()
		Catch To loEx
			This.ShowExceptionError(loEx)
		Finally
			Use In (Select("qResult"))
		Endtry
		Return lcOutput
	Endfunc
	* LastErrorText_Assign
	Function LastErrorText_Assign
		Lparameters vNewVal
		With This
			If .lInternal
				.lInternal = .F.
				.LastErrorText = m.vNewVal
			Endif
		Endwith
	Endfunc
	* ShowExceptionError
	Function ShowExceptionError(toEx As Exception) As Void
		With This
			.lError = .T.
			If .lShowErrors
				Wait "ErrorNo: " 	+ Str(toEx.ErrorNo) 	+ Chr(13) + ;
					"Message: " 	+ toEx.Message 			+ Chr(13) + ;
					"LineNo: " 		+ Str(toEx.Lineno) 		+ Chr(13) + ;
					"Procedure: " 	+ toEx.Procedure Window Nowait
			Endif
			.lInternal = .T.
			.LastErrorText = toEx.Message
		Endwith
	Endfunc
	* ResetError
	Hidden Function ResetError As Void
		_screen.curtokenpos = 1
		This.lError = .F.
	Endfunc
	* Destroy
	Function Destroy
		Try
			If This.lTablePrompt
				lcTablePrompt = This.lTablePrompt
				Set TablePrompt &lcTablePrompt
			Endif
		Catch
		Endtry
	Endfunc
Enddefine
