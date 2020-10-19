&& ******************************************************************************************* &&
&&  program:        main.prg
&&  author:         Irwin Rodríguez <rodriguez.irwin@gmail.com>
&&  date:           28 july 20, 10:19:50
&&  summary:        Libraries collection for JSON Parsing
&&  performance: 	big-o(n)
&& ******************************************************************************************* &&


Set procedure to "src\ArrayToArray" Additive
Set procedure to "src\ArrayToCursor" Additive
Set procedure to "src\CursorToArray" Additive
Set procedure to "src\FoxQueue" Additive
Set procedure to "src\JSONClass" Additive
Set procedure to "src\JSONClassToken" Additive
Set procedure to "src\JSONDecorator" Additive
Set procedure to "src\JsonLexer" Additive
Set procedure to "src\JsonParser" Additive
Set procedure to "src\JSONStringify" Additive
Set procedure to "src\JSONToRTF" Additive
Set procedure to "src\JSONUtils" Additive
Set procedure to "src\ObjectToJSON" Additive
Set procedure to "src\StreamReader" Additive
Set procedure to "src\StructureToJSON" Additive

If Type("_Screen.Json") = "U"
	=AddProperty(_Screen, "Json", .Null.)
Endif
_Screen.Json = Createobject("JsonClass")
Return
