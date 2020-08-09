&& ======================================================================== &&
&& Class FoxQueue
&& ======================================================================== &&
Define Class FoxQueue As Custom
	Hidden aQueueList(1)
	Hidden nQueueCounter
&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
	Function Init
		This.nQueueCounter = 0
	Endfunc
&& ======================================================================== &&
&& Function Enqueue
&& ======================================================================== &&
	Function Enqueue(tvItem As Variant) As Variant
		This.nQueueCounter = This.nQueueCounter + 1
		Dimension This.aQueueList(This.nQueueCounter)
		This.aQueueList[This.nQueueCounter] = tvItem
		Return This.aQueueList[This.nQueueCounter]
	Endfunc
&& ======================================================================== &&
&& Function Dequeue
&& ======================================================================== &&
	Function Dequeue As Variant
		Local lvItem As Variant, lnTotItems As Integer
		lvItem = .Null.
		If This.nQueueCounter > 0
			lvItem = This.aQueueList[1]
			If Alen(This.aQueueList) > 1
				For i = 1 To Alen(This.aQueueList) - 1
					Dimension newCopy(i)
					newCopy[i] = This.aQueueList[i + 1]
				Endfor
				This.nQueueCounter = 0
				For j = 1 To Alen(newCopy)
					This.Enqueue(newCopy[j])
				Endfor
				Release newCopy
			Else
				This.nQueueCounter = 0
				This.aQueueList[1] = .Null.
			EndIf
		Endif
		Return lvItem
	Endfunc
&& ======================================================================== &&
&& Function Extract
&& ======================================================================== &&
	Function Extract As Variant
		Local lvItem As Variant
		lvItem = .Null.
		If This.nQueueCounter > 0
			lvItem = This.aQueueList[Alen(This.aQueueList)]
			This.nQueueCounter = This.nQueueCounter - 1
			If Alen(This.aQueueList) > 1
				Dimension This.aQueueList[This.nQueueCounter]
			Else
				This.aQueueList[1] = .Null.
			EndIf
		EndIf
		Return lvItem
	EndFunc
&& ======================================================================== &&
&& Function Clear
&& ======================================================================== &&
	Function Clear As Void
		This.nQueueCounter = 0
		Dimension This.aQueueList(1)
	Endfunc
&& ======================================================================== &&
&& Function Count
&& ======================================================================== &&
	Function Count As Integer
		Return This.nQueueCounter
	Endfunc
&& ======================================================================== &&
&& Function Peek
&& ======================================================================== &&
	Function Peek As Variant
		Local lvPeek As Variant
		lvPeek = .Null.
		If This.nQueueCounter > 0
			lvPeek = This.aQueueList[1]
		Endif
		Return lvPeek
	Endfunc
Enddefine
