#include "JSONFox.h"
* ArrayToCursor
Define Class ArrayToCursor As Session
	#Define STRING_MAX_SIZE	254

	curname 	 = ""
	nSessionID 	 = 0
	oTableStruct = .Null.
	
	Dimension aRows(1)
	nRowCount = 0

	lexer = .Null.
	cur_token = 0
	peek_token = 0

	Function Init(toLexer)
		This.lexer = toLexer
		This.oTableStruct = Createobject('Collection')
		This.next_token()
		This.next_token()
	Endfunc

	&& ======================================================================== &&
	&& Function Array
	&& EBNF -> 	array  	= '[' object | { ',' object }  ']'
	&& ======================================================================== &&
	Function Array As Void

		If Empty(This.nSessionID)
			This.nSessionID = Set("Datasession")
		Endif
		Set DataSession To (This.nSessionID)

		This.eat(T_LBRACKET, "Expect '[' before Array definition.")
		this.nRowCount = 1
		Dimension this.aRows(this.nRowCount)
		this.aRows[this.nRowCount] = This.Object()

		Do While This.cur_token.Type == T_COMMA
			This.eat(T_COMMA)
			this.nRowCount = this.nRowCount + 1
			Dimension this.aRows[this.nRowCount]
			this.aRows[this.nRowCount] = This.Object()
		Enddo

		This.eat(T_RBRACKET, "Expect ']' after Array definition.")
		This.InsertData()
	Endfunc
	&& ======================================================================== &&
	&& Function Object
	&& EBNF -> 	object 	= '{' kvp | { ',' kvp} '}'
	&& ======================================================================== &&
	Hidden Function Object As Void
		Local loCollection, loPair
		This.eat(T_LBRACE, "Expect '{' before json object.")
		loCollection = Createobject("Collection")

		loPair = This.kvp()
		loCollection.Add(loPair.Value, loPair.Field)

		Do While This.cur_token.Type == T_COMMA
			This.eat(T_COMMA)
			loPair = This.kvp()
			loCollection.Add(loPair.Value, loPair.Field)
		Enddo
		This.eat(T_RBRACE, "Expect '}' after json object.")
		
		Return loCollection
	Endfunc
	&& ======================================================================== &&
	&& Function Kvp
	&& EBNF -> 	kvp 	= KEY ':' value
	&& 			value	= STRING | NUMBER | BOOLEAN	| NULL
	&& ======================================================================== &&
	Hidden Function kvp
		Local lcProp, lxValue, lcType, lnFieldLength, lcFieldName, loPair
		lcProp = This.cur_token.Value
				
		This.eat(T_STRING, "Expect right key element")
		This.eat(T_COLON, "Expect ':' after key element.")
		
		lcFieldName = Space(1)
		lxValue = .f.
		
		If Inlist(This.cur_token.Type, T_STRING, T_NUMBER, T_BOOLEAN, T_NULL)
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
		Else
			Error "Parser Error: Unknown token value '" + Transform(This.cur_token.Value) + "'"
		EndIf

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
		Local lexeme
		Do Case
		Case This.cur_token.Type == T_STRING
			lexeme = This.cur_token.Value
			This.eat(T_STRING)
			Return lexeme
		Case This.cur_token.Type == T_NUMBER
			lexeme = This.cur_token.Value
			This.eat(T_NUMBER)
			nVal = Val(lexeme)
			Return Iif(At('.', lexeme) > 0, nVal, Int(nVal))
		Case This.cur_token.Type == T_BOOLEAN
			lexeme = This.cur_token.Value
			This.eat(T_BOOLEAN)
			Return (lexeme == 'true')
		Case This.cur_token.Type == T_NULL
			This.eat(T_NULL)
			Return .Null.
		Otherwise
			Error "Parser Error: Unknown token value '" + Transform(This.cur_token.Value) + "'"
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
	Endfunc
	* DefaultValue
	Hidden Function DefaultValue(tcType)
		Do Case
		Case tcType $ "CDTBGMQVWX"
			Do Case
			Case tcType == 'D'
				Return Ctod("{}")
			Case tcType == 'T'
				Return Ctot("{//::}")
			case tcType == 'X'
				Return .Null.
			Otherwise
				Return ''
			Endcase
		Case tcType $ "YFIN"
			Return 0
		Case tcType = 'L'
			Return .F.
		Otherwise
			Return .Null.
		Endcase
	EndFunc
	
	Function next_token
		This.cur_token = This.peek_token
		This.peek_token = This.lexer.next_token()
	Endfunc

	Function eat(tnTokenType, tcErrorMessage)
		If This.cur_token.Type == tnTokenType
			This.next_token()
		Else
			If Empty(tcErrorMessage)
				tcErrorMessage = "Parser Error: expected token '" + Transform(tnTokenType) + "' got = '" + Transform(This.cur_token.Type) + "'"
			Endif
			Error tcErrorMessage
		Endif
	Endfunc
Enddefine
