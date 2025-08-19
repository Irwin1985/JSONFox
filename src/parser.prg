#include "JSONFox.h"
&& ======================================================================== &&
&& JsonParser
&& EBNF Grammar
&& object = '{' kvp | { ',' kvp } '}'
&& kvp    = KEY ':' value
&& value  = STRING | NUMBER | BOOLEAN | array | object | null
&& array  = '[' value | { ',' value }  ']'
&& ======================================================================== &&
define class Parser as custom
	Hidden current
	Hidden previous
	Hidden peek
	hidden problematicFields
	hidden tokenCollection
	hidden lUseArrayObjects
	
	function init(toScanner, tlUseArrayObjects)
		this.tokenCollection = toScanner.scanTokens()
		this.current = 1
		this.lUseArrayObjects = IIF(PCOUNT() > 1, tlUseArrayObjects, .F.)		
		this.problematicFields = createobject("Collection")
		this.problematicFields.Add("messages", "messages")
		this.problematicFields.Add("update", "update")
	endfunc

	function Parse
		local loParsedObject
		loParsedObject = this.value()
		this.CleanUp()

		return loParsedObject
	endfunc
	&& ======================================================================== &&
	&& Function Object
	&& EBNF -> 	object = '{' kvp ( ',' kvp )* '}'
	&& 			kvp    = KEY ':' value
	&& ======================================================================== &&
	hidden function object as object
		local loObj, loPair, lcMacro
		loObj = createobject('Empty')
		if !this.check(T_RBRACE)
			loPair = this.kvp()
			this.addKeyValuePair(@loObj, @loPair)
			
			do while this.match(T_COMMA)
				loPair = this.kvp()
				this.addKeyValuePair(@loObj, @loPair)
			enddo
		endif
		this.consume(T_RBRACE, "Expect '}' after JSON body.")			
		return loObj
	endfunc
	&& ======================================================================== &&
	&& Function Kvp
	&& EBNF -> 	kvp = KEY ':' value
	&& ======================================================================== &&
	hidden function kvp(toObj)		
		local loPair, lvValue
		
		loPair = CreateObject('Empty')
		=AddProperty(loPair, 'key', '')
	
		this.consume(T_STRING, "Expect key name")
		loPair.key = _screen.jsonUtils.CheckProp(this.previous.value)
		this.consume(T_COLON, "Expect ':' after key element.")
		lvValue = this.value()

		if this.lUseArrayObjects
			=AddProperty(loPair, 'value', lvValue)
		else
			If Type('lvValue', 1) != 'A'
				=AddProperty(loPair, 'value', lvValue)
			Else
				=AddProperty(loPair, 'value[1]', .Null.)
				Acopy(lvValue, loPair.value)
			endif
		endif

		Return loPair
	EndFunc

	Hidden function addKeyValuePair(toObject, toPair)
		local lAddObject
		lAddObject = .f.
		if this.lUseArrayObjects
			=AddProperty(toObject, toPair.key, toPair.value)			
		else
			If Type('toPair.value', 1) != 'A'
				=AddProperty(toObject, toPair.key, toPair.value)
			else
				lAddObject = .t.
			endif
		endif

		if lAddObject
			local lcMacro
			if this.problematicFields.GetKey(toPair.key) > 0
				local lcArrayName		
				lcArrayName = toPair.key + "_array"				
				lcMacro = "AddProperty(toObject, '" + lcArrayName + "[1]', .null.)"
				&lcMacro
				
				lcMacro = "Acopy(toPair.value, toObject." + lcArrayName + ")"
				&lcMacro
				
				=addproperty(toObject, "_specialArray_" + lcArrayName, toPair.key)
			else
				Local lcMacro
				lcMacro = "AddProperty(toObject, '" + toPair.key + "[1]', .Null.)"
				&lcMacro
				lcMacro = "Acopy(toPair.value, toObject." + toPair.key + ")"
				&lcMacro
			endif
		endif
	EndFunc
		
	&& ======================================================================== &&
	&& Function Value
	&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | array | object | NULL
	&& ======================================================================== &&
	hidden function value
		do case
		case this.match(T_STRING)
			return _screen.jsonUtils.CheckString(this.previous.value)
			
		case this.match(T_NUMBER)
			Local lcValue, lcPoint
			lcValue = this.previous.value
			lcPoint = Set("Point")
			
			If lcPoint != '.'
				lcValue = Strtran(lcValue, '.', lcPoint)
			EndIf
			return iif(at(lcPoint, lcValue) > 0, Val(lcValue), int(Val(lcValue)))
			
		case this.match(T_BOOLEAN)
			return (this.previous.value == 'true')

		case this.match(T_LBRACE)
			return this.object()

		case this.match(T_LBRACKET)
			if this.lUseArrayObjects
				return this.array()
			endif
			return @this.array()
			
		case this.match(T_NULL)
			return .null.
		otherwise
			error "Parser Error: Unknown token value: '" + _screen.jsonUtils.tokenTypeToStr(this.peek.type) + "'"
		EndCase
	endfunc
	&& ======================================================================== &&
	&& Function Array
	&& EBNF -> 	array = '[' value | { ',' value }  ']'
	&& ======================================================================== &&
	hidden function array
		local laArray
		if this.lUseArrayObjects
			laArray = createobject("TParserInternalArrayCollectionBased")
		else
			laArray = createobject("TParserInternalArray")
		endif
		
		If !this.check(T_RBRACKET)
			laArray.Push(this.value())
			do while this.match(T_COMMA)
				laArray.Push(this.value())
			enddo
		endif
		this.consume(T_RBRACKET, "Expect ']' after array elements.")

		if this.lUseArrayObjects
			return laArray
		endif
		return @laArray.getArray()
	endfunc
	
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
		if empty(tcMessage)
			tcMessage = "Parser Error: expected token '" + _screen.jsonUtils.tokenTypeToStr(tnTokenType) + "' got = '" + _screen.jsonUtils.tokenTypeToStr(this.peek.type) + "'"
		endif
		error tcMessage
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
		Return this.tokenCollection.tokens[this.current-1]
	endfunc

	Hidden Function isAtEnd
		Return this.peek.type == T_EOF
	endfunc

	Hidden Function peek_access
		Return this.tokenCollection.tokens[this.current]
	endfunc

	Hidden Function previous_access
		Return this.tokenCollection.tokens[this.current-1]
	endfunc
	
	function CleanUp
		with this
			.TokenCollection = .null.
			.current = 0
			.previous = .null.
			.peek = .null.
		endwith
	endfunc
	
EndDefine

* ============================================================ *
* TParserInternalArray
* ============================================================ *
Define Class TParserInternalArray As Custom
	Dimension aCustomArray[1]
	nIndex = 0
	
	Function Push(tvItem)
		this.nIndex = this.nIndex + 1
		Dimension this.aCustomArray[this.nIndex]
		this.aCustomArray[this.nIndex] = tvItem
	Endfunc
	
	Function GetArray
		Return @this.aCustomArray
	EndFunc
enddefine

* ============================================================ *
* TParserInternalArrayCollectionBased
* ============================================================ *
Define Class TParserInternalArrayCollectionBased As Collection	
	Function Push(tvItem)
		this.Add(tvItem)
	Endfunc	
	
	function Get(tnIndex)
		if between(tnIndex, 1, this.Count)
			return this.Item(tnIndex)
		endif
		
		return .null.
	endfunc
Enddefine