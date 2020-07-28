&& ======================================================================== &&
&& Class JSON
&& ======================================================================== &&
Define Class JSON As Custom
	Hidden 					;
		oRef,				;
		Classlibrary, 		;
		Comment, 			;
		Baseclass, 			;
		Controlcount, 		;
		Controls, 			;
		Objects, 			;
		Object, 			;
		Height, 			;
		Helpcontextid, 		;
		Left, 				;
		Name, 				;
		Parent, 			;
		Parentclass, 		;
		Picture, 			;
		Tag, 				;
		Top, 				;
		Whatsthishelpid, 	;
		Width,				;
		Class	
&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
	Function Init(toRef As Object)
		If !IsNull(toRef)
			this.oRef = toRef
		EndIf
	EndFunc
&& ======================================================================== &&
&& Function to_json
&& ======================================================================== &&
	Function to_json As String
		If Type("_Screen.Json") = "O"
			Return _Screen.Json.objtojson.decode(this.oRef)
		Else
			Return "{}"
		EndIf
	EndFunc
&& ======================================================================== &&
&& Function This_Access
&& ======================================================================== &&
	Function This_Access(tcPropName As String) As Object
		If PemStatus(This, tcPropName, 5)
			Return This
		Else
			Return This.oRef
		EndIf
	EndFunc
&& ======================================================================== &&
&& Function Destroy
&& ======================================================================== &&
	Function Destroy
		This.oRef = .Null.
	EndFunc
EndDefine