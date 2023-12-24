* CursorToJsonObject Parser
define class CursorToJsonObject as session
	nSessionID = 0
	CurName    = ""
	ParseUTF8 = .f.
	TrimChars = .F.

	* Function CursorToArray
	function CursorToJsonObject as object
		if !empty(this.nSessionID)
			set datasession to this.nSessionID
		EndIf
		Local laArray, loRow, lnRecno
		laArray = createobject("TParserInternalArray")
		
		select (this.CurName)
		lnRecno = Recno()
		Scan
			Scatter memo name loRow
			laArray.Push(loRow)
		EndScan

		Try
			Go lnRecno
		Catch
		EndTry
		return @laArray.getArray()		
	EndFunc
	
	* MasterDetail
	Function MasterDetailToJSON(tcMaster as String, tcDetail as String, tcExpr as String, tcDetailAttribute as String, tnSessionID as Integer) as Object		
		if !empty(tnSessionID)
			set datasession to tnSessionID
		ENDIF

		Local laArray, loRow, lnRecno, lbContinue, laDetail, lcMacro, lcCursor,i
		laArray = createobject("TParserInternalArray")
		** Set Detail cursor		
		this.nSessionID = tnSessionID
		
		select (tcMaster)
		lnRecno = Recno()
		i = 0
		scan
			i = i + 1
			Scatter memo name loRow
			laDetail = .null.
			* Filter detail
			lcCursor = Sys(2015)
			try
				Select * from (tcDetail) where &tcExpr into cursor (lcCursor)
				lbContinue = Used(lcCursor)
			Catch
				lbContinue = .f.
			EndTry
			If !lbContinue
				Loop
			EndIf

			If Reccount(lcCursor) > 0
				this.curName = lcCursor
				laDetail = this.CursorToJsonObject()
				Local array laRows[1]
				Acopy(laDetail, laRows)
				lcMacro = 'AddProperty(loRow, "'+tcDetailAttribute+'[1]", .null.)'
				&lcMacro
				lcMacro = 'Acopy(laRows, loRow.'+tcDetailAttribute+')'
				&lcMacro
			Else
				lcMacro = 'AddProperty(loRow, "'+tcDetailAttribute+'", .null.)'
				&lcMacro
			EndIf
			
			Use in (lcCursor)
			
			laArray.Push(loRow)
		EndScan

		Try
			Go lnRecno in (tcMaster)
		Catch
		EndTry
		IF i>0
			return @laArray.getArray()
		ELSE
			RETURN .null.
		ENDIF
	EndFunc
enddefine