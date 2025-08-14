#include "JSONFox.h"
Define Class NETScanner As Custom
  Hidden capacity
  Hidden Length
  Hidden Scanner
  Dimension tokens[1]

  Function Init(strInput)
      With This
          .Scanner = Createobject("JSONFoxHelper.Lexer")
          .Scanner.ReadString(strInput)
          .Length   = 1
          .capacity = 0
      Endwith
  Endfunc

  Function scanTokens
      With This
          * Limpiar array inicial
          Dimension .tokens[1]
          .Length = 1
          .capacity = 0
          
          * Procesar tokens uno por uno
          Local loToken
          loToken = .Scanner.NextToken()
          
          Do While loToken.Type != 0 && T_NONE
              .addToken(loToken.Type, loToken.Value, loToken.Line)
              loToken = .Scanner.NextToken()
          Enddo
          
          * Agregar token EOF
          .addToken(T_EOF, "", 1)
          .capacity = .Length - 1

          * Ajustar tamaño del array
          Dimension .tokens[.capacity]

          * Crear objeto de retorno igual al nativo
          Local loTokens
          loTokens = Createobject("Empty")
          AddProperty(loTokens, "tokens[" + Alltrim(Str(.capacity)) + "]", Null)

          * Copiar tokens al objeto de retorno
          Local i
          For i = 1 To .capacity
              If Type('.tokens[i]') = 'O'
                  loTokens.tokens[i] = Createobject("Empty")
                  AddProperty(loTokens.tokens[i], "type", .tokens[i].type)
                  AddProperty(loTokens.tokens[i], "value", .tokens[i].value)
                  AddProperty(loTokens.tokens[i], "line", .tokens[i].line)
              Else
                  loTokens.tokens[i] = .tokens[i]
              Endif
          Next

          * Limpiar y devolver
          .CleanUp()
          Return loTokens
      Endwith
  Endfunc

  Hidden Function addToken(tnTokenType, tcTokenValue, tnLine)
      With This
          .checkCapacity()
          Local loToken
          loToken = Createobject("Empty")
          AddProperty(loToken, "type",  tnTokenType)
          AddProperty(loToken, "value", tcTokenValue)
          AddProperty(loToken, "line",  tnLine)

          .tokens[.length] = loToken
          .Length = .Length + 1
      Endwith
  Endfunc

  Hidden Function checkCapacity
      With This
          If .capacity < .Length + 1
              If Empty(.capacity)
                  .capacity = 8
              Else
                  .capacity = .capacity * 2
              Endif
              Dimension .tokens[.capacity]
          Endif
      Endwith
  Endfunc

  Function CleanUp
      With This
          * Limpiar scanner .NET
          If Type('this.Scanner') = 'O' And !Isnull(this.Scanner)
              this.Scanner.CleanUp()
              this.Scanner = .Null.
          Endif
          
          * Limpiar tokens
          Local i
          If Type('this.tokens', 1) == 'A'
              For i = 1 To Alen(this.tokens)
                  this.tokens[i] = .Null.
              Next
          Endif
          
          * Resetear array y propiedades
          Dimension this.tokens[1]
          this.tokens[1] = .Null.
          this.Length = 1
          this.capacity = 0
      Endwith
  Endfunc

  Function Destroy
      This.CleanUp()
      DoDefault()
  Endfunc
Enddefine