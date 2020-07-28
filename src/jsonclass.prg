&& ======================================================================== &&
&& Class JSONClass
&& ======================================================================== &&
Define Class JSONClass As Session
	Hidden oHelper
	Hidden clManager
	DataSession = 2
	LastErrorText = ""
	lError = .F.
	lShowErrors = .T.
	Hidden lInternal
	Hidden lTablePrompt
	Version = "2.0"

&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
	Function Init
		With This
			.ResetError()
			.lTablePrompt = Set("TablePrompt") == "ON"
			Set TablePrompt Off
			Set Procedure To "ClassLibManager" 	Additive
			.clManager = Createobject("ClassLibManager")
			With .clManager
				.AddClass("ArrayToCursor")
				.AddClass("CursorToArray")
				.AddClass("JsonLexer")
				.AddClass("JsonParser")
				.AddClass("JsonStringify")
				.AddClass("ObjectToJson")
				.AddClass("JsonDecorator")

				.AddProcedure("ArrayToCursor")
				.AddProcedure("CursorToArray")
				.AddProcedure("JsonLexer")
				.AddProcedure("JsonParser")
				.AddProcedure("JsonStringify")
				.AddProcedure("ObjectToJson")
				.AddProcedure("JsonDecorator")
				.LoadProcedures()
			Endwith

			.oHelper = Createobject("Empty")
			=AddProperty(.oHelper, "Lexer", Createobject("JsonLexer"))
			=AddProperty(.oHelper, "Parser", Createobject("JsonParser", .oHelper.Lexer))
			=AddProperty(.oHelper, "ArrayToCursor", Createobject("ArrayToCursor", .oHelper.Lexer))
			=AddProperty(.oHelper, "CursorToArray", Createobject("CursorToArray"))
			=AddProperty(.oHelper, "JSONStringify", Createobject("JSONStringify", .oHelper.Lexer))
			=AddProperty(.oHelper, "ObjToJson", Createobject("ObjectToJson"))
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
					.ScanString(tcJsonStr)
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
		Lparameters tvNewVal As Variant
		This.ResetError()
		If Vartype(tvNewVal) = "O"
			tvNewVal = This.oHelper.ObjToJson.Encode(tvNewVal)
		Endif
		Local loJSONStr As Memo
		loJSONStr = ""
		Try
			With This.oHelper
				With .Lexer
					.ScanString(tvNewVal)
					.NextToken()
				Endwith
				loJSONStr = .JSONStringify.Stringify()
			Endwith
		Catch To loEx
			This.ShowExceptionError(loEx)
		Endtry
		Return loJSONStr
	Endfunc
*  ====================== Old JSONFox Functions =========================== *
*  . . . . . . . . . . For backward compatibility . . . . . . . . . . . .
*  ======================================================================== *
&& ======================================================================== &&
&& Function Encode
&& <<Deprecated>> please use Stringify function instead.
&& ======================================================================== &&
	Function Encode(toObj As Object) As Memo
		Return This.Stringify(toObj)
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
					.ScanString(tcJsonStr)
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
					.ScanString(tcArray)
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
		Endtry
		Return lcJsonXML
	Endfunc
&& ======================================================================== &&
&& Function CursorToJSON
&& ======================================================================== &&
	Function CursorToJSON As Memo
		Lparameters tcCursor As String, tbCurrentRow As Boolean, tnDataSession As Integer
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
		Endtry
		Return '{"' + Lower(Alltrim(tcCursor)) + '":' + lcJsonXML + '}'
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
	Function ShowExceptionError(toEx As Exception) As void
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
	Hidden Function ResetError As void
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
		Try
			This.clManager.ReleaseAll()
		Catch
		Endtry
	Endfunc
Enddefine
