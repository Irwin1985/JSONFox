&& ======================================================================== &&
&& Class JSONClass
&& ======================================================================== &&
Define Class JSONClass As Session
	Hidden oHelper
	DataSession = 1
	LastErrorText = ""
	lError = .F.
	lShowErrors = .T.
	Hidden lInternal
	Hidden lTablePrompt
	Version = "2.6"

&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
	Function Init
		With This
			.ResetError()
			.lTablePrompt = Set("TablePrompt") == "ON"
			Set TablePrompt Off
			.oHelper = Createobject("Empty")
			=AddProperty(.oHelper, "Lexer", Createobject("JsonLexer"))
			=AddProperty(.oHelper, "Parser", Createobject("JsonParser", .oHelper.Lexer))
			=AddProperty(.oHelper, "ArrayToCursor", Createobject("ArrayToCursor", .oHelper.Lexer))
			=AddProperty(.oHelper, "CursorToArray", Createobject("CursorToArray"))
			=AddProperty(.oHelper, "JSONStringify", Createobject("JSONStringify", .oHelper.Lexer))
			=AddProperty(.oHelper, "ObjToJson", Createobject("ObjectToJson"))
			=AddProperty(.oHelper, "JSONToRTF", Createobject("JSONToRTF", .oHelper.Lexer))
		Endwith
	Endfunc
&& ======================================================================== &&
&& Parse
&& Parse the string text as JSON
&& ======================================================================== &&
	Function Parse As Memo
		Lparameters tcJsonStr As Memo
		Local loJSONObj As Object
		loJSONObj = .Null.
		Try
			This.ResetError()
			With This.oHelper
				With .Lexer
					.ScanString(tcJsonStr, .F.)
					.NextToken()
				Endwith
				loJSONObj = .Parser.Object()
			Endwith
		Catch To loEx
			This.ShowExceptionError(loEx)
		Endtry
		Return loJSONObj
	Endfunc
&& ======================================================================== &&
&& Function Stringify
&& Return a JSON string corresponding to the specified value
&& ======================================================================== &&
	Function Stringify As Memo
		Lparameters tvNewVal As Variant, tcFlags As String
		This.ResetError()
		If Vartype(tvNewVal) = "O"
			tvNewVal = This.oHelper.ObjToJson.Encode(tvNewVal, tcFlags)
		Endif
		Local loJSONStr As Memo
		loJSONStr = ""
		Try
			With This.oHelper
				With .Lexer
					.ScanString(tvNewVal, .T.)
					.NextToken()
				EndWith
				loJSONStr = .JSONStringify.Stringify()
			Endwith
		Catch To loEx
			This.ShowExceptionError(loEx)
		Endtry
		Return loJSONStr
	Endfunc
&& ======================================================================== &&
&& Function JSONToRTF
&& Return a JSON string with RTF format
&& ======================================================================== &&
	Function JSONToRTF As Memo
		Lparameters tvNewVal As Variant, tnIndent As Boolean
		This.ResetError()
		If Vartype(tvNewVal) = "O"
			tvNewVal = This.oHelper.ObjToJson.Encode(tvNewVal)
		Endif
		Local loJSONStr As Memo
		loJSONStr = ""
		Try
			This.lError = .F.
			This.LastErrorText = ""
			With This.oHelper
				With .Lexer
					.ScanString(tvNewVal)
					.NextToken()
				Endwith
				.JSONToRTF.lShowErrors = This.lShowErrors
				loJSONStr = .JSONToRTF.StrToRTF(tnIndent)
				This.lError = .JSONToRTF.lError
				This.LastErrorText = .JSONToRTF.cErrorMsg
			Endwith
		Catch To loEx
			This.ShowExceptionError(loEx)
			This.lError = .T.
			This.LastErrorText = loEx.Message
		Endtry
		Return loJSONStr
	Endfunc
&& ======================================================================== &&
&& Function JSONViewer
&& ======================================================================== &&
	Function JSONViewer As Void
		Lparameters tcJsonStr As Memo, tlStopExecution As Boolean
		Do Form frmJSONViewer With tcJsonStr, tlStopExecution
		If tlStopExecution
			Read events
		EndIf
	Endfunc
