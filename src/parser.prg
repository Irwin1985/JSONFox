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
	lexer = .null.
	cur_token = 0
	peek_token = 0
	function init(toLexer)
		this.lexer = toLexer
		this.next_token()
		this.next_token()
	endfunc

	function next_token
		this.cur_token = .null.
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

	function Parse
		lvNewVal = .null.
		do case
		case this.cur_token.type == T_STRING
			return _screen.jsonUtils.CheckString(this.cur_token.value)
		case this.cur_token.type == T_NUMBER
			nVal = val(this.cur_token.value)
			return iif(at('.', this.cur_token.value) > 0, nVal, int(nVal))
		case this.cur_token.type == T_BOOLEAN
			return (this.cur_token.value == 'true')
		case this.cur_token.type == T_LBRACE
			return this.object()
		case this.cur_token.type == T_LBRACKET
			local MyArray, nIndex
			MyArray = createobject("Empty")
			=addproperty(MyArray, '_[1]', 0)
			this.eat(T_LBRACKET)
			nIndex = 1
			if this.cur_token.type != T_RBRACKET

				dimension MyArray._(nIndex)
				MyArray._[nIndex] = this.value()

				do while this.cur_token.type = T_COMMA
					this.eat(T_COMMA)
					nIndex = nIndex + 1
					dimension MyArray._(nIndex)
					MyArray._[nIndex] = this.value()
				enddo
			endif
			this.eat(T_RBRACKET, "Expect ']' after array elements.")
			return MyArray
		case this.cur_token.type == T_NULL
			return .null.
		otherwise
			error "Parser Error: Unknown token type '" + transform(this.cur_token.type) + "'"
		endcase
	endfunc
	&& ======================================================================== &&
	&& Function Object
	&& EBNF -> 	object = '{' kvp ( ',' kvp )* '}'
	&& 			kvp    = KEY ':' value
	&& ======================================================================== &&
	hidden function object as object
		local obj
		obj = createobject('Empty')
		this.eat(T_LBRACE)
		if this.cur_token.type != T_RBRACE
			this.kvp(@obj)
			do while this.cur_token.type == T_COMMA
				this.eat(T_COMMA)
				this.kvp(@obj)
			enddo
		endif
		this.eat(T_RBRACE, "Expect '}' after JSON body.")

		return obj
	endfunc
	&& ======================================================================== &&
	&& Function Kvp
	&& EBNF -> 	kvp = KEY ':' value
	&& ======================================================================== &&
	hidden function kvp(toObj)
		local lcKeyElement
		lcKeyElement = this.cur_token.value
		this.eat(T_STRING, "Expect right key element")
		this.eat(T_COLON, "Expect ':' after key element.")

		if this.cur_token.type != T_LBRACKET
			=addproperty(toObj, _screen.jsonUtils.CheckProp(lcKeyElement), this.value(toObj, lcKeyElement))
		else
			this.value(toObj, lcKeyElement) &&Array element
		endif
	endfunc
	&& ======================================================================== &&
	&& Function Value
	&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | array | object | NULL
	&& ======================================================================== &&
	hidden function value(toObj2, tcProperty)
		local lvNewVal
		lvNewVal = .null.
		do case
		case this.cur_token.type == T_STRING
			lvNewVal = this.cur_token.value
			this.eat(T_STRING)
			return _screen.jsonUtils.CheckString(lvNewVal)
		case this.cur_token.type == T_NUMBER
			lvNewVal = this.cur_token.value
			this.eat(T_NUMBER)
			local nVal
			nVal = val(lvNewVal)
			return iif(at('.', lvNewVal) > 0, nVal, int(nVal))
		case this.cur_token.type == T_BOOLEAN
			lvNewVal = this.cur_token.value
			this.eat(T_BOOLEAN)
			return (lvNewVal == 'true')
		case this.cur_token.type == T_LBRACE
			return this.object()
		case this.cur_token.type == T_LBRACKET
			return this.array(toObj2, tcProperty)
		case this.cur_token.type == T_NULL
			this.eat(T_NULL)
			return .null.
		otherwise
			error "Parser Error: Unknown token value: '" + transform(this.cur_token.value) + "'"
		endcase
	endfunc
	&& ======================================================================== &&
	&& Function Array
	&& EBNF -> 	array = '[' value | { ',' value }  ']'
	&& ======================================================================== &&
	hidden function array(toObjRef, tcPropertyName)
		local llReturnObj
		llReturnObj = .f.
		this.eat(T_LBRACKET)
		if empty(tcPropertyName)
			toObjRef = createobject('Empty')
			tcPropertyName = '_'
			llReturnObj = .t.
		else
			tcPropertyName = _screen.jsonUtils.CheckProp(tcPropertyName)
		endif
		&& >>>>>>> IRODG 01/17/22
		if inlist(tcPropertyName, 'update', 'delete') && these arrays names cause internal error on 'empty' based objects.
			tcPropertyName = '_' + tcPropertyName
		endif
		&& <<<<<<< IRODG 01/17/22
		=addproperty(toObjRef, tcPropertyName + "(1)", 0)

		if this.cur_token.type != T_RBRACKET
			local nIndex
			nIndex = 0
			this.ArrayPush(toObjRef, tcPropertyName, @nIndex)
			do while this.cur_token.type == T_COMMA
				this.eat(T_COMMA)
				this.ArrayPush(toObjRef, tcPropertyName, @nIndex)
			enddo
		endif
		this.eat(T_RBRACKET, "Expect ']' after array elements.")

		if llReturnObj
			return toObjRef
		endif
	endfunc
	&& ======================================================================== &&
	&& Hidden Function ArrayPush
	&& ======================================================================== &&
	hidden function ArrayPush(toObjRef, tcPropName, tnCurrentIndex)
		tnCurrentIndex = tnCurrentIndex + 1
		lcCmd = "DIMENSION toObjRef." + tcPropName + "(" + alltrim(str(tnCurrentIndex)) + ")"
		&lcCmd
		lcCmd = "toObjRef." + tcPropName + "[" + alltrim(str(tnCurrentIndex)) + "] = This.Value()"
		&lcCmd
	endfunc
enddefine
