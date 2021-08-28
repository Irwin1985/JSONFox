* ObjectToJSON
define class ObjectToJSON as session
	#define USER_DEFINED_PEMS	'U'
	#define ALL_MEMBERS			"PHGNUCIBR"
	lCentury = .f.
	cDateAct = ''
	nOrden   = 0
	cFlags 	 = ''
	* Function Init
	function init
		this.lCentury = set("Century") == "OFF"
		this.cDateAct = set("Date")
		set century on
		set date ansi
		mvcount = 60000
	endfunc
	* Encode
	function Encode(toRefObj, tcFlags)
		lPassByRef = .t.
		try
			external array toRefObj
		catch
			lPassByRef = .f.
		endtry
		this.cFlags = evl(tcFlags, ALL_MEMBERS)
		if lPassByRef
			return this.AnyToJson(@toRefObj)
		else
			return this.AnyToJson(toRefObj)
		endif
	endfunc
	* AnyToJson
	function AnyToJson as memo
		lparameters tValue as Variant
		try
			external array tValue
		catch
		endtry
		do case
		*case type("Alen(tValue, 1)") = "N"
		case type("tValue", 1) = 'A'
			local k, j, lcArray
			if alen(tValue, 2) == 0
				*# Unidimensional array
				lcArray = '['
				for k = 1 to alen(tValue)
					lcArray = lcArray + iif(len(lcArray) > 1, ',', '')
					try
						*local array aLista(alen(tValue[k]))
						=acopy(tValue[k], aLista)
						lcArray = lcArray + this.AnyToJson(@aLista)
					catch
						lcArray = lcArray + this.AnyToJson(tValue[k])
					endtry
				endfor
				lcArray = lcArray + ']'
			else
				*# Multidimensional array support
				lcArray = '['
				for k = 1 to alen(tValue, 1)
					lcArray = lcArray + iif(len(lcArray) > 1, ',', '')

					* # begin of rows
					lcArray = lcArray + '['
					for j = 1 to alen(tValue, 2)
						if j > 1
							lcArray = lcArray + ','
						endif
						try
							=acopy(tValue[k, j], aLista)
							lcArray = lcArray + this.AnyToJson(@aLista)
						catch
							lcArray = lcArray + this.AnyToJson(tValue[k, j])
						endtry
					endfor
					lcArray = lcArray + ']'
					* # end of rows
				endfor
				lcArray = lcArray + ']'
			endif
			return lcArray

		case vartype(tValue) = 'O'
			local j, lcJSONStr, lnTot
			local array gaMembers(1)

			lcJSONStr = '{'
			lnTot = amembers(gaMembers, tValue, 0, this.cFlags)
			for j=1 to lnTot
				lcProp = lower(alltrim(gaMembers[j]))
				lcJSONStr = lcJSONStr + iif(len(lcJSONStr) > 1, ',', '') + '"' + lcProp + '":'
				try
					*local array aCopia(alen(tValue. &gaMembers[j]))
					=acopy(tValue. &gaMembers[j], aCopia)
					lcJSONStr = lcJSONStr + this.AnyToJson(@aCopia)
				catch
					try
						lcJSONStr = lcJSONStr + this.AnyToJson(tValue. &gaMembers[j])
					catch
						lcJSONStr = lcJSONStr + "{}"
					endtry
				endtry
			endfor

			*//> Collection based class object support
			llIsCollection = .f.
			try				
				llIsCollection = (tValue.BaseClass == "Collection" and tValue.Class == "Collection" and tValue.Name == "Collection")
			catch
			endtry
			if llIsCollection
				lcComma   = iif(right(lcJSONStr, 1) != '{', ',', '')
				lcJSONStr = lcJSONStr + lcComma + '"Collection":['
				for i=1 to tValue.Count
					lcJSONStr = lcJSONStr + iif(i>1,',','') + this.AnyToJson(tValue.Item(i))
				endfor
				lcJSONStr = lcJSONStr + ']'
			endif
			*//> Collection based class object support

			lcJSONStr = lcJSONStr + '}'
			return lcJSONStr
		otherwise
			return _screen.JSONUtils.GetValue(tValue, vartype(tValue))
		endcase
	endfunc
	* Destroy
	function destroy
		if this.lCentury
			set century off
		endif
		lcDateAct = this.cDateAct
		set date &lcDateAct
	endfunc
enddefine
