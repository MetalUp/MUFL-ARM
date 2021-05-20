//Test code
      MOV R0, #source
main: STR R0, .ReadString
      MOV R1, #tokenList
      PUSH {R0}
      BL tokenizer
      MOV R2, R0
      POP {R0}
      CMP R2, #0
      BEQ main
//    Handle parse error
      STR R0, .WriteString //Echo back the source
      MOV R2, #10       //newline
      STRB R2, .WriteChar 
      MOV R2, #32       //Space
      STRB R2, .WriteChar //Write number of spaces to match current character pointer in R2
      SUBS R1, R1, #1
      BGT .-2
      MOV R2, #parseErrorMsg
      STR R2, .WriteString
      B main
// tokenizer: Parse input string and generate a list of tokens
// Input parameters: R0 has address of a zero-terminated string of source expression;
//                   R1 has start address where tokens are to be stored
// Returned values: R0 has result code. Anything non-zero indicates error. 
//                  R1 will have the character number where the error was detected.
//                  
//R0: Start of expression
//R1: Index
//R2: Temp
//R3: Token counter
//R4: Temp
//Constants
literalToken: .WORD 0x10000000
openBracket: .WORD 0x20000028
closeBracket: .WORD 0x20000029
parseErrorMsg: .ASCIZ "^ Parse error!"
comma: .WORD 0x2000002C
tokenizer: 
      PUSH {R4-R8,LR}
      MOV R4, R1
      MOV R1, #0
      MOV R3, #0
//Get next char
loop1: LDRB R2, [R0 + R1]
//Test for end of line
      CMP R2, #0
      BEQ end
//Test for space
      CMP R2, #32       //ASCII space
      BEQ nextChar
//Test for numeric digit
      CMP R2, #48       //ASCII '0'
      BLT notADigit
      CMP R2, #57       //ASCII '9'
      BGT notADigit
//Tokenize number
      PUSH {R0, R3}
      BL readInteger    //Token returned in R0, R1 (index into source) will have been updated or be -1
      MOV R2, R0
      POP {R0, R3}
      LDR R5, literalToken //Store the literalToken and the integer in the tokenlist
      STR R5, [R4 + R3]
      ADD R3, R3, #4    //Update token pointer to next word
      STR R2, [R4 + R3]
      ADD R3, R3, #4    //Update token pointer to next word
      MVN R2, #0        //Results in '-1'
      CMP R1, R2        //This would mean that end of source was reached
      BEQ end 
      B cont
notADigit:
//Test for puncuators
      CMP R2, #40       // '('
      BNE .+5
      LDR R5, openBracket
      STR R5, [R4 + R3]
      ADD R3, R3, #4 
      B nextChar
      CMP R2, #41       // ')'
      BNE .+5
      LDR R5, closeBracket
      STR R5, [R4 + R3]
      ADD R3, R3, #4 
      B nextChar
      CMP R2, #44       // ','
      BNE .+5
      LDR R5, comma
      STR R5, [R4 + R3]
      ADD R3, R3, #4 
      B nextChar
//Test for variables
parseError: MVN R0, #0  //Return -1 indicating error
      B end
nextChar: ADD R1, R1, #1 //Update char index
cont: B loop1
end:  POP {R4-R8, LR}   //POP saved registers
      RET
// Returned: Read up to 8 numeric chars and convert to a binary integer,
// Input params: R0 has address of a zero-terminated string of chars to be read; R1 has index of first numeric digit to be read. 
// Returned results: R0 has binary number; R1 has index of next unread character or -1 if the end of string has been reached 
readInteger: PUSH {R4-R8} //Save variable registers used locally
      MOV R7, #0        //R7: Built up BCD
      MOV R3, #0        //Digit counter
      LDRB R2, [R0 + R1] //Read up to 8 decimal digits from string
      CMP R2, #48       //ASCII 0
      BLT .+12
      CMP R2, #57       //ASCII 9
      BGT .+10
      CMP R1, #0
      BEQ .+2
      LSL R7, R7, #4
      SUB R2, R2, #48 
      ADD R7, R7, R2
      ADD R1, R1, #1
      ADD R3, R3, #1
      CMP R3, #8        //Max 8 digits
      BLT .-13
      CMP R2, #0        //End of string marker
      BNE .+2
      MVN R1,#0         //Return index value -1 indicating that end of string has been reached.
// Convert BCD to binary
      MOV R6, #0        //R6: Bit counter
      LSR R8, R8, #1    //For each bit ...
      LSRS R7, R7, #1
      BCS .+2
      B .+2
      ADD R8,R8,#0x80000000
//Set up the masks
      MOV R2, #0xF0000000 //Nibble mask
      MOV R3, #0x80000000 //8 for comparison
      MOV R4, #0x30000000 //3 to add if nibble is >= 8
      AND R5, R7, R2    //For each nibble in R0
      CMP R5, R3
      BLT .+2           //    If >= 8 subtract 3
      SUB R7, R7, R4
      LSR R2, R2, #4    //Move to next digit
      LSR R3, R3, #4
      LSR R4, R4, #4
      CMP R2, #0        //If all 8 digits done...
      BEQ .+2           //
      B .-9             //Next nibble
      ADD R6, R6, #1    //Increment bit counter
      CMP R6, #32       //All bits done?
      BLT .-20          //Next bit 
      MOV R0, R8        //Return binary value in R0
      POP {R4-R8}       //Restore variable registers
      RET
      .ALIGN 256
      .DATA
source: .BLOCK 256      //256 chars
tokenList: .BLOCK 512   //128 words
