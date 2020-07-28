&& ******************************************************************************************* &&
&&  PROGRAM:        EnumType.prg
&&  AUTHOR:         Irwin Rodriguez
&&  DATE:           14 July 2020, 16:30:45
&&  SUMMARY:        Built-in function that emulates the enum data type.
&&  PERFORMANCE: 	Big-O(n²)
&& ******************************************************************************************* &&
Function Enum(tcEnumList As String) As Object
	Local loEnum As Object
	loEnum = .Null.
	If !Empty(tcEnumList)
		loEnum = Createobject("Empty")
		tcEnumList = Strtran(Strtran(tcEnumList, Chr(13)), Chr(10))
		lnValue = 1
		For i = 1 To Getwordcount(tcEnumList, ",")
			lcLine = Getwordnum(tcEnumList, i, ",")
			If "=" $ lcLine
				lnValue = Val(Alltrim(GetWordNum(lcLine, 2, "=")))
				lcLine = Alltrim(GetWordNum(lcLine, 1, "="))
			EndIf
			=AddProperty(loEnum, lcLine, Int(lnValue))
			lnValue = lnValue + 1
		Endfor
	EndIf
	Return loEnum
EndFunc