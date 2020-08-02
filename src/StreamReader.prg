&& ======================================================================== &&
&& Class StreamReader
&& ======================================================================== &&
Define Class StreamReader As Custom
	#Define FETCH_SIGLE_CHAR 	1
	Hidden cString
	Hidden lInternalCall
	Hidden nCurrentPos
	Hidden nStringLen
	EndOfStream = .F.

&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
	Function Init
		Lparameters tcString As Memo
		This.cString 		= Evl(tcString, "")
		This.nCurrentPos 	= 0
		This.SetStringLen()
	Endfunc
&& ======================================================================== &&
&& Function Read As Character
&& ======================================================================== &&
	Function Read As Character
		Local lcResult As Character
		lcResult = ""
		If !Empty(This.cString)
			If This.nCurrentPos < This.nStringLen
				This.nCurrentPos = This.nCurrentPos + 1
			Else
				This.lInternalCall  = .T.
				This.EndOfStream 	= .T.
			Endif
			If !This.EndOfStream
				lcResult = Substr(This.cString, This.nCurrentPos, FETCH_SIGLE_CHAR)
			Endif
			This.lInternalCall  = .T.
			This.EndOfStream = (This.nCurrentPos = This.nStringLen)
		Else
			Error "Empty String"
		Endif
		Return lcResult
	Endfunc
&& ======================================================================== &&
&& Function LookBehind
&& ======================================================================== &&
	Function LookBehind As Character
		Lparameters tnPosition As Integer
		Local lcChar As Character
		lcChar = Chr(255)
		If (This.nCurrentPos - tnPosition) > 1
			lcChar = Substr(This.cString, tnPosition, 1)
		Endif
		Return lcChar
	Endfunc
&& ======================================================================== &&
&& Function SetString
&& ======================================================================== &&
	Function SetString As String
		Lparameters tcString As Memo
		With This
			.lInternalCall  = .T.
			.EndOfStream 	= .F.
			.nCurrentPos    = 0
			.cString 		= tcString
			.SetStringLen()
			Return .cString
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function EndOfStream_Assign
&& ======================================================================== &&
	Function EndOfStream_Assign(vNewVal)
		If This.lInternalCall
			This.lInternalCall = .F.
			This.EndOfStream = vNewVal
		Endif
	Endfunc
&& ======================================================================== &&
&& Function SetStringLen
&& ======================================================================== &&
	Function SetStringLen As Void
		This.nStringLen	= Len(This.cString)
	Endfunc
&& ======================================================================== &&
&& Function Peek
&& ======================================================================== &&
	Function Peek As Character
		Return Substr(This.cString, This.nCurrentPos + 1, FETCH_SIGLE_CHAR)
	Endfunc
&& ======================================================================== &&
&& Function GetPosition
&& ======================================================================== &&
	Function GetPosition As Integer
		Return This.nCurrentPos
	Endfunc
&& ======================================================================== &&
&& Function SetPosition
&& ======================================================================== &&
	Function SetPosition As Void
		Lparameters tnNewPos As Integer
		With This
			.nCurrentPos = tnNewPos
			.lInternalCall  = .T.
			.EndOfStream = (.nCurrentPos = .nStringLen)
		Endwith
	Endfunc
Enddefine
