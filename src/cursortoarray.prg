* CursorToArray Parser
define class CursorToArray as session
	nSessionID = 0
	CurName    = ""
	ParseUTF8 = .f.
	TrimChars = .F.
	oUtils    = .null.
	
	* Function CursorToArray
	function CursorToArray as memo
		if !empty(this.nSessionID)
			set datasession to this.nSessionID
		endif
		private JSONUtils
		JSONUtils = iif(vartype(this.oUtils) == 'O', this.oUtils, _screen.JSONUtils)
		local lcOutput as memo, ;
			i as Integer, ;
			lcValue as Variant, ;
			llCentury as Boolean, ;
			llDeleted as Boolean, ;
			lcDateAct as string, ;
			nCounter as Integer, ;
			lnTotField as Integer, ;
			lnTotal as Integer, ;
			lnRecNo as Integer

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
			* Dentro del SCAN un campo pisa a una variable del mismo nombre:
			* con un campo llamado i, aColumns[i, 1] leía el campo y fallaba
			* con 'Subscript is outside defined range'. Por eso m.
			scan
				nCounter   = m.nCounter + 1
				lcOutput   = m.lcOutput + "{"
				for i = 1 to m.lnTotField
					if m.i > 1
						lcOutput = m.lcOutput + ','
					endif
					lcOutput = m.lcOutput + '"' + lower(m.aColumns[m.i, 1]) + '"'
					lcOutput = m.lcOutput + ':'
					lcValue  = evaluate(.CurName + "." + m.aColumns[m.i, 1])
					if vartype(m.lcValue) = 'X'
						lcValue = "null"
						lcOutput = m.lcOutput + m.lcValue
					else
						do case
						case m.aColumns[m.i, 2] $ "CDTGMQVW"
							do case
							case m.aColumns[m.i, 2] = 'D'
								if !empty(m.lcValue)
									lcValue = '"' + left(ttoc(m.lcValue,3),10) + '"'
								else
									lcValue = 'null'
								endif
							case m.aColumns[m.i, 2] = 'T'
								if !empty(m.lcValue)
									lcValue = '"' + ttoc(m.lcValue,3) + '"'
								else
									lcValue = 'null'
								endif
							Otherwise
								lcValue = m.JSONUtils.GetString(Iif(this.TrimChars, Alltrim(m.lcValue), m.lcValue), this.ParseUTF8)
							endcase
							lcOutput = m.lcOutput + Iif(this.TrimChars, Alltrim(m.lcValue), m.lcValue)
						case m.aColumns[m.i, 2] = "B"
							* Un Double guarda más decimales de los que enseña.
							lcOutput = m.lcOutput + m.JSONUtils.NumberToJson(m.lcValue)
						case m.aColumns[m.i, 2] $ "YFIN"
							lcOutput = m.lcOutput + m.JSONUtils.NumberToJson(m.lcValue, m.aColumns[m.i, 4])
						case m.aColumns[m.i, 2] = "L"
							lcOutput = m.lcOutput + iif(m.lcValue, "true", "false")
						endcase
					endif
				endfor
				lcOutput = m.lcOutput + '}' + iif(m.nCounter < m.lnTotal, ',', '')
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
