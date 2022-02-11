using System;
using System.Text.RegularExpressions;

namespace JSONFoxHelper
{
    public class Lexer{
        private readonly int NONE = 0;
        private readonly char EOT = (char)4;
        private readonly int LBRACE = 1;
        private readonly int RBRACE = 2;
        private readonly int LBRACKET = 3;
        private readonly int RBRACKET = 4;
        private readonly int COMMA = 5;
        private readonly int COLON = 6;
        private readonly int NULL = 9;
        private readonly int NUMBER = 10;
        private readonly int STRING = 12;
        private readonly int BOOLEAN = 18;
        private readonly char EOF_CHAR = (char)0;
        public string input;
        private char c; // current char under examination.
        private StringReader sr = new StringReader();
        public Lexer() { }
        public void ReadString(string input){
            this.input = input;
            sr.ReadString(input);
            Consume(); // prime lookahead
        }        
        private void WS(){
            do { Consume(); } while (c == ' ' || c == '\t' || c == '\n' || c == '\r');
        }
        private void Consume(){
            c = sr.Read();
        }
        private bool IsDigit(char ch)
        {
            return '0' <= ch && ch <= '9';
        }
        private bool IsLetter(char ch)
        {
            return 'a' <= ch && ch <= 'z' || 'A' <= ch && ch <= 'Z' || ch == '_';
        }
        private Token GetString(){
            string lexeme = "";
            Consume(); // consume the first '"'
            while(c != EOF_CHAR) {
                if (c == '\\'){
                    Consume(); // advance '\'
                    switch (c){
                        case '\\':
                            Consume();
                            lexeme += "\\"; break;
                        case 'n':
                            Consume();
                            lexeme += "\n"; break;
                        case 'r':
                            Consume();
                            lexeme += "\r"; break;
                        case 't':
                            Consume();
                            lexeme += "\t"; break;
                        case 'u':
                            Consume();
                            lexeme += GetUnicode(); break;
                        case '/':
                            Consume();
                            lexeme += "/"; break;
                        default:
                            var msg = String.Format("error: bad scape secuence at [{0}:{1}]", sr.GetLine(), sr.GetColumn());
                            throw new Exception(msg);
                    }
                } else{
                    if (c == '"'){ // the last '"'
                        Consume(); break;
                    } else{
                        lexeme += c;
                    }
                }                
                Consume();
            };            
            return new Token(STRING, lexeme);
        }
        private string GetUnicode()
        {
            string lexeme = @"\u";
            while (c != EOF_CHAR && IsDigit(c)){
                lexeme += c;
                Consume();
            }
            return Decode(lexeme);
        }
        private string Decode(string input)
        {
            string html = System.Text.RegularExpressions.Regex.Replace(input, @"\\u[0-9A-F]{4}", match => ((char)int.Parse(match.Value.Substring(2), System.Globalization.NumberStyles.HexNumber)).ToString(), RegexOptions.IgnoreCase);
            return System.Net.WebUtility.HtmlDecode(html);
        }
        private bool IsHex(char ch)
        {
            return 'a' <= ch && ch <= 'f' || 'A' <= ch && ch <= 'F';
        }
        private Token GetNumber()
        {
            string lexeme = "";
            bool signed = c == '-';
            if (signed){
                lexeme += "-";
                Consume();
            }
            do { lexeme += c; Consume(); } while (c != EOF_CHAR && IsDigit(c));
            // check for decimal part.
            if (c == '.'){
                lexeme += ".";
                Consume();
                do { lexeme += c; Consume(); } while (c != EOF_CHAR && IsDigit(c));
            }
            return new Token(NUMBER, lexeme);
        }
        private Token GetIdentifier()
        {
            string lexeme = "";
            do { lexeme += c; Consume(); } while (IsLetter(c));
            int type = BOOLEAN;
            if (lexeme == "true" || lexeme == "false" || lexeme == "null"){
                if (lexeme == "null") type = NULL;
            } else{
                var msg = String.Format("error: unknown identifier at [{0}:{1}]", sr.GetLine(), sr.GetColumn());
                throw new Exception(msg);
            }
            return new Token(type, lexeme);
        }
        public Object NextToken()
        {
            while (c != EOF_CHAR){                
                switch (c){
                    case ' ': case '\t': case '\n': case '\r': WS(); continue;
                    case '{': Consume(); return new Token(LBRACE, '{');
                    case '}': Consume(); return new Token(RBRACE, '}');
                    case '[': Consume(); return new Token(LBRACKET, '[');
                    case ']': Consume(); return new Token(RBRACKET, ']');
                    case ':': Consume(); return new Token(COLON, ':');
                    case ',': Consume(); return new Token(COMMA, ',');
                    case '"': return GetString();
                    default:
                        if (c == '-' && IsDigit(sr.Peek()) || IsDigit(c)){
                            return GetNumber();
                        }
                        if (IsLetter(c)) return GetIdentifier();
                        var msg = String.Format("error: unknown character at [{0}:{1}]", sr.GetLine(), sr.GetColumn());
                        throw new Exception(msg);                        
                }
            }
            return new Token(NONE, EOT);
        } 
    }
    public class Token
    {
        public int type;
        public string value;
        public Token() { }
        public Token(int type, char literal)
        {
            this.type = type;
            this.value = literal.ToString();
        }
        public Token(int type, string literal)
        {
            this.type = type;
            this.value = literal;
        }
        public override string ToString()
        {
            return String.Format("<'{0}',{1}>", value, type);
        }
    }
}
