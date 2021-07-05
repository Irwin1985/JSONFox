using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace JSONFoxHelper
{
    public class StringReader
    {
        private int line;
        private int column;
        private string input;
        private int curPos = -1;
        public StringReader() { }
        public StringReader(string input){
            this.input = input;
        } 
        public void ReadString(string input)
        {
            this.input = input;
        }
        public char Read()
        {
            char ch = (char)0; //EOF
            curPos += 1;
            if (curPos < input.Length){
                column += 1;
                ch = input[curPos];
            }
            if (ch == '\n'){
                line += 1;
                column = 0;
            }
            return ch;
        }
        public int GetLine() { return line; }
        public int GetColumn() { return column; }
        public char Peek(){
            if (IsAtEnd()) return (char)0;
            return input[curPos + 1];
        }
        public bool IsAtEnd(){
            return curPos + 1 >= input.Length;
        }
    }
}
