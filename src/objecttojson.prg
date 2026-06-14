* ObjectToJSON
define class ObjectToJSON as session
	#define USER_DEFINED_PEMS	'U'
	#define ALL_MEMBERS			"PHGNUCIBR"
	lCentury = .f.
	cDateAct = ''
	nOrden   = 0
	cFlags 	 = ''
	parseUTF8 = .f.
	TrimChars = .f.
	oUtils = .null.

	* Function Init
	function init
		this.lCentury = set("Century") == "OFF"
		this.cDateAct = set("Date")
		set century on
		set date ansi
		mvcount = 60000
	endfunc

	* Encode
	function Encode(toRefObj, tcFlags, tlParseUTF8, tlTrimChars)
		private JSONUtils
		JSONUtils = iif(vartype(this.oUtils) == 'O', this.oUtils, _screen.jsonUtils)
		lPassByRef = .t.
		try
			external array toRefObj
		catch
			lPassByRef = .f.
		endtry
		this.cFlags = evl(tcFlags, USER_DEFINED_PEMS)
		this.parseUTF8 = tlParseUTF8
		this.TrimChars = tlTrimChars
		if lPassByRef
			return this.AnyToJson(@toRefObj)
		else
			return this.AnyToJson(toRefObj)
		endif
	endfunc

	function EncodeFromSchema(toRefObj, tcSchema, tlParseUTF8, tlTrimChars)

	endfunc

	* AnyToJson
	function AnyToJson as memo
		lparameters tValue as Variant
		try
			external array tValue
		catch
		endtry
		do case
		case type("tValue", 1) = 'A'
			local k, j, lcArray
			if alen(tValue, 2) == 0
				*# Unidimensional array
				lcArray = '['
				for k = 1 to alen(tValue)
					lcArray = lcArray + iif(len(lcArray) > 1, ',', '')
					try
						local array laLista[1]
						=acopy(tValue[k], laLista)
						lcArray = lcArray + this.AnyToJson(@laLista)
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
							local array laLista[1]
							=acopy(tValue[k, j], laLista)
							lcArray = lcArray + this.AnyToJson(@laLista)
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
			* Check if it is a collection first to handle it specially
			local llIsCollection
			llIsCollection = .f.
			try
				llIsCollection = (tValue.BaseClass == "Collection" and tValue.Class == "Collection" and tValue.Name == "Collection")
			catch
			endtry

			if llIsCollection
				* Check if collection has keys (key-value) or only values
				local lnCount, i, lcResult, llHasKeys, lcKey
				lnCount = tValue.Count
				llHasKeys = .f.

				* Try to get the first element key to determine if key-value
				if lnCount > 0
					try
						lcKey = tValue.GetKey(1)
						if !empty(lcKey)
							llHasKeys = .t.
						endif
					catch
					endtry
				endif

				if llHasKeys
					* Collection with key-value pairs, treat as object
					lcResult = '{'
					for i = 1 to lnCount
						lcKey = tValue.GetKey(i)
						lcResult = lcResult + iif(i > 1, ',', '') + '"' + lcKey + '":' + this.AnyToJson(tValue.Item(i))
					endfor
					lcResult = lcResult + '}'
				else
					* Collection with values only, treat as array
					lcResult = '['
					for i = 1 to lnCount
						lcResult = lcResult + iif(i > 1, ',', '') + this.AnyToJson(tValue.Item(i))
					endfor
					lcResult = lcResult + ']'
				endif

				return lcResult
			else
				* Not a collection, process as normal object
				local j, lcJSONStr, lnTot, i, lcProp, lcOriginalName
				local array gaMembers(1)

				lcJSONStr = '{'
				lnTot = amembers(gaMembers, tValue, 0, this.cFlags)

				local array laPropsToProcess[1]
				local lnPropCount, lnIdx
				lnPropCount = 0

				* Step 1: identify and classify properties
				for j=1 to lnTot
					lcProp = lower(alltrim(gaMembers[j]))
					* Skip special array properties
					if left(lower(lcProp), 14) == "_specialarray_"
						loop
					endif

					lnPropCount = lnPropCount + 1
					dimension laPropsToProcess[lnPropCount,2]
					laPropsToProcess[lnPropCount, 1] = lcProp
					if right(lcProp, 6) == "_array" and type("tValue._specialArray_" + lcProp) == "C"
						laPropsToProcess[lnPropCount, 2] = "special_array"
					else
						laPropsToProcess[lnPropCount, 2] = "normal"
					endif
				next

				* Step 2: process filtered properties
				for lnIdx=1 to lnPropCount
					lcProp = laPropsToProcess[lnIdx, 1]

					if laPropsToProcess[lnIdx, 2] == "special_array"
						lcOriginalName = evaluate("tValue._specialArray_" + lcProp)
						lcJSONStr = lcJSONStr + iif(len(lcJSONStr) > 1, ',', '') + '"' + lcOriginalName + '":'
						try
							local array laLista[1]
							=acopy(tValue. &lcProp, laLista)
							lcJSONStr = lcJSONStr + this.AnyToJson(@laLista)
						catch
							lcJSONStr = lcJSONStr + "[]"
						endtry
					else
						* Normal property
						lcJSONStr = lcJSONStr + iif(len(lcJSONStr) > 1, ',', '') + '"' + lcProp + '":'
						try
							local array laLista[1]
							=acopy(tValue. &lcProp, laLista)
							lcJSONStr = lcJSONStr + this.AnyToJson(@laLista)
						catch
							try
								lcJSONStr = lcJSONStr + this.AnyToJson(tValue. &lcProp)
							catch
								lcJSONStr = lcJSONStr + "{}"
							endtry
						endtry
					endif
				endfor

				lcJSONStr = lcJSONStr + '}'
				return lcJSONStr
			endif
		otherwise
			return JSONUtils.GetValue(tValue, vartype(tValue), this.parseUTF8, this.TrimChars)
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
