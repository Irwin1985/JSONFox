#include "JSONFox.h"
* ArrayToCursor
define class ArrayToCursor as session
	#define STRING_MAX_SIZE	254

	curname 	= ""
	nSessionID 	= 0
	nColumns 	= 0
	hashMap 	= .null.
	cFieldList 	= ""
	
	dimension aTableStruct(1)
	tableStructCounter = 0

	lexer = .null.
	cur_token = 0
	peek_token = 0

	function init(toLexer)
		this.lexer = toLexer
		this.hashMap = createobject("Empty")
		=addproperty(this.hashMap, "field", '')
		=addproperty(this.hashMap, "value", '')
		this.next_token()
		this.next_token()
	endfunc

	function next_token
		this.cur_token = this.peek_token
		this.peek_token = this.lexer.next_token()
	endfunc

	function eat(tnTokenType, tcErrorMessage)
		if this.cur_token.type == tnTokenType
			this.next_token()
		else
			if empty(tcErrorMessage)
				tcErrorMessage = "Parser Error: expected token '" + transform(tnTokenType) + "' got = '" + transform(this.cur_token.type) + "'"
			endif
			error tcErrorMessage
		endif
	endfunc

	&& ======================================================================== &&
	&& Function Array
	&& EBNF -> 	array  	= '[' object | { ',' object }  ']'
	&& ======================================================================== &&
	function array as Void
		private oMap, JSONUtils
		oMap 		= this.hashMap
		JSONUtils 	= _screen.JSONUtils

		if empty(this.nSessionID)
			this.nSessionID = set("Datasession")
		endif
		set datasession to (this.nSessionID)

		this.eat(T_LBRACKET, "Expect '[' before Array definition.")
		nGlobalRow = 1
		dimension arrMap(nGlobalRow)
		arrMap[nGlobalRow] = this.object()

		do while this.cur_token.type == T_COMMA
			this.eat(T_COMMA)
			nGlobalRow = nGlobalRow + 1
			dimension arrMap(nGlobalRow)
			arrMap[nGlobalRow] = this.object()
		enddo

		this.eat(T_RBRACKET, "Expect ']' after Array definition.")
		this.InsertData()
	endfunc
	&& ======================================================================== &&
	&& Function Object
	&& EBNF -> 	object 	= '{' kvp | { ',' kvp} '}'
	&& ======================================================================== &&
	hidden function object as Void
		this.eat(T_LBRACE, "Expect '{' before json object.")
		oCollection = createobject("Collection")

		this.kvp()
		oCollection.add(oMap.value, oMap.field)

		do while this.cur_token.type == T_COMMA
			this.eat(T_COMMA)
			this.kvp()
			oCollection.add(oMap.value, oMap.field)
		enddo
		this.eat(T_RBRACE, "Expect '}' after json object.")
		return oCollection
	endfunc
	&& ======================================================================== &&
	&& Function Kvp
	&& EBNF -> 	kvp 	= KEY ':' value
	&& 			value	= STRING | NUMBER | BOOLEAN	| NULL
	&& ======================================================================== &&
	hidden function kvp
		local lcProp, lxValue, lcType, lnFieldLength
		lcProp = this.cur_token.value

		this.eat(T_STRING, "Expect right key element")
		this.eat(T_COLON, "Expect ':' after key element.")

		if inlist(this.cur_token.type, T_STRING, T_NUMBER, T_BOOLEAN, T_NULL)
			lxValue = this.value()
			lcType  = vartype(lxValue)
			lnFieldLength = 0
			do case
			case lcType = 'N'
				lcType = iif(occurs('.', transform(lxValue)) > 0, 'N', 'I')
			case lcType = 'C'
				if len(lxValue) > STRING_MAX_SIZE
					lcType = 'M'
				else
					lxValue  = JSONUtils.CheckString(lxValue)
					lcType   = vartype(lxValue)
				endif
				if lcType == 'C'
					lnFieldLength = iif(empty(len(lxValue)), 1, len(lxValue))
				endif
			endcase
			lcFieldName = lower(JSONUtils.CheckProp(lcProp))
			this.CheckStructure(lcFieldName, lcType, lnFieldLength)
		else
			error "Parser Error: Unknown token value '" + transform(this.cur_token.value) + "'"
		endif
		* Update Map
		oMap.field = lcFieldName
		oMap.value = lxValue
	endfunc
	&& ======================================================================== &&
	&& Function Value
	&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | NULL
	&& ======================================================================== &&
	hidden function value as Variant
		local lexeme
		do case
		case this.cur_token.type == T_STRING
			lexeme = this.cur_token.value
			this.eat(T_STRING)
			return lexeme
		case this.cur_token.type == T_NUMBER
			lexeme = this.cur_token.value
			this.eat(T_NUMBER)
			nVal = val(lexeme)
			return iif(at('.', lexeme) > 0, nVal, int(nVal))
		case this.cur_token.type == T_BOOLEAN
			lexeme = this.cur_token.value
			this.eat(T_BOOLEAN)
			return (lexeme == 'true')
		case this.cur_token.type == T_NULL
			this.eat(T_NULL)
			return .null.
		otherwise
			error "Parser Error: Unknown token value '" + transform(this.cur_token.value) + "'"
		endcase
	endfunc
	* InsertData
	hidden function InsertData
		this.CreateCursor()
		dimension aValues(1)
		aValues[1] = ''
		lcFieldList = this.cFieldList
		for i = 1 to alen(arrMap, 1)
			o = arrMap[i]
			cValues = ''
			for j = 1 to getwordcount(lcFieldList, ",")
				cField = getwordnum(lcFieldList, j, ",")
				xValue = this.defaultvalue(cField)
				try
					xValue = o.item(cField)
				catch
				endtry
				dimension aValues(j)
				aValues[j] = xValue
				cValues = cValues + iif(j > 1, ",", '') + "aValues(" + alltrim(str(j)) + ")"
			endfor
			cInsert = "INSERT INTO " + this.curname + "(" + lcFieldList + ") VALUES(" + cValues + ")"
			try
				&cInsert
			catch to loEx
			&& IRODG 20210313 ISSUE # 14 ERROR HANDLING
				error loEx.message
			&& IRODG 20210313 ISSUE # 14 ERROR HANDLING
			endtry
		endfor
	endfunc
	* CreateCursor
	hidden function CreateCursor
		cQuery  = "CREATE CURSOR " + this.curname + " ("
		nIndex  = 0
		lcComma = ""
		local lcFieldList
		lcFieldList = this.cFieldList

		for j = 1 to getwordcount(lcFieldList, ",")
			nIndex  = nIndex + 1
			lcComma = iif(nIndex > 1, ",", space(1))

			cField = getwordnum(lcFieldList, j, ",")
			lcType = this.FieldType(cField)
			lcLen  = this.FieldLen(cField)

			cQuery = cQuery + lcComma + cField + space(1)

			* Use Logical (faster) type for .Null. Columns.
			lcType  = strtran(lcType, "X", "L")
			lcFlags = iif(lcType == "C", "(" + alltrim(str(lcLen)) + ")", '')
			if lcType == "N"
				lcFlags = "(18,5)" && Integer Length 18 and Decimal length 5
			endif
			cQuery = cQuery + lcType + lcFlags + " NULL"
		endfor
		cQuery = cQuery + ")"
		try
			&cQuery
		catch to loEx
		&& IRODG 20210313 ISSUE # 14 ERROR HANDLING
			error loEx.message
		&& IRODG 20210313 ISSUE # 14 ERROR HANDLING
		endtry
	endfunc

	* CheckStructure
	function CheckStructure(tcFieldName, tcType, tnLength)
		* Find or Insert the field.
		&& >>>>>>> IRODG 12/28/21
		LOCAL nFieldIdx
