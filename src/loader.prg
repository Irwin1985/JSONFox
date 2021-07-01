#include "JSONFox.h"

* load all classes
Set Procedure To "src\JSONClass" 		Additive
Set Procedure To "src\Tokenizer" 		Additive
&& >>>>>>> IRODG 07/01/21  
Set Procedure To "src\NetScanner" 		Additive
&& <<<<<<< IRODG 07/01/21
Set Procedure To "src\Parser" 			Additive
Set Procedure To "src\JSONUtils" 		Additive
Set Procedure To "src\ArrayToCursor" 	Additive
Set Procedure To "src\CursorToArray" 	Additive
Set Procedure To "src\JSONStringify" 	Additive
Set Procedure To "src\ObjectToJSON" 	Additive
Set Procedure To "src\JSONToRTF" 		Additive
Set Procedure To "src\StructureToJSON" 	Additive

* Include Toml files
Set Procedure To "src\toml_lexer" 		Additive
Set Procedure To "src\toml_parser" 		Additive
Set Procedure To "src\toml_class" 		Additive

* JsonUtils object ***(DO NOT MANIPULATE)***
If Type('_SCREEN.JsonUtils') != 'U'
	=Removeproperty(_Screen, 'JsonUtils')
Endif
=AddProperty(_Screen, 'JsonUtils', Createobject("JSONUtils"))

* Global Regular Expression object  (YOU MAY MANIPULATE IT).
If Type('_SCREEN.oRegEx') != 'U'
	=Removeproperty(_Screen, 'oRegEx')
Endif
=AddProperty(_Screen, 'oRegEx', Createobject("VBScript.RegExp"))
_Screen.oRegEx.Global = .T.

* Main JSON class handler.
If Type("_Screen.Json") != "U"
	=Removeproperty(_Screen, 'Json')
Endif
=AddProperty(_Screen, "Json", Createobject("JsonClass"))

* Main TOML class handler
If Type("_Screen.Toml") != "U"
	=Removeproperty(_Screen, 'Toml')
Endif
=AddProperty(_Screen, "Toml", Createobject("TomlClass"))

Return