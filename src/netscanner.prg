#include "JSONFox.h"
define class NETScanner as custom
	Hidden capacity
	Hidden length
	Dimension tokens[1]
	
	function init(strInput)
		public ns
		ns = createobject("JSONFoxHelper.Lexer")
		ns.ReadString(strInput)
		this.length = 1
		this.capacity = 0		
	EndFunc
	
	function scanTokens
		return ns.NextToken()
	endfunc
	
	Function scanTokens
		Local loToken
		Dimension this.tokens[1]
		loToken = ns.NextToken()
		this.addToken(loToken.type, loToken.value, 1)
		
		Do while loToken.type != T_EOF
			loToken = ns.NextToken()
			this.addToken(loToken.type, loToken.value, 1)
		EndDo
		this.addToken(T_EOF, "", 1)
		this.capacity = this.length-1
		
		* Shrink array
		Dimension this.tokens[this.capacity]
		
		Return @this.tokens
	EndFunc

	hidden function addToken(tnTokenType, tcTokenValue, tnLine)
		this.checkCapacity()
		local loToken
		loToken = createobject("Empty")
		=addproperty(loToken, "type", tnTokenType)
		=addproperty(loToken, "value", tcTokenValue)
		=AddProperty(loToken, "line", tnLine)
		
		this.tokens[this.length] = loToken
		this.length = this.length + 1		
	EndFunc
	
	Hidden function checkCapacity
		If this.capacity < this.length + 1
			If Empty(this.capacity)
				this.capacity = 8
			Else
				this.capacity = this.capacity * 2
			EndIf			
			Dimension this.tokens[this.capacity]
		EndIf
	endfunc

enddefine