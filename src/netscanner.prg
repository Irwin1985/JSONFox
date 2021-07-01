define class NETScanner as custom
	function init(strInput)
		public ns
		ns = createobject("JSONFoxHelper.Lexer")
		ns.ReadString(strInput)
	endfunc
	function next_token
		return ns.NextToken()
	endfunc
enddefine