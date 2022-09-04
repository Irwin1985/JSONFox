#include "JSONFox.h"
* ArrayToCursor
Define Class ArrayToCursor As Session
	#Define STRING_MAX_SIZE	254

	curname 	 = ""
	nSessionID 	 = 0
	oTableStruct = .Null.
	
	Dimension aRows(1)
	nRowCount = 0

	Dimension tokens[1]
	Hidden current
	Hidden previous
	Hidden peek
	
	Hidden capacity
	Hidden length


	function init(toScanner)
		Local laTokens
		laTokens = toScanner.scanTokens()
		=Acopy(laTokens, this.tokens)		
		this.current = 1
		This.oTableStruct = Createobject('Collection')

		this.length = 1
		this.capacity = 0

	endfunc

	&& ======================================================================== &&
	&& Function Array
	&& EBNF -> 	array  	= '[' object | { ',' object }  ']'
	&& ======================================================================== &&
	Function Array As Void

		If Empty(This.nSessionID)
			This.nSessionID = Set("Datasession")
		Endif
		Set DataSession To (This.nSessionID)

		This.consume(T_LBRACKET, "Expect '[' before Array definition.")
		
		If !this.match(T_RBRACKET)
			this.addRow(this.Object())

			Do While This.match(T_COMMA)
				this.addRow(this.Object())
			Enddo
		EndIf
		This.consume(T_RBRACKET, "Expect ']' after Array definition.")

		* Shrink array
		this.capacity = this.length-1
		Dimension this.aRows[this.capacity]
		
		This.InsertData()
	EndFunc
	
	hidden function addRow(toValue)
		this.checkCapacity()

		this.aRows[this.length] = toValue
		this.length = this.length + 1		
	EndFunc	

	Hidden function checkCapacity
		If this.capacity < this.length + 1
			If Empty(this.capacity)
				this.capacity = 8
			Else
				this.capacity = this.capacity * 2
			EndIf			
			Dimension this.aRows[this.capacity]
		EndIf
	endfunc
	
	&& ======================================================================== &&
	&& Function Object
	&& EBNF -> 	object 	= '{' kvp | { ',' kvp} '}'
	&& ======================================================================== &&
	Hidden Function Object As Void
		Local loCollection, loPair
		This.consume(T_LBRACE, "Expect '{' before json object.")
		loCollection = Createobject("Collection")
		
		If !this.check(T_RBRACE)
			loPair = This.kvp()
			loCollection.Add(loPair.Value, loPair.Field)

			Do While This.match(T_COMMA)
				loPair = This.kvp()
				loCollection.Add(loPair.Value, loPair.Field)
			EndDo
		endif
		This.consume(T_RBRACE, "Expect '}' after json object.")
		
		Return loCollection
	Endfunc
	&& ======================================================================== &&
	&& Function Kvp
	&& EBNF -> 	kvp 	= KEY ':' value
	&& 			value	= STRING | NUMBER | BOOLEAN	| NULL
	&& ======================================================================== &&
	Hidden Function kvp
		Local lcProp, lxValue, lcType, lnFieldLength, lcFieldName, loPair

		This.consume(T_STRING, "Expect right key element")
		lcProp = this.previous.value
		
		This.consume(T_COLON, "Expect ':' after key element.")
		
		lcFieldName = Space(1)		
		lxValue = This.Value()
		lcType  = Vartype(lxValue)
		lnFieldLength = 0
		Do Case
		Case lcType == 'N'
			lcType = Iif(Occurs('.', Transform(lxValue)) > 0, 'N', 'I')
		Case lcType == 'C'
			If Len(lxValue) > STRING_MAX_SIZE
				lcType = 'M'
			Else
				lxValue = _Screen.JSONUtils.CheckString(lxValue)
				lcType  = Vartype(lxValue)
			Endif
			If lcType == 'C'
				lnFieldLength = Iif(Empty(Len(lxValue)), 1, Len(lxValue))
			Endif
		Endcase
		lcFieldName = Lower(_Screen.JSONUtils.CheckProp(lcProp))
		This.CheckStructure(lcFieldName, lcType, lnFieldLength)

		* Set Key-Value pair object
		loPair = CreateObject("Empty")
		=AddProperty(loPair, "field", lcFieldName)
		=AddProperty(loPair, "value", lxValue)
		
		Return loPair
	Endfunc
	&& ======================================================================== &&
	&& Function Value
	&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | NULL
	&& ======================================================================== &&
	Hidden Function Value As Variant
		Do Case
		Case This.match(T_STRING)
			Return this.previous.value
			
		case this.match(T_NUMBER)
			Local lcValue
			lcValue = this.previous.value
			return iif(at('.', lcValue) > 0, Val(lcValue), int(Val(lcValue)))

		case this.match(T_BOOLEAN)
			return (this.previous.value == 'true')

		case this.match(T_NULL)
			return .null.

		Otherwise
			Error "Parser Error: This token is invalid in for cursor conversion: '" + _screen.jsonUtils.tokenTypeToStr(This.peek.type) + "'"
		Endcase
	Endfunc
	* InsertData
	Hidden Function InsertData
		This.CreateCursor()
		Local loMap, i, j, cField, xValue

		For i = 1 To Alen(this.aRows, 1)
			loMap = this.aRows[i]
			Select (This.curname)
			Append BLANK
			For j = 1 to loMap.Count
				cField = loMap.GetKey(j)
				xValue = loMap.Item(j)
				replace (cField) with xValue
			EndFor
		EndFor
		Go top in (this.curName)		
	Endfunc	
	* CreateCursor
	Hidden Function CreateCursor
		Local cQuery, lcComma, j, loPair, cField, lcFlags
		cQuery  = "CREATE CURSOR " + This.curname + " ("
		lcComma = ''
		j = 0
		loPair = .Null.
		cField = ''
		
		For j = 1 to this.oTableStruct.count 
			cField  = this.oTableStruct.GetKey(j)
			loPair  = this.oTableStruct.Item(j)
			lcComma = Iif(j > 1, ',', Space(1))
			cQuery  = cQuery + lcComma + cField + Space(1)
			lcFlags = ''

			* Use Logical (faster) type for .Null. Columns.
			Do case
			case loPair.FieldType == 'X'
				loPair.FieldType = 'L'
			Case loPair.FieldType == 'C'
				lcFlags = '(' + Alltrim(Str(loPair.FieldLength)) + ')'
			Case loPair.FieldType == 'N'
				lcFlags = "(18,5)" && Integer part 18 and Decimal part 5
			EndCase
			cQuery = cQuery + loPair.FieldType + lcFlags + " NULL"			
		EndFor
		cQuery = cQuery + ')'
		Try
			&cQuery
		Catch To loEx
			Error loEx.Message
		Endtry
	Endfunc
	* ============================================================= *
	* CheckStructure
	* Adds or Updates an entry key in the oTableStruct dictionary
	* ============================================================= *
	Function CheckStructure(tcFieldName, tcType, tnLength)
		Local nFieldIdx, loPair
		nFieldIdx = This.oTableStruct.GetKey(tcFieldName)
		If nFieldIdx > 0
			loPair = This.oTableStruct.Item(nFieldIdx)
			* Check for .NULL. type and Update
			Do case
			case loPair.fieldType == 'X'
				loPair.fieldType   = tcType
				loPair.fieldLength = tnLength
				* Remove the key and registry a new one
				This.oTableStruct.Remove(nFieldIdx)
				This.oTableStruct.Add(loPair, tcFieldName)

			case loPair.fieldType == 'C' && Check string length (always saves the longest)
				If tnLength > loPair.fieldLength
					loPair.fieldLength = tnLength
					* Remove the key and registry a new one
					This.oTableStruct.Remove(nFieldIdx)
					This.oTableStruct.Add(loPair, tcFieldName)
				Endif
			EndCase
		Else
			* Insert new field.
			loPair = CreateObject('Empty')
			AddProperty(loPair, 'fieldType', tcType)
			AddProperty(loPair, 'fieldLength', tnLength)
			This.oTableStruct.Add(loPair, tcFieldName)
		Endif
	EndFunc
		
	Function match(tnTokenType)
		If this.check(tnTokenType)
			this.advance()
			Return .t.
		EndIf
		Return .f.
	EndFunc

	Hidden Function consume(tnTokenType, tcMessage)
		If this.check(tnTokenType)
			Return this.advance()
		EndIf
		if empty(tcErrorMessage)
			tcErrorMessage = "Parser Error: expected token '" + _screen.jsonUtils.tokenTypeToStr(tnTokenType) + "' got = '" + _screen.jsonUtils.tokenTypeToStr(this.peek.type) + "'"
		endif
		error tcErrorMessage
	endfunc

	Hidden Function check(tnTokenType)
		If this.isAtEnd()
			Return .f.
		EndIf
		Return this.peek.type == tnTokenType
	EndFunc 

	Hidden Function advance
		If !this.isAtEnd()
			this.current = this.current + 1
		EndIf
		Return this.tokens[this.current-1]
	endfunc

	Hidden Function isAtEnd
		Return this.peek.type == T_EOF
	endfunc

	Hidden Function peek_access
		Return this.tokens[this.current]
	endfunc

	Hidden Function previous_access
		Return this.tokens[this.current-1]
	EndFunc

Enddefine
