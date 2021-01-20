* CursorToArray Parser
define class CursorToArray as session
	nSessionID = 0
	CurName    = ""
	* Function CursorToArray
	function CursorToArray as memo
		if !empty(this.nSessionID)
			set datasession to this.nSessionID
		endif
		private JSONUtils
		JSONUtils = _screen.JSONUtils
		local lcOutput as memo
		lcOutput = "["
		llCentury = set("Century") == "OFF"
		llDeleted = set("Deleted") == "OFF"
		lcDateAct = set("Date")
		set century on
		set deleted on
		set date ansi
		with this
			nCounter = 0
			select (.CurName)
			lnTotField  = afields(aColumns, .CurName)
			lnTotal  	= reccount(.CurName)
			lnRecNo 	= recn(.CurName)
			count for !deleted() to lnTotal
			go lnRecNo
			scan
				nCounter   = nCounter + 1
				lcOutput   = lcOutput + "{"
				for i = 1 to lnTotField
					if i > 1
						lcOutput = lcOutput + ','
					endif
					lcOutput = lcOutput + '"' + lower(aColumns[i, 1]) + '"'
					lcOutput = lcOutput + ':'
					lcValue  = evaluate(.CurName + "." + aColumns[i, 1])
					if vartype(lcValue) = 'X'
						lcValue = "null"
						lcOutput = lcOutput + alltrim(lcValue)
					else
						do case
						case aColumns[i, 2] $ "CDTBGMQVW"
							do case
							case aColumns[i, 2] = 'D'
								if !empty(lcValue)
									lcValue = '"' + strtran(dtoc(lcValue), '.', '-') + '"'
								else
									lcValue = 'null'
								endif
							case aColumns[i, 2] = 'T'
								if !empty(lcValue)
									lcValue = '"' + strtran(ttoc(lcValue), '.', '-') + '"'
								else
									lcValue = 'null'
								endif
							otherwise
								lcValue = JSONUtils.GetString(alltrim(lcValue))
							endcase
							lcOutput = lcOutput + alltrim(lcValue)
						case aColumns[i, 2] $ "YFIN"
							lcOutput = lcOutput + transform(lcValue)
						case aColumns[i, 2] = "L"
							lcOutput = lcOutput + iif(lcValue, "true", "false")
						endcase
					endif
				endfor
				lcOutput = lcOutput + '}' + iif(nCounter < lnTotal, ',', '')
				select (.CurName)
			endscan
		endwith
		lcOutput = lcOutput + "]"
		if llCentury
			set century off
		endif
		if llDeleted
			set deleted off
		endif
		set date &lcDateAct
		return lcOutput
	endfunc
enddefine
