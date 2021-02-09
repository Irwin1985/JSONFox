* TOMLClass
define class TOMLClass as custom
	version = "1.0"
	hidden toml_lexer
	hidden toml_parser
	
	function Parse as memo
		lparameters tcTomlStr as memo
		local loTOMLObj as object
		loTOMLObj = .null.
		try
			toml_lexer  = createobject("TomlLexer", tcTomlStr)
			toml_parser = createobject("TomlParser", toml_lexer)
			loTOMLObj   = toml_parser.parse()
		catch to loEx
			wait "ErrorNo: " 	+ str(loEx.errorno) 	+ chr(13) + ;
				"Message: " 	+ loEx.message 			+ chr(13) + ;
				"LineNo: " 		+ str(loEx.lineno) 		+ chr(13) + ;
				"Procedure: " 	+ loEx.procedure window nowait
		endtry
		return loTOMLObj
	endfunc
enddefine