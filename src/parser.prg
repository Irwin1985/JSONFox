#include "JSONFox.h"
&& ======================================================================== &&
&& JsonParser
&& EBNF Grammar
&& object = '{' kvp | { ',' kvp } '}'
&& kvp    = KEY ':' value
&& value  = STRING | NUMBER | BOOLEAN | array | object | null
&& array  = '[' value | { ',' value }  ']'
&& ======================================================================== &&
Define Class Parser As Custom
	* Parse any valid JSON object.
	Function Parse
		_screen.curtokenpos = 1
		Private JSONUtils
		JSONUtils = _Screen.JSONUtils
		lvNewVal = .Null.
		Do Case
		Case JSONUtils.Match(T_STRING)
			lvNewVal = _Screen.oPrevious.Lexeme
			If Occurs('-', lvNewVal) >= 2
				lDate = JSONUtils.FormatDate(lvNewVal)
				If !Isnull(lDate)
					lvNewVal = lDate
				Endif
			Endif
			Return lvNewVal
		Case JSONUtils.Match(T_NUMBER)
			nVal = Val(_Screen.oPrevious.Lexeme)
			Return Iif(At('.', _Screen.oPrevious.Lexeme) > 0, nVal, Int(nVal))
		Case JSONUtils.Match(T_BOOLEAN)
			Return (_Screen.oPrevious.Lexeme == 'true')
		Case JSONUtils.Match(T_LBRACE)
			Return This.Object()
		Case JSONUtils.Match(T_LBRACKET)
			MyArray = Createobject("Empty")
			=AddProperty(MyArray, '_[1]', .Null.)
			nIndex = 1
			Dimension MyArray._(1)
			MyArray._[1] = This.Value()
			If !JSONUtils.Check(T_RBRACKET)
				Do While JSONUtils.Match(T_COMMA)
					nIndex = nIndex + 1
					Dimension MyArray._(nIndex)
					MyArray._[nIndex] = This.Value()
				Enddo
			Endif
			JSONUtils.Consume(T_RBRACKET, "Expect ']' after array elements.")
			Return MyArray
		Case JSONUtils.Match(T_NULL)
			Return .Null.
		Otherwise
			JSONUtils.jsonError(JSONUtils.peek(), "Unknown token value")
		Endcase
	Endfunc
	&& ======================================================================== &&
	&& Function Object
	&& EBNF -> 	object = '{' kvp | { ',' kvp } '}'
	&& 			kvp    = KEY ':' value
	&& ======================================================================== &&
	Hidden Function Object As Object
		obj = Createobject('Empty')

		If !JSONUtils.Check(T_RBRACE)
			This.kvp(@obj)
			Do While JSONUtils.Match(T_COMMA)
				This.kvp(@obj)
			Enddo
		Endif
		JSONUtils.Consume(T_RBRACE, "Expect '}' after JSON body.")

		Return obj
	Endfunc
	&& ======================================================================== &&
	&& Function Kvp
	&& EBNF -> 	kvp = KEY ':' value
	&& ======================================================================== &&
	Hidden Function kvp As Void
		Lparameters toObj As Object
		loElement = JSONUtils.Consume(T_STRING, "Expect right key element")
		lcKeyElement = loElement.Lexeme
		JSONUtils.Consume(T_COLON, "Expect ':' after key element.")
		If !JSONUtils.Check(T_LBRACKET)
			=AddProperty(toObj, JSONUtils.CheckProp(lcKeyElement), This.Value(toObj, lcKeyElement))
		Else
			* Array element
			This.Value(toObj, lcKeyElement)
		Endif
	Endfunc
	&& ======================================================================== &&
	&& Function Value
	&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | array | object | NULL
	&& ======================================================================== &&
	Hidden Function Value(toObj2, tcProperty)
		lvNewVal = .Null.
		Do Case
		Case JSONUtils.Match(T_STRING)
			lvNewVal = _Screen.oPrevious.Lexeme
			If Occurs('-', lvNewVal) >= 2
				lDate = JSONUtils.FormatDate(lvNewVal)
				If !Isnull(lDate)
					lvNewVal = lDate
				Endif
			Endif
			Return lvNewVal
		Case JSONUtils.Match(T_NUMBER)
			nVal = Val(_Screen.oPrevious.Lexeme)
			Return Iif(At('.', _Screen.oPrevious.Lexeme) > 0, nVal, Int(nVal))
		Case JSONUtils.Match(T_BOOLEAN)
			Return (_Screen.oPrevious.Lexeme == 'true')
		Case JSONUtils.Match(T_LBRACE)
			Return This.Object()
		Case JSONUtils.Match(T_LBRACKET)
			Return This.Array(toObj2, tcProperty)
		Case JSONUtils.Match(T_NULL)
			Return .Null.
		Otherwise
			JSONUtils.jsonError(This.peek(), "Unknown token value")
		Endcase
	Endfunc
	&& ======================================================================== &&
	&& Function Array
	&& EBNF -> 	array = '[' value | { ',' value }  ']'
	&& ======================================================================== &&
	Hidden Function Array As Void
		Lparameters toObjRef As Object, tcPropertyName As String
		With This
			tcPropertyName = JSONUtils.CheckProp(tcPropertyName)
			=AddProperty(toObjRef, tcPropertyName + "(1)", 0)
			If !JSONUtils.Check(T_RBRACKET)
				nIndex = 0
				.ArrayPush(toObjRef, tcPropertyName, @nIndex)
				Do While JSONUtils.Match(T_COMMA)
					.ArrayPush(toObjRef, tcPropertyName, @nIndex)
				Enddo
			Endif
			JSONUtils.Consume(T_RBRACKET, "Expect ']' after array elements.")
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
Enddefine
