* ObjectToJSON
Define Class ObjectToJSON As Session
	#define USER_DEFINED_PEMS	"U"
	lCentury = .F.
	cDateAct = ""
	nOrden   = 0
	cFlags 	 = ""
	* Function Init
	Function Init
		This.lCentury = Set("Century") == "OFF"
		This.cDateAct = Set("Date")
		Set Century On
		Set Date Ansi
		Mvcount = 60000
	Endfunc
	* Encode
	Function Encode(toRefObj, tcFlags)
		lPassByRef = .T.
		Try
			External array toRefObj
		Catch
			lPassByRef = .F.
		EndTry
		This.cFlags = Evl(tcFlags, USER_DEFINED_PEMS)
		If lPassByRef
			Return This.AnyToJson(@toRefObj)
		Else
			Return This.AnyToJson(toRefObj)
		EndIf
	Endfunc
	* AnyToJson
	Function AnyToJson As Memo
		Lparameters tValue As Variant
		Try
			External array tValue
		Catch
		EndTry
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
			lnTot = Amembers(gaMembers, tValue, 0, This.cFlags)
			For j=1 to lnTot
				lcProp = Lower(Alltrim(gaMembers[j]))
				lcJSONStr = lcJSONStr + Iif(Len(lcJSONStr) > 1, ",", "") + '"' + lcProp + '":'
				Try
					Local array aCopia(Alen(tValue. &gaMembers[j], 1))
					=Acopy(tValue. &gaMembers[j], aCopia)
					lcJSONStr = lcJSONStr + This.AnyToJson(@aCopia)
				Catch
					try
						lcJSONStr = lcJSONStr + This.AnyToJson(tValue. &gaMembers[j])
					catch
						lcJSONStr = lcJSONStr + "{}"
					endtry
				EndTry
			Endfor
			lcJSONStr = lcJSONStr + "}"
			Return lcJSONStr
		Otherwise
			Return _Screen.JSONUtils.GetValue(tValue, Vartype(tValue))
		EndCase
	Endfunc
	* Destroy
	Function Destroy
		If This.lCentury
			Set Century Off
		Endif
		lcDateAct = This.cDateAct
		Set Date &lcDateAct
	Endfunc
Enddefine