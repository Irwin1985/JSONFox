* CursorToArray Parser
Define Class CursorToArray As Session
	nSessionID = 0
	curName    = ""
	* Function CursorToArray
	Function CursorToArray As Memo
		If !Empty(This.nSessionID)
			Set DataSession To This.nSessionID
		Endif
		Private JSONUtils
		JSONUtils = _Screen.JSONUtils
		Local lcOutput As Memo
		lcOutput = "["
		llCentury = Set("Century") == "OFF"
		llDeleted = Set("Deleted") == "OFF"
		lcDateAct = Set("Date")
		Set Century On
		Set Deleted On
		Set Date Ansi
		With This
			nCounter = 0
			Select (.curName)
			lnTotField  = Afields(aColumns, .curName)
			lnTotal  	= Reccount(.curName)
			lnRecNo 	= Recn(.curName)
			Count For !Deleted() To lnTotal
			Go lnRecNo
			Scan
				nCounter   = nCounter + 1
				lcOutput   = lcOutput + "{"
				For i = 1 To lnTotField
					If i > 1
						lcOutput = lcOutput + ','
					Endif
					lcOutput = lcOutput + '"' + Lower(aColumns[i, 1]) + '"'
					lcOutput = lcOutput + ':'
					lcValue  = Evaluate(.curName + "." + aColumns[i, 1])
					Do Case
					Case aColumns[i, 2] $ "CDTBGMQVW"
						Do Case
						Case aColumns[i, 2] = "D"
							lcValue = '"' + Strtran(Dtoc(lcValue), ".", "-") + '"'
						Case aColumns[i, 2] = "T"
							lcValue = '"' + Strtran(Ttoc(lcValue), ".", "-") + '"'
						Otherwise
							If Vartype(lcValue) = "X"
								lcValue = "null"
							Else
								lcValue = JSONUtils.GetString(Alltrim(lcValue))
							Endif
						Endcase
						lcOutput = lcOutput + Alltrim(lcValue)
					Case aColumns[i, 2] $ "YFIN"
						lcOutput = lcOutput + Transform(lcValue)
					Case aColumns[i, 2] = "L"
						lcOutput = lcOutput + Iif(lcValue, "true", "false")
					Endcase
				Endfor
				lcOutput = lcOutput + '}' + Iif(nCounter < lnTotal, ',', '')
				Select (.curName)
			Endscan
		Endwith
		lcOutput = lcOutput + "]"
		If llCentury
			Set Century Off
		Endif
		If llDeleted
			Set Deleted Off
		Endif
		Set Date &lcDateAct
		Return lcOutput
	Endfunc
Enddefine
