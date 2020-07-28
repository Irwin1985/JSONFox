&& ======================================================================== &&
&& ArrayToArray Parser
&& ======================================================================== &&
Define Class ArrayToArray As Session
&& ======================================================================== &&
&& Function ArrayToArray
&& ======================================================================== &&
	Function ArrayToArray As Memo
		Lparameters taList
		External Array taList
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
			lnTotal  = Alen(taList, 1)
			For i = 1 To lnTotal
				lcValue = taList[i]
				lcType  = Vartype(lcValue)
				Do Case
				Case lcType $ "CDTBGMQVWX"
					Do Case
					Case lcType = "D"
						lcValue = '"' + Strtran(Dtoc(lcValue), ".", "-") + '"'
					Case lcType = "T"
						lcValue = '"' + Strtran(Ttoc(lcValue), ".", "-") + '"'
					Otherwise
						If lcType = "X"
							lcValue = "null"
						Else
							lcValue = '"' + Alltrim(lcValue) + '"'
						Endif
					Endcase
					lcOutput = lcOutput + Alltrim(lcValue)
				Case lcType $ "YFIN"
					lcOutput = lcOutput + Transform(lcValue)
				Case lcType = "L"
					lcOutput = lcOutput + Iif(lcValue, "true", "false")
				Endcase
				If lnTotal > 1 And Between(i, 1, lnTotal - 1)
					lcOutput = lcOutput + ","
				Endif
			Endfor
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