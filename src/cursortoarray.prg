&& ======================================================================== &&
&& CursorToArray Parser
&& ======================================================================== &&
Define Class CursorToArray As Session
	nSessionID = 0
	curName = ""
	Hidden utils
&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
	Function Init
		Set Procedure To "JsonUtils" Additive
		this.utils = Createobject("JsonUtils")
	Endfunc
&& ======================================================================== &&
&& Function CursorToArray
&& ======================================================================== &&
	Function CursorToArray As Memo
		If !Empty(This.nSessionID)
			Set DataSession To This.nSessionID
		Endif
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
			lnTotal  = Reccount(.curName)
			Select (.curName)
			Scan
				nCounter   = nCounter + 1
				lcOutput   = lcOutput + "{"
				lnTotField = Afields(aColumns, .curName)
				For i = 1 To lnTotField
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
								lcValue = This.utils.GetString(Alltrim(lcValue))
							Endif
						Endcase
						lcOutput = lcOutput + Alltrim(lcValue)
					Case aColumns[i, 2] $ "YFIN"
						lcOutput = lcOutput + Transform(lcValue)
					Case aColumns[i, 2] = "L"
						lcOutput = lcOutput + Iif(lcValue, "true", "false")
					Endcase
					If lnTotField > 1 And Between(i, 1, lnTotField - 1)
						lcOutput = lcOutput + ','
					Endif
				Endfor
				lcOutput = lcOutput + "}"
				If lnTotal > 1 And Between(nCounter, 1, lnTotal - 1)
					lcOutput = lcOutput + ","
				Endif
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
	EndFunc
&& ======================================================================== &&
&& Function Destroy
&& ======================================================================== &&
	Function Destroy
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