&& ======================================================================== &&
&& Class JSONDecorator
&& ======================================================================== &&
Define Class JSONDecorator As Custom
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
		This.extends(toRef)
	Endfunc
&& ======================================================================== &&
&& Function Extends
&& ======================================================================== &&
	Function extends As Void
		Lparameters toExtendedClass As Object
		If !Isnull(toExtendedClass)
			This.oRef = toExtendedClass
		Endif
	Endfunc
&& ======================================================================== &&
&& Function to_json
&& ======================================================================== &&
	Function to_json As String
		If Type("_Screen.Json") = "O" And Type("This.oRef") = "O"
			Return _Screen.JSON.Stringify(This.oRef)
		Else
			Return "{}"
		Endif
	Endfunc
&& ======================================================================== &&
&& Function This_Access
&& ======================================================================== &&
	Function This_Access(tcPropName As String) As Object
		If Pemstatus(This, tcPropName, 5)
			Return This
		Else
			Return This.oRef
		Endif
	Endfunc
&& ======================================================================== &&
&& Function Destroy
&& ======================================================================== &&
	Function Destroy
		This.oRef = .Null.
	Endfunc
Enddefine
