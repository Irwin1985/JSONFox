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
	Dimension tokens[1]
	Hidden current
	Hidden previous
	Hidden peek
	
	function init(toScanner)
		With this
			Local laTokens
			laTokens = toScanner.scanTokens()
			=Acopy(laTokens, .tokens)		
			.current = 1
		endwith
	endfunc

	function Parse	
		With this
			Return .value()
		endwith
	endfunc
	&& ======================================================================== &&
	&& Function Object
	&& EBNF -> 	object = '{' kvp ( ',' kvp )* '}'
	&& 			kvp    = KEY ':' value
	&& ======================================================================== &&
	hidden function object as object
		With this
			local loObj, loPair, lcMacro
			loObj = createobject('Empty')
			
			if !.check(T_RBRACE)
				loPair = .kvp()
				.addKeyValuePair(@loObj, @loPair)
				
				do while .match(T_COMMA)
					loPair = .kvp()
					.addKeyValuePair(@loObj, @loPair)
				enddo
			endif
			.consume(T_RBRACE, "Expect '}' after JSON body.")

			return loObj
		endwith
	endfunc
	&& ======================================================================== &&
	&& Function Kvp
	&& EBNF -> 	kvp = KEY ':' value
	&& ======================================================================== &&
	hidden function kvp(toObj)		
		With this
			local loPair, lvValue
			
			loPair = CreateObject('Empty')
			=AddProperty(loPair, 'key', '')		
			
			.consume(T_STRING, "Expect key name")
			
			loPair.key = _screen.jsonUtils.CheckProp(.previous.value)

			.consume(T_COLON, "Expect ':' after key element.")
			
			lvValue = .value()
			If Type('lvValue', 1) != 'A'
				=AddProperty(loPair, 'value', lvValue)
			Else
				=AddProperty(loPair, 'value[1]', .Null.)			
				Acopy(lvValue, loPair.value)			
			endif

			Return loPair
		EndWith
	EndFunc

	Hidden function addKeyValuePair(toObject, toPair)
		If Type('toPair.value', 1) != 'A'
			=AddProperty(toObject, toPair.key, toPair.value)
		Else
			Local lcMacro
			lcMacro = "AddProperty(toObject, '" + toPair.key + "[1]', .Null.)"
			&lcMacro
			lcMacro = "Acopy(toPair.value, toObject." + toPair.key + ")"
			&lcMacro
		EndIf
	EndFunc
		
	&& ======================================================================== &&
	&& Function Value
	&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | array | object | NULL
	&& ======================================================================== &&
	hidden function value
		With this
			do case
			case .match(T_STRING)
				return _screen.jsonUtils.CheckString(.previous.value)
				
			case .match(T_NUMBER)
				Local lcValue, lcPoint
				lcValue = .previous.value
				lcPoint = Set("Point")
				
				If lcPoint != '.'
					lcValue = Strtran(lcValue, '.', lcPoint)
				EndIf
				return iif(at(lcPoint, lcValue) > 0, Val(lcValue), int(Val(lcValue)))
				
			case .match(T_BOOLEAN)
				return (.previous.value == 'true')

			case .match(T_LBRACE)
				return .object()

			case .match(T_LBRACKET)
				return @.array()
				
			case .match(T_NULL)
				return .null.
			otherwise
				error "Parser Error: Unknown token value: '" + _screen.jsonUtils.tokenTypeToStr(.peek.type) + "'"
			EndCase
		EndWith
	endfunc
	&& ======================================================================== &&
	&& Function Array
	&& EBNF -> 	array = '[' value | { ',' value }  ']'
	&& ======================================================================== &&
	hidden function array
		With this
			local laArray
			laArray = createobject("TParserInternalArray")
			If !.check(T_RBRACKET)
				laArray.Push(.value())
				do while .match(T_COMMA)
					laArray.Push(.value())
				enddo
			endif
			.consume(T_RBRACKET, "Expect ']' after array elements.")

			return @laArray.getArray()
		endwith
	endfunc
	
	Function match(tnTokenType)
		With this
			If .check(tnTokenType)
				.advance()
				Return .t.
			EndIf
			Return .f.
		endwith
	EndFunc

	Hidden Function consume(tnTokenType, tcMessage)
		With this
			If .check(tnTokenType)
				Return .advance()
			EndIf
			if empty(tcMessage)
				tcMessage = "Parser Error: expected token '" + _screen.jsonUtils.tokenTypeToStr(tnTokenType) + "' got = '" + _screen.jsonUtils.tokenTypeToStr(.peek.type) + "'"
			endif
			error tcMessage
		EndWith
	endfunc

	Hidden Function check(tnTokenType)
		With this
			If .isAtEnd()
				Return .f.
			EndIf
			Return .peek.type == tnTokenType
		endwith
	EndFunc 

	Hidden Function advance
		With this
			If !.isAtEnd()
				.current = .current + 1
			EndIf
			Return .tokens[.current-1]
		endwith
	endfunc

	Hidden Function isAtEnd
		With this.peek
			Return .type == T_EOF
		endwith
	endfunc

	Hidden Function peek_access
		With this
			Return .tokens[.current]
		endwith
	endfunc

	Hidden Function previous_access
		With this
			Return .tokens[.current-1]
		endwith
	EndFunc
	
EndDefine

* ============================================================ *
* TParserInternalArray
* ============================================================ *
Define Class TParserInternalArray As Custom
	Dimension aCustomArray[1]
	nIndex = 0
	
	Function Push(tvItem)
		With this
			.nIndex = .nIndex + 1
			Dimension .aCustomArray[.nIndex]
			.aCustomArray[.nIndex] = tvItem
		EndWith
	Endfunc
	
	Function GetArray
		With this
			Return @.aCustomArray
		endwith
	EndFunc
Enddefine