*!*			nFieldIdx = ascan(this.aTableStruct, tcFieldName)
		nFieldIdx = ascan(this.aTableStruct, tcFieldName,-1,-1,0,4)
		&& >>>>>>> IRODG 12/28/21
		if nFieldIdx > 0
			* Check for .NULL. type and Update
			lcFieldType = getwordnum(this.aTableStruct[nFieldIdx], 2, "|")
			if lcFieldType = "X"
				newVal = getwordnum(this.aTableStruct[nFieldIdx], 1, "|")
				newVal = newVal + "|" + tcType
				newVal = newVal + "|" + alltrim(str(tnLength))
				this.aTableStruct[nFieldIdx] = newVal
			endif
			* Check for Length and Update
			if lcFieldType = "C"
				lnFieldLen = val(getwordnum(this.aTableStruct[nFieldIdx], 3, "|"))
				if tnLength > lnFieldLen
					newVal = getwordnum(this.aTableStruct[nFieldIdx], 1, "|")
					newVal = newVal + "|" + tcType
					newVal = newVal + "|" + alltrim(str(tnLength))
					this.aTableStruct[nFieldIdx] = newVal
				endif
			endif
		else
			* Insert new field.
			this.tableStructCounter = this.tableStructCounter + 1
			dimension this.aTableStruct(this.tableStructCounter)
			newVal = tcFieldName
			newVal = newVal + "|" + tcType
			if tcType == "C"
				newVal = newVal + "|" + alltrim(str(tnLength))
			endif
			this.aTableStruct(this.tableStructCounter) = newVal
		endif
	endfunc

	* FieldType
	hidden function FieldType(tcField)
		&& <<<<<<< IRODG 12/28/21
		LOCAL nFieldIdx
*!*			nFieldIdx = ascan(this.aTableStruct, tcField)
		nFieldIdx = ascan(this.aTableStruct, tcField,-1,-1,0,4)
		&& >>>>>>> IRODG 12/28/21
		lcType    = 'X'
		if nFieldIdx > 0
			lcType = getwordnum(this.aTableStruct[nFieldIdx], 2, "|")
		endif
		return lcType
	endfunc

	* FieldLength
	hidden function FieldLen(tcField)
		&& <<<<<<< IRODG 12/28/21
		LOCAL nFieldIdx
*!*			nFieldIdx = ascan(this.aTableStruct, tcField)
		nFieldIdx = ascan(this.aTableStruct, tcField,-1,-1,0,4)
		&& >>>>>>> IRODG 12/28/21
		lnLen     = 0
		if nFieldIdx > 0
			lnLen = val(getwordnum(this.aTableStruct[nFieldIdx], 3, "|"))
		endif
		return lnLen
	endfunc

	* DefaultValue
	hidden function defaultvalue(tcField)
		lcType = this.FieldType(tcField)
		do case
		case lcType $ "CDTBGMQVWX"
			do case
			case lcType = "D"
				return ctod("{}")
			case lcType = "T"
				return ctot("{//::}")
			otherwise
				if lcType = "X"
					return .null.
				else
					return ""
				endif
			endcase
		case lcType $ "YFIN"
			return 0
		case lcType = 'L'
			return .f.
		otherwise
			return .null.
		endcase
	endfunc
	* cFieldList_Access
	function cFieldList_Access
		local lcFieldList
		lcFieldList = ''
		for i = 1 to alen(this.aTableStruct, 1)
			lcFieldList = lcFieldList + iif(i > 1, ',', '') + getwordnum(this.aTableStruct[i], 1, "|")
		endfor
		return lcFieldList
	endfunc
enddefine
