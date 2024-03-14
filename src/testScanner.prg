clear
cd f:\desarrollo\github\jsonfox\src\
delete file "F:\Desarrollo\GitHub\JSONFox\trace.log"
Do loader

lbUserJScriptTokenizer = .F.
lcClass = "JScriptScanner"
set procedure to "JScriptScanner" additive

local lnStart
lnStart = seconds()
local loScanner
*lcFile 		= "F:\Desarrollo\GitHub\JSONFox\test.json"
lcFile 		= "c:\a1\registro-gastos\node_modules\.cache\babel-loader\38c18daa8cb0956e273a42f3cabeb7a3ca3c829d7c9614a3fabaecc14d68db02.json"
loScanner 	= createobject(lcClass, strconv(filetostr(lcFile),11))
loResult 	= loScanner.ScanTokens()
? seconds() - lnStart
return

for each loToken in loResult
	lcOutput = loScanner.TokenStr(loToken)
	loScanner.log(lcOutput)
endfor