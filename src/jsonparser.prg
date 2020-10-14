#include "JSONFox.h"
&& ======================================================================== &&
&& JsonParser
&& EBNF Grammar
&& object = '{' kvp | { ',' kvp } '}'
&& kvp    = KEY ':' value
&& value  = STRING | NUMBER | BOOLEAN | array | object | null
&& array  = '[' value | { ',' value }  ']'
&& ======================================================================== &&
Define Class JsonParser As Custom
	Hidden sc
	Hidden utils
&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
	Function Init
		Lparameters toSC As Object
		Set Procedure To "JsonUtils" Additive
		With This
			.sc    = toSC
			.utils = Createobject("JsonUtils")
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function Object
&& EBNF -> 	object = '{' kvp | { ',' kvp } '}'
&& 			kvp    = KEY ':' value
&& ======================================================================== &&
	Function Object As Object
		obj = Createobject('Empty')
		With This
			.utils.Match(.sc, T_LEFTCURLEYBRACKET)
			If .sc.Token.Code != T_RIGHTCURLEYBRACKET
				.kvp(@obj)
				Do While .sc.Token.Code = T_COMMA
					.sc.NextToken()
					.kvp(@obj)
				EndDo
			EndIf
			.utils.Match(.sc, T_RIGHTCURLEYBRACKET)
		Endwith
		Return obj
	Endfunc
&& ======================================================================== &&
&& Function Kvp
&& EBNF -> 	kvp = KEY ':' value
&& ======================================================================== &&
	Hidden Function kvp As Void
		Lparameters toObj As Object
		With This
			lcProp = .sc.Token.Value
			.sc.NextToken()
			.utils.Match(.sc, T_COLON)
			If .sc.Token.Code != T_LEFTBRACKET
				=AddProperty(toObj, .utils.CheckProp(lcProp), .Value(toObj, lcProp))
			Else
				.Value(toObj, lcProp)
			Endif
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function Value
&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | array | object | NULL
&& ======================================================================== &&
	Hidden Function Value As Variant
		Lparameters toObj2, tcProperty As String
		vNewVal = .Null.
		With This
			Do Case
			Case .sc.Token.Code = T_STRING
				vNewVal = .sc.Token.Value
				If Occurs('-', vNewVal) >= 2
					lDate = .utils.FormatDate(vNewVal)
					If !Isnull(lDate)
						vNewVal = lDate
					Endif
				Endif
				.sc.NextToken()
			Case .sc.Token.Code = T_INTEGER
				vNewVal = .sc.Token.Value
				.sc.NextToken()
			Case .sc.Token.Code = T_FLOAT
				vNewVal = .sc.Token.Value
				.sc.NextToken()
			Case .sc.Token.Code = T_TRUE
				vNewVal = .sc.Token.Value
				.sc.NextToken()
			Case .sc.Token.Code = T_FALSE
				vNewVal = .sc.Token.Value
				.sc.NextToken()
			Case .sc.Token.Code = T_LEFTCURLEYBRACKET
				vNewVal = .Object()
			Case .sc.Token.Code = T_LEFTBRACKET
				.Array(toObj2, tcProperty)
				Return
			Case .sc.Token.Code = T_NULL
				vNewVal = .sc.Token.Value
				.sc.NextToken()
			Otherwise
				Error "Parse error " + Alltrim(Str(.sc.Token.LineNumber)) + "," + Alltrim(Str(.sc.Token.columnNumber)) + " Unexpected Token '" + .sc.TokenToStr(.sc.Token.Code) + "'"
			Endcase
		Endwith
		Return vNewVal
	Endfunc
&& ======================================================================== &&
&& Function Array
&& EBNF -> 	array = '[' value | { ',' value }  ']'
&& ======================================================================== &&
	Hidden Function Array As Void
		Lparameters toObjRef As Object, tcPropertyName As String
		With This
			.utils.Match(.sc, T_LEFTBRACKET)
			tcPropertyName = .utils.CheckProp(tcPropertyName)
			=AddProperty(toObjRef, tcPropertyName + "(1)", 0)
			If .sc.Token.Code != T_RIGHTBRACKET
				nIndex = 0
				.ArrayPush(toObjRef, tcPropertyName, @nIndex)
				Do While .sc.Token.Code = T_COMMA
					.sc.NextToken()
					.ArrayPush(toObjRef, tcPropertyName, @nIndex)
				Enddo
			Endif
			.utils.Match(.sc, T_RIGHTBRACKET)
		Endwith
	Endfunc
&& ======================================================================== &&
&& Hidden Function ArrayPush
&& ======================================================================== &&
	Hidden Function ArrayPush As Void
		Lparameters toObjRef As Object, tcPropName As String, tnCurrentIndex As Integer
		tnCurrentIndex = tnCurrentIndex + 1
		lcCmd = "DIMENSION toObjRef." + tcPropName + "(" + Alltrim(Str(tnCurrentIndex)) + ")"
		&lcCmd
		lcCmd = "toObjRef." + tcPropName + "[" + Alltrim(Str(tnCurrentIndex)) + "] = This.Value()"
		&lcCmd
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