*  ====================== Old JSONFox Functions =========================== *
*  . . . . . . . . . . For backward compatibility . . . . . . . . . . . .
*  ======================================================================== *
&& ======================================================================== &&
&& Function Encode
&& <<Deprecated>> please use Stringify function instead.
&& ======================================================================== &&
	Function Encode(toObj As Object, tcFlags As String) As Memo
		If Type("toObj") = 'O'
			Return This.Stringify(toObj, tcFlags)
		Else
			Return This.oHelper.ObjToJson.AnyToJSON(toObj)
		EndIf
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
			With This.oHelper
				With .Lexer
					.ScanString(tcJsonStr, .F.)
					.NextToken()
				Endwith
				loJSONObj = .Parser.Object()
			Endwith
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
&& ======================================================================== &&
&& Function ArrayToXML
&& ======================================================================== &&
	Function ArrayToXML(tcArray As Memo) As String
		Local lcOut As String
		lcOut = ''
		Try
			This.ResetError()
			With This.oHelper
				With .Lexer
					.ScanString(tcArray, .F.)
					.NextToken()
				Endwith
				With .ArrayToCursor
					.CurName 	= "qResult"
					.nSessionID = Set("Datasession")
					.Array()
				Endwith
			Endwith
			=Cursortoxml('qResult','lcOut', 1, 0, 0, '1')
		Catch To loEx
			This.ShowExceptionError(loEx)
		Finally
			Use In (Select("qResult"))
		Endtry
		Return lcOut
	Endfunc
&& ======================================================================== &&
&& Function XMLToJson
&& ======================================================================== &&
	Function XMLToJson(tcXML As Memo) As Memo
		Local lcJsonXML As Memo
		lcJsonXML = ''
		Try
			This.ResetError()
			=Xmltocursor(tcXML, 'qXML')
			With This.oHelper
				With .CursorToArray
					.CurName 	= "qXML"
					.nSessionID = Set("Datasession")
					lcJsonXML 	= .CursorToArray()
				Endwith
			Endwith
		Catch To loEx
			This.ShowExceptionError(loEx)
		Finally
			Use In (Select("qXML"))
		Endtry
		Return lcJsonXML
	Endfunc
&& ======================================================================== &&
&& Function CursorToJSON
&& ======================================================================== &&
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
			With This.oHelper
				With .CursorToArray
					.CurName 	= "qResult"
					.nSessionID = tnDataSession
					lcJsonXML 	= .CursorToArray()
				Endwith
			Endwith
		Catch To loEx
			This.ShowExceptionError(loEx)
		Finally
			Use In (Select("qResult"))
		EndTry
		lcOutput = Iif(tlJustArray, lcJsonXML, '{"' + Lower(Alltrim(tcCursor)) + '":' + lcJsonXML + '}')
		Return lcOutput
	Endfunc
&& ======================================================================== &&
&& Function JSONToCursor
&& ======================================================================== &&
	Function JSONToCursor(tcJsonStr As Memo, tcCursor As String, tnDataSession As Integer) As Void
		Try
			This.ResetError()
			If !Empty(tcCursor)
				tnDataSession = Evl(tnDataSession, Set("Datasession"))
				With This.oHelper
					With .Lexer
						.ScanString(tcJsonStr, .T.)
						.NextToken()
					Endwith
					With .ArrayToCursor
						.CurName 	= tcCursor
						.nSessionID = tnDataSession
						.Array()
					Endwith
				Endwith
			Else
				If This.lShowErrors
					Wait "Invalid cursor name." Window Nowait
				Endif
			Endif
		Catch To loEx
			This.ShowExceptionError(loEx)
		Endtry
	Endfunc
&& ======================================================================== &&
&& Function LastErrorText_Assign
&& ======================================================================== &&
	Function LastErrorText_Assign
		Lparameters vNewVal
		With This
			If .lInternal
				.lInternal = .F.
				.LastErrorText = m.vNewVal
			Endif
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function ShowExceptionError
&& ======================================================================== &&
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
&& ======================================================================== &&
&& Function ResetError
&& ======================================================================== &&
	Hidden Function ResetError As Void
		This.lError = .F.
	Endfunc
&& ======================================================================== &&
&& Function Destroy
&& ======================================================================== &&
	Function Destroy
		Try
			If This.lTablePrompt
				lcTablePrompt = This.lTablePrompt
				Set TablePrompt &lcTablePrompt
			Endif
		Catch
		Endtry
		Try
			This.oHelper = .Null.
		Catch
		Endtry
	Endfunc
Enddefine
