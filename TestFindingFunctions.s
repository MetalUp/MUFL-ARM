//Test finding a function
      MOV R0, #0x2b     //+
      BL GetFunctionToken
      MOV R1, #Functions //because it is the first function
      ADD R1, R1, #8
      LDR R1, [R1]
      BL assertR0eqR1
      MOV R0, #0x4F72   //Or
      BL GetFunctionToken
      MOV R1, #Or
      ADD R1, R1, #8
      LDR R1, [R1]
      BL assertR0eqR1
      MOV R0, #0x213d   //Ne
      BL GetFunctionToken
      MOV R1, #Ne
      ADD R1, R1, #8
      LDR R1, [R1]
      BL assertR0eqR1
      MOV R0, #0x466f6f //Non existant function Foo
      BL GetFunctionToken
      MVN R1, #0        //-1
      BL assertR0eqR1
      MOV R0, #passedMsg
      STR R0, .WriteString
      HLT
//
//Test framework
assertR0eqR1:
      CMP R0, R1
      BNE .+2
      RET
      MOV R0, #failedMsg
      STR R0, .WriteString
      HLT
failedMsg: 
      .ASCIZ "Failed test"
passedMsg: 
      .ASCIZ "Passed tests"
//
// Function under test
//Input: Function name (as up to 4 ASCII) in R0
// Result in R0 is function token. If no function returned, result is -1
GetFunctionToken:
      MOV R1, #Functions
      LDR R2, [R1]
      CMP R2, #0        //End of functions indicator
      BEQ notFound
      CMP R0,R2
      BEQ found
      ADD R1, R1, #4    //Advance 1 word
      LDR R1, [R1]      // Get next addr
      B .-7             //Repeat search
found: ADD R1, R1, #8   //Advance two words
      LDR R0, [R1]      //Get token
      RET
notFound: MVN R0, #0    //-1
      RET
      3
      .Align 1024
Functions:
      .data
//Add
      .Word 0x0000002b  // Name: '+'
      .Word 0x414       // Link
      .Word 0xB200040c  // Token
      ADD R0,R4,R5      // Compiled impl
      RET
Sub:
      .Word 0x0000002d  // Name: '-'
      .Word 0x428       // Link
      .Word 0xB2000420  // Token
      SUB R0,R4,R5      // Compiled impl
      RET
And:
      .Word 0x00000026  // Name: '&'
      .Word 0x43c       // Link
      .Word 0xB2000434  // Token
      AND R0,R4,R5      // Compiled impl
      RET
Or:
      .Word 0x00004F72  // Name: 'Or'
      .Word 0x450       // Link
      .Word 0xB2000448  // Token
      ORR R0,R4,R5      // Compiled impl
      RET
Xor:
      .Word 0x00586F72  // Name: 'Xor'
      .Word 0x464       // Link
      .Word 0xB200045c  // Token
      XOR R0,R4,R5      // Compiled impl
      RET
Not:
      .Word 0x00000021  // Name: '!'
      .Word 0x478       // Link or zero for end
      .Word 0xB2000470  // Token
      MVN R0,R4         // Compiled impl
      RET
Lsl:
      .Word 0x00003c3c  // Name: '<<'
      .Word 0x48c       // Link or zero for end
      .Word 0xB2000484  // Token
      LSL R0,R4,R5      // Compiled impl
      RET
Lsr:
      .Word 0x00003e3e  // Name: '>>'
      .Word 0x4a0       // Link or zero for end
      .Word 0xB2000498  // Token
      LSR R0,R4,R5      // Compiled impl
      RET
Gt:
      .Word 0x0000003e  // Name: '>'
      .Word 0x4c0       // Link or zero for end
      .Word 0xB20004ac  // Token
      MOV R0, #1        // Compiled impl
      CMP R4,R5
      BGT .+2
      MOV R0, #0
      RET
Lt:
      .Word 0x0000003c  // Name: '<'
      .Word 0x4e0       // Link or zero for end
      .Word 0xB20004cc  // Token
      MOV R0, #1        // Compiled impl
      CMP R4,R5
      BLT .+2
      MOV R0, #0
      RET
Eq:
      .Word 0x00003d3d  // Name: '=='
      .Word 0x500       // Link or zero for end
      .Word 0xB20004ec  // Token
      MOV R0, #1        // Compiled impl
      CMP R4,R5
      BEQ .+2
      MOV R0, #0
      RET
Ne:
      .Word 0x0000213d  // Name: '=='
      .Word 0x520       // Link or zero for end
      .Word 0xB200050c  // Token
      MOV R0, #1        // Compiled impl
      CMP R4,R5
      BEQ .+2
      MOV R0, #0
      RET
StartOfUDFs:            //Start of UDFs
//Sum3
      .Word 0x53756d33  // Name: 'Sum3'
      .Word 0x540       // Link
      .Word 0xF305052c  //  Token Function, 2 params, 5 tokens, addr.
// Tokens
      .Word 0xF2000000  //+
      .Word 0xA0000000  //Var 0
      .Word 0xF2000000  //+
      .Word 0xA0000001  //Var 1
      .Word 0xA0000002  //Var 2
//Max
      .Word 0x003       // Name: 'Max'
      .Word 0x560       // Link
      .Word 0xF205054c  // Token Function, 2 params, 5 tokens, addr.
// Tokens
      .Word 0xC0000000  // If (condition)
      .Word 0xB20004ac  // Gt
      .Word 0xA0000000  // Var 0 
      .Word 0xA0000001  //Var 1
      .Word 0xA0000002  //Var 2
EndOfFunctions:
      .Word 0
