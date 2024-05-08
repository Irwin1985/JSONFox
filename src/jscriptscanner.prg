#include "JSONFox.h"
* JScriptScanner
define class JScriptScanner as custom
	Hidden source
	hidden line
	
	Hidden capacity
	Hidden length
	
	Dimension tokens[1]	
	oScript = .null.

	function init(tcSource)
		With this
			.length = 1
			.capacity = 0
			&& IRODG 11/08/2023 Inicio
			* We remove possible invalid characters from the input source.
			tcSource = STRTRAN(tcSource, CHR(0))
			tcSource = STRTRAN(tcSource, CHR(10))
			tcSource = STRTRAN(tcSource, CHR(13))
			&& IRODG 11/08/2023 Fin
			.source = tcSource
			.line = 1
		endwith
	endfunc

	function escapeCharacters(tcLexeme)
		* Convert all escape sequences
		tcLexeme = Strtran(tcLexeme, '\\', '\')
		tcLexeme = Strtran(tcLexeme, '\/', '/')
		tcLexeme = Strtran(tcLexeme, '\n', Chr(10))
		tcLexeme = Strtran(tcLexeme, '\r', Chr(13))
		tcLexeme = Strtran(tcLexeme, '\t', Chr(9))
		tcLexeme = Strtran(tcLexeme, '\"', '"')
		tcLexeme = Strtran(tcLexeme, "\'", "'")
		return tcLexeme
	endfunc
	
	procedure increaseNewLine
		this.line = this.line + 1
	endproc
		
	function checkUnicodeFormat(tcLexeme)
		* Look for unicode format
		** This conversion is better (in performance) than Regular Expressions.
		&& IRODG 09/10/2023 Inicio
		local lcUnicode, lcConversion, lbReplace, lnPos
		lnPos = 1
		do while .T.
			lbReplace = .F.
			lcUnicode = substr(tcLexeme, at('\u', tcLexeme, lnPos), 6)
			if len(lcUnicode) == 6
				lbReplace = .T.
			else
				lcUnicode = substr(tcLexeme, at('\U', tcLexeme, lnPos), 6)
				if len(lcUnicode) == 6
					lbReplace = .T.
				endif
			endif
			if lbReplace
				tcLexeme = strtran(tcLexeme, lcUnicode, strtran(strconv(lcUnicode,16), chr(0)))
			else
				exit
			endif
		enddo
		&& IRODG 09/10/2023 Fin
		return tcLexeme
	endfunc

	Function scanTokens
		With this
			Dimension .tokens[1]
			
			this.oScript = Createobject([MSScriptcontrol.scriptcontrol.1])			
			this.oScript.Language = "JScript"
			*this.oScript.AddCode(strconv(filetostr('F:\Desarrollo\GitHub\JSONFox\scanner.js'),11))
			local lcScript
			lcScript = this.loadScript()
		
		*	_cliptext = lcScript
		*	messagebox(lcScript)
		
			this.oScript.AddCode(lcScript)
			this.oScript.AddObject("oScanner", this)
			this.oScript.Run("ScanTokens", this.source)			
			.capacity = .length-1			
			* Shrink array
			Dimension .tokens[.capacity]
		endwith
		Return @this.tokens
	endfunc

	function log(tcContent)
		? tcContent
		strtofile(tcContent + CRLF, 'f:\desarrollo\github\jsonfox\trace.log', 1)
	endfunc	

	function addToken(tnTokenType, tcTokenValue)
		With this
			.checkCapacity()
			local loToken
			loToken = createobject("Empty")
			=addproperty(loToken, "type", tnTokenType)
			=addproperty(loToken, "value", tcTokenValue)
			=AddProperty(loToken, "line", .line)
			
			.tokens[.length] = loToken
			.length = .length + 1
		EndWith
	EndFunc
	
	Hidden function checkCapacity
		With this
			If .capacity < .length + 1
				If Empty(.capacity)
					.capacity = 8
				Else
					.capacity = .capacity * 2
				EndIf			
				Dimension .tokens[.capacity]
			EndIf
		endwith
	endfunc

	procedure showError(tcCharacter, tnCurrent)
		local lcMessage
		lcMessage = "Unknown character ['" + transform(tcCharacter) + "'], ascii: [" + TRANSFORM(ASC(tcCharacter)) + "]"
		error "SYNTAX ERROR: (" + TRANSFORM(this.line) + ":" + TRANSFORM(tnCurrent) + ")" + lcMessage
	endproc

	function tokenStr(toToken)
		local lcType, lcValue
		lcType = _screen.jsonUtils.tokenTypeToStr(toToken.type)
		lcValue = alltrim(transform(toToken.value))		
		return "Token(" + lcType + ", '" + lcValue + "') at Line(" + Alltrim(Str(toToken.Line)) + ")"
	endfunc

	function loadScript
		local lcScript
		text to lcScript noshow
var C_LBRACE 	= 1
var C_RBRACE 	= 2
var C_LBRACKET 	= 3
var C_RBRACKET 	= 4
var C_COMMA 	= 5
var C_COLON 	= 6
var C_NULL 		= 9
var C_NUMBER 	= 10
var C_STRING 	= 12
var C_EOF 		= 17
var C_BOOLEAN 	= 18
var C_NEWLINE   = 19

var Spec = [
    // --------------------------------------
    // Whitespace:
    [/^[ \t\r\f]/, null],

    // --------------------------------------
    // New line:
    [/^\n/, C_NEWLINE],

    // --------------------------------------
    // Keywords
    [/^\btrue\b/, C_BOOLEAN],
    [/^\bfalse\b/, C_BOOLEAN],
    [/^\bnull\b/, C_NULL],

    // --------------------------------------
    // Symbols
    [/^\{/, C_LBRACE],
    [/^\}/, C_RBRACE],
    [/^\[/, C_LBRACKET],
    [/^\]/, C_RBRACKET],
    [/^\:/, C_COLON],
    [/^\,/, C_COMMA],    

    // --------------------------------------
    // Numbers:
    [/^-?\d+(,\d{3})*(\.\d+)?([eE][-+]?\d+)?/, C_NUMBER],

    // --------------------------------------
    // Double quoted string:
    [/^"/, C_STRING]
];

var _scannerString;
var _scannerCursor;

function ScanTokens(source) {
    _scannerString = source;
    _scannerCursor = 0; // track the position of each character

    while (_scannerCursor < _scannerString.length) {
        var token = _getNextToken();
        if (token == null) {
            break;
        }
        oScanner.AddToken(token.type, token.value);
    }
    oScanner.AddToken(C_EOF, '');
}

function _getNextToken() {
    if (_scannerCursor >= _scannerString.length) {
        return null;
    }
    var string = _scannerString.slice(_scannerCursor);

    for (var i = 0; i < Spec.length; i++) {
        var regexp = Spec[i][0];
        var tokenType = Spec[i][1];        
        var tokenValue = _matchRegEx(regexp, string);

        if (tokenValue == null) {
            continue;
        }

        if (tokenType == null) {
            return _getNextToken();
        }

        if (tokenType === C_NEWLINE) {
            oScanner.increaseNewLine();
            return _getNextToken();
        }        
        var literal = tokenValue;
        if (tokenType === C_STRING) {
            literal = _parseString();
        }

        return {
            type: tokenType,
            value: literal
        };
    }

    oScanner.showError(string[0], _scannerCursor);
}

function _matchRegEx(regexp, string) {
    var matched = regexp.exec(string);
    if (matched == null) {
        return null;
    }
    _scannerCursor += matched[0].length;
    return matched[0];
}

function _parseString() {
    var ch = '';
    var looping = true;
    var start = _scannerCursor-1;
    var pn = '';
    while (_scannerCursor < _scannerString.length) {
        ch = _scannerString.charAt(_scannerCursor);
        switch (ch) {
            case '\\':
                pn = (_scannerCursor+1 <= _scannerString.length) ? _scannerString.charAt(_scannerCursor+1) : '';
                if (pn === '\\' || pn === '/' || pn === 'n' || pn === 'r' || pn === 't' || pn === '"' || pn === "'") {
                    _scannerCursor++;
                }
                break;
            case '"': 
                looping = false;
                break;
            default:
                break;
        }
        _scannerCursor++;
        if (!looping) {
            break;
        }
    }
    var lexeme = _scannerString.slice(start+1, _scannerCursor-1);
    lexeme = oScanner.escapeCharacters(lexeme);
    lexeme = oScanner.checkUnicodeFormat(lexeme);
    return lexeme;
}
		endtext
		return lcScript
	endfunc
enddefine