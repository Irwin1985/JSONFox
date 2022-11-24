#include "JSONFox.h"
Define Class NETScanner As Custom
	Hidden capacity
	Hidden Length
	Hidden Scanner
	Dimension tokens[1]

	Function Init(strInput)
		With This
			.Scanner = Createobject("JSONFoxHelper.Lexer")
			.Scanner.ReadString(strInput)
			.Length   = 1
			.capacity = 0
		Endwith
	Endfunc

	Function scanTokens
		With This
			Local loToken
			Dimension .tokens[1]
			loToken = .Scanner.NextToken()
			.addToken(loToken.Type, loToken.Value, 1)

			Do While loToken.Type != 0 && 0 T_NONE
				loToken = .Scanner.NextToken()
				.addToken(loToken.Type, loToken.Value, 1)
			Enddo
			.addToken(T_EOF, "", 1)
			.capacity = .Length-1

			* Shrink array
			Dimension .tokens[.capacity]

			Return @.tokens
		Endwith
	Endfunc

	Hidden Function addToken(tnTokenType, tcTokenValue, tnLine)
		With This
			.checkCapacity()
			Local loToken
			loToken = Createobject("Empty")
			=AddProperty(loToken, "type",  tnTokenType)
			=AddProperty(loToken, "value", tcTokenValue)
			=AddProperty(loToken, "line",  tnLine)

			.tokens[.length] = loToken
			.Length = .Length + 1
		Endwith
	Endfunc

	Hidden Function checkCapacity
		With This
			If .capacity < .Length + 1
				If Empty(.capacity)
					.capacity = 8
				Else
					.capacity = .capacity * 2
				Endif
				Dimension .tokens[.capacity]
			Endif
		Endwith
	Endfunc

Enddefine