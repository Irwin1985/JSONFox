&& ======================================================================== &&
&& ObjectToJSON Parser
&& ======================================================================== &&
Define Class ObjectToJSON As Session
	Hidden utils
	lCentury = .F.
	cDateAct = ""
	nOrden = 0
&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
	Function Init
		Set Procedure To "JsonUtils" Additive
		This.utils = Createobject("JsonUtils")
		This.lCentury = Set("Century") == "OFF"
		This.cDateAct = Set("Date")
		Set Century On
		Set Date Ansi
		Mvcount = 60000
	Endfunc
&& ======================================================================== &&
&& Function Encode
&& ======================================================================== &&
	Function Encode As Memo
		Lparameters toRefObj As Object
		Return This.AnyToJson(toRefObj)
	Endfunc
&& ======================================================================== &&
&& Function AnyToJson
&& ======================================================================== &&
	Function AnyToJson As Memo
		Lparameters tValue As Variant
		Do Case
		Case Type("Alen(tValue, 1)") = "N"
			Local k, lcArray
			lcArray = "["
			For k = 1 to Alen(tValue)
				lcArray = lcArray + Iif(Len(lcArray) > 1, ",", "")
				Try
					Local array aLista(Alen(tValue[k], 1))
					=Acopy(tValue[k], aLista)
					lcArray = lcArray + This.AnyToJson(@aLista)
				Catch
					lcArray = lcArray + This.AnyToJson(tValue[k])
				EndTry
			EndFor
			lcArray = lcArray + "]"
			Return lcArray
		Case Vartype(tValue) = "O"
			Local j, lcJSONStr, lnTot
			Local array gaMembers(1)
			
			lcJSONStr = "{"
			lnTot = Amembers(gaMembers, tValue, 0, "U")
			For j=1 to lnTot
				lcProp = Lower(Alltrim(gaMembers[j]))
				lcJSONStr = lcJSONStr + Iif(Len(lcJSONStr) > 1, ",", "") + '"' + lcProp + '":'
				Try
					Local array aCopia(Alen(tValue. &gaMembers[j], 1))
					=Acopy(tValue. &gaMembers[j], aCopia)
					lcJSONStr = lcJSONStr + This.AnyToJson(@aCopia)
				Catch
					lcJSONStr = lcJSONStr + This.AnyToJson(tValue. &gaMembers[j])
				EndTry
			Endfor
			lcJSONStr = lcJSONStr + "}"
			Return lcJSONStr
		Otherwise
			Return This.Utils.GetValue(tValue, Vartype(tValue))
		EndCase
	Endfunc
&& ======================================================================== &&
&& Function Destroy
&& ======================================================================== &&
	Function Destroy
		If This.lCentury
			Set Century Off
		Endif
		lcDateAct = This.cDateAct
		Set Date &lcDateAct
		Try
			This.utils = .Null.
		Catch
		Endtry
		Try
			Clear Class JsonUtils
		Catch
		Endtry
		Try
			Release Procedure JsonUtils
		Catch
		Endtry
	Endfunc
Enddefine