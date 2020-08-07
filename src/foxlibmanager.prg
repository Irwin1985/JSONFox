&& ======================================================================== &&
&& Class FoxLibManager
&& ======================================================================== &&
Define Class FoxLibManager As Custom
    Dimension aClassList(1)
    Dimension aProcList(1)
    Hidden nClassCounter
    Hidden nProcCounter
&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
    Function Init
        This.nClassCounter = 0
        This.nProcCounter  = 0
    EndFunc
&& ======================================================================== &&
&& Function AddClass
&& ======================================================================== &&
    Function AddClass(tcClassName As String) As Void
        This.nClassCounter = This.nClassCounter + 1
        Dimension This.aClassList(This.nClassCounter)
        This.aClassList[This.nClassCounter] = tcClassName
    EndFunc
&& ======================================================================== &&
&& Function AddProcedure
&& ======================================================================== &&
    Function AddProcedure(tcProcName As String) As Void
        This.nProcCounter = This.nProcCounter + 1
        Dimension This.aProcList(This.nProcCounter)
        This.aProcList[This.nProcCounter] = tcProcName
    EndFunc
&& ======================================================================== &&
&& Function AddBoth
&& ======================================================================== &&
	Function AddBoth (tcEntity As String) As Void
		this.AddClass(tcEntity)
		This.AddProcedure(tcEntity)
	EndFunc
&& ======================================================================== &&
&& Function LoadProcedures
&& ======================================================================== &&
    Function LoadProcedures As Variant
        For i = 1 to Alen(This.aProcList, 1)
            If Type("This.aProcList[i]") = "C"
                If not upper(This.aProcList[i]) $ Set("Procedure")
                    Set Procedure To (This.aProcList[i]) Additive
                Endif
            Endif
        EndFor
    EndFunc
&& ======================================================================== &&
&& Function ReleaseAll
&& ======================================================================== &&
    Function ReleaseAll As Void
        This.ClearClasses()
        This.ReleaseProcedures()
    EndFunc
&& ======================================================================== &&
&& Hidden Function ReleaseProcedures
&& ======================================================================== &&
    Hidden Function ReleaseProcedures As Void
        For i = 1 to Alen(This.aProcList, 1)
            Try
                Release Procedure (This.aProcList[i])
            Catch
            EndTry
        EndFor
    EndFunc
&& ======================================================================== &&
&& Hidden Function ClearClasses
&& ======================================================================== &&
    Hidden Function ClearClasses As Void
        For i = 1 to Alen(This.aClassList, 1)
            Try
                Clear Class (This.aClassList[i])
            Catch
            EndTry
        EndFor
    EndFunc
EndDefine