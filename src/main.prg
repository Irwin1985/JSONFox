&& ******************************************************************************************* &&
&&  program:        main.prg
&&  author:         Irwin Rodríguez <rodriguez.irwin@gmail.com>
&&  date:           28 july 20, 10:19:50
&&  summary:        Libraries collection for JSON Parsing
&&  performance: 	big-o(n)
&& ******************************************************************************************* &&
Set Path To "src" Additive
Set Procedure To "JsonClass" Additive
Set Procedure To "JsonDecorator" Additive
If Type("_Screen.Json") = "U"
	=AddProperty(_Screen, "Json", .Null.)
Endif
_Screen.Json = Createobject("JsonClass")
Return
