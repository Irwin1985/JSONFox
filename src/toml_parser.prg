#include toml.h
&& ======================================================================== &&
&& Parser
&& BNF Grammar
&& object ::= key_value_pair
&&         | empty
&& 
&& empty ::= comment | None
&& 
&& comment ::= '#' ([^#])*
&& 
&& key_value_pair ::= ident '=' value (ident '=' value)*
&&                 | entry (key_value_pair)*
&& 
&& entry ::= '[' ident ('.' ident)* ']'
&& 
&& value ::= STRING | INTEGER | ARRAY | TABLE | BOOLEAN | DATE
&& ======================================================================== &&

Define Class TomlParser As Custom
	cur_token = .Null.
	peek_token = .Null.
	lexer = .Null.
	dimension errors(1)
	error_index = 0
	
	function init(lexer)
		this.lexer = lexer
		&& Advances the tokens
		this.next_token()
		this.next_token()
	endfunc
	
	function next_token
		this.cur_token = this.peek_token
		this.peek_token = this.lexer.get_next_token()
	endfunc

	Function parse
		this.error_index = 0
		return this.parse_object()
	endfunc

	function skip_new_line
		do while this.cur_token_is(T_NEW_LINE)
			this.next_token()
		enddo
	endfunc
	
	Hidden function parse_object
		local obj
		obj = createobject("Empty")
		this.skip_new_line()
		do while this.cur_token.type != T_EOF
			this.parse_statement(@obj)
			if this.cur_token_is(T_NEW_LINE)
				this.next_token() && skip T_NEW_LINE
			endif
		enddo
		return obj
	endfunc
	
	Hidden function parse_statement(parent_obj)
		this.skip_new_line()
		do case
		case this.cur_token.type = T_LBRACKET
			local obj_ref
			obj_ref = this.parse_entry(@parent_obj)
			this.next_token() && skip T_NEW_LINE
			*(this.cur_token.type != T_LBRACKET and this.lexer.last_token.type != T_ASSIGN) and 
			do while this.cur_token.type != T_LBRACKET and !this.cur_token.type == T_EOF
				this.parse_statement(@obj_ref)
				if this.cur_token_is(T_NEW_LINE)
					this.next_token() && skip T_NEW_LINE
				endif
			enddo
		case inlist(this.cur_token.type, T_IDENT, T_STRING)
			this.parse_key_value_pair(@parent_obj)			
		otherwise
			this.append_error('unexpected token ' + transform(this.cur_token.type))
		endcase
	endfunc
	
	Hidden function parse_key_value_pair(parent_obj)
		local key_name, nested_ref_obj
		key_name = this.parse_key(this.cur_token.value)
		this.next_token()
		if this.cur_token_is(T_DOT)
			if type('parent_obj.&key_name') = 'U'
				=addproperty(parent_obj, key_name, createobject('Empty'))
			endif
			nested_ref_obj = parent_obj. &key_name
			do while this.cur_token_is(T_DOT)
				this.next_token() && skip '.'
				key_name = this.parse_key(this.cur_token.value)
				if this.peek_token_is(T_DOT)
					if type('nested_ref_obj.&key_name') = 'U'
						=addproperty(nested_ref_obj, key_name, createobject('Empty'))
					endif
					nested_ref_obj = nested_ref_obj. &key_name
					if type('nested_ref_obj') != 'O'
						error 'Invalid object conversion'
					endif
				endif
				this.next_token() && skip T_IDENT
			enddo
		endif
		this.next_token() && skip T_ASSIGN
		
		if not this.cur_token_is(T_LBRACKET)
			if type('nested_ref_obj') = 'O'
				if type('nested_ref_obj.&key_name') = 'U'
					addproperty(nested_ref_obj, key_name, this.parse_value(@nested_ref_obj, key_name))
				else
					nested_ref_obj. &key_name = this.parse_value(@nested_ref_obj, key_name)
				endif
			else
				if type('parent_obj.&key_name') = 'U'
					addproperty(parent_obj, key_name, this.parse_value(@parent_obj, key_name))
				else
					parent_obj. &key_name = this.parse_value(@parent_obj, key_name)
				endif
			endif
		else
			if type('nested_ref_obj') = 'O'
				this.parse_value(@nested_ref_obj, key_name)
			else
				this.parse_value(@parent_obj, key_name)
			endif
		endif
	endfunc
	
	function parse_key(key_name)
		local new_key
		new_key = strtran(strtran(strtran(key_name, '-', '_'), space(1), '_'), '.', '_')
		if isdigit(left(new_key, 1))
			new_key = '_' + new_key
		endif
		return new_key
	endfunc
	
	Hidden function parse_value(parent_obj, key_name)
		local vLexeme
		do case
		case this.cur_token_is(T_STRING)
			vLexeme = this.cur_token.value
			this.next_token()
			return vLexeme
		case this.cur_token_is(T_NUMBER) and not this.peek_token_is(T_DASH)
			vLexeme = this.cur_token.value
			this.next_token()
			return vLexeme
		case this.cur_token_is(T_BOOLEAN)
			vLexeme = this.cur_token.value
			this.next_token()
			return vLexeme == 'true'
		case this.cur_token_is(T_DATE)
			vLexeme = this.cur_token.value
			this.next_token()
			If Occurs('-', vLexeme) >= 2
				vLexeme = this.parse_date(vLexeme)
				If Isnull(vLexeme)
					vLexeme = ctod('{}')
				endif
			endif
			return vLexeme
		case this.cur_token_is(T_LBRACKET)
			return this.parse_array(@parent_obj, key_name)
		otherwise
			this.append_error('unknown token value: ' + transform(this.cur_token.value))
		endcase
	endfunc
	
	function parse_entry(parent_obj)
		this.next_token() && skip the '['
		local key_name, nested_ref_obj
		key_name = this.parse_key(this.cur_token.value)
		this.next_token()
		if type('parent_obj.&key_name') = 'U'
			=addproperty(parent_obj, key_name, createobject('Empty'))
		endif
		nested_ref_obj = parent_obj. &key_name
		if this.cur_token_is(T_DOT)
			do while this.cur_token_is(T_DOT)
				this.next_token() && skip '.'
				key_name = this.parse_key(this.cur_token.value)
				if type('nested_ref_obj.&key_name') = 'U'
					=addproperty(nested_ref_obj, key_name, createobject('Empty'))
				endif
				nested_ref_obj = nested_ref_obj. &key_name
				if type('nested_ref_obj') != 'O'
					error 'Invalid object conversion'
				endif
				this.next_token() && skip T_IDENT
			enddo
		endif
		this.next_token() && skip the ']'
		return @nested_ref_obj
	endfunc

	Hidden Function parse_array(parent_obj, key_name)
		AddProperty(parent_obj, key_name + "(1)", 0)
		this.next_token() && advance the '['
		If not this.cur_token_is(T_RBRACKET)
			local nindex
			nindex = 0
			this.array_push(@parent_obj, key_name, @nindex)
			Do While this.cur_token_is(T_COMMA)
				this.next_token()
				this.array_push(@parent_obj, key_name, @nindex)
			Enddo
		Endif
		this.next_token()  && advance the ']'
	Endfunc

	Hidden Function array_push(parent_obj, key_name, cur_index)
		cur_index = cur_index + 1
		local lcCmd
		lcCmd = "DIMENSION parent_obj." + key_name + "(" + Alltrim(Str(cur_index)) + ")"
		&lcCmd
		lcCmd = "parent_obj." + key_name + "[" + Alltrim(Str(cur_index)) + "] = This.parse_value(@parent_obj, key_name)"
		&lcCmd
	endfunc

	function cur_token_is(token_type)
		return this.cur_token.Type == token_type
	endfunc

	function peek_token_is(token_type, error_msg)
		return this.peek_token.type == token_type
	endfunc
	
	function expect_peek(token_type)
		if this.peek_token_is(token_type)
			this.next_token()
			return .t.
		else
			this.append_error('expected next token to be ' + transform(token_type) + ', got ' + transform(this.peek_token.type) + ' instead')
			return .f.
		endif
	endfunc
	
	function append_error(error_msg)
		this.error_index = this.error_index + 1
		dimension this.errors(this.error_index)
		this.errors[this.error_index] = error_msg
	endfunc

	Function parse_date(tcDate)
		Local cStr, lIsDateTime, lDate
		cStr 		= ''
		lIsDateTime = .F.
		lDate		= .Null.
		cStr 		= Strtran(tcDate, '-')
		If Occurs(':', tcDate) >= 2 .And. Len(Alltrim(tcDate)) <= 25
			lIsDateTime = .T.
			Do Case
			Case "." $ tcDate And "T" $ tcDate && JavaScript built-in JSON object format. 'YYYY-mm-ddTHH:mm:ss.ms'
				cStr = Strtran(tcDate, "T")
				cStr = Substr(cStr, 1, At(".", cStr) - 1)
				cStr = Strtran(cStr, '-')
				cStr = Strtran(cStr, ':')
				tcDate = Substr(Strtran(tcDate, "T", Space(1)), 1, At(".", tcDate) - 1)
			Case "T" $ tcDate And Occurs(':', tcDate) = 3 && ISO 8601 format. 'YYYY-mm-ddTHH:mm:ss-ms:00'
				cStr = Strtran(tcDate, "T")
				cStr = Substr(cStr, 1, At("-", cStr, 3) - 1)
				cStr = Strtran(cStr, '-')
				cStr = Strtran(cStr, ':')
				tcDate = Substr(Strtran(tcDate, "T", Space(1)), 1, At("-", tcDate, 3) - 1)
			Otherwise
				cStr = Strtran(cStr, ':')
				cStr = Strtran(Lower(cStr), 'am')
				cStr = Strtran(Lower(cStr), 'pm')
				cStr = Strtran(cStr, Space(1))
				tcDate = Substr(tcDate, 1, At(Space(1), tcDate, 2) - 1)
			Endcase
		Endif
		For i=1 To Len(cStr) Step 1
			If Isdigit(Substr(cStr, i, 1))
				Loop
			Else
				Return .Null.
			Endif
		Endfor
		lcYear  = Left(tcDate, 4)
		lcMonth = Strextract(tcDate, '-', '-', 1)
		If !lIsDateTime
			lcDay = Right(tcDate, 2)
		Else
			lcDay = Strextract(tcDate, '-', Space(1), 2)
		Endif
		If Val(lcYear) > 0 And Val(lcMonth) > 0 And Val(lcDay) > 0
			If !lIsDateTime
				lDate = Date(Val(lcYear), Val(lcMonth), Val(lcDay))
			Else
				lcHour = Substr(tcDate, 12, 2)
				lcMin  = Strextract(tcDate, ':', ':', 1)
				lcSecs = Right(tcDate, 2)
				lDate  = Datetime(Val(lcYear), Val(lcMonth), Val(lcDay), Val(lcHour), Val(lcMin), Val(lcSecs))
			Endif
		Else
			lDate = Iif(!lIsDateTime, {//}, {//::})
		Endif
		Return lDate
	Endfunc
enddefine