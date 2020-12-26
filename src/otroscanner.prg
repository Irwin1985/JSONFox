#include "JSONFox.h"
* Scanner
Define Class Scanner As Custom
	Hidden source = ""
	Hidden start = 0
	Hidden current = 0
	Hidden line = 0

	* Initialize
	Function init(tcSource)
		this.source = tcSource
		this.start = 0
		this.current = 0
		this.line = 0
	EndFunc
	
	* ScanTokens
	Function scanTokens
		_screen.curtokenpos = 1
		Dimension _screen.tokens[_screen.curtokenpos]
		Do while !this.isAtEnd()
			this.start = this.current
			this.scanToken()
		EndDo
		* EOF Token
		Dimension _screen.tokens[_screen.curtokenpos + 1]
		_screen.tokens[_screen.curtokenpos + 1] = this.newToken(T_NONE, "")
	EndFunc
	
	* isAtEnd
	Function isAtEnd
		Return this.current >= Len(this.source)
	EndFunc
	
	* scanToken
*!*		Function scanToken
*!*			c = this.advance()
*!*			DO CASE
*!*			CASE c == '"'
*!*				this.string()

*!*			OTHERWISE

*!*			ENDCASE

*!*		EndFunc
	
	* string
	Function string
		Do while !this.isAtEnd()
			this.advance()
			
		EndDo
	EndFunc
	
	* advance
	Function advance
		this.current = this.current + 1
		Return Substr(this.source, this.current, 1)
	EndFunc
	
Enddefine