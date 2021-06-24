//Test executing a function from its token, setting up the params manually
      LDR R0, 0x408     //'+' token
      MOV R4, #3
      MOV R5, #4
      BL ExecuteBasicFunction
      MOV R1, #7        // Expected
      MOV R2, #1        //Test number 1
      BL AssertR0eqR1
//
      LDR R0, 0x41c     //'-' token
      MOV R4, #9
      MOV R5, #7
      BL ExecuteBasicFunction
      MOV R1, #2        // Expected
      MOV R2, #2        //Test number 2
      BL AssertR0eqR1
//
      LDR R0, 0x430     //'&' token
      MOV R4, #0xA
      MOV R5, #0xD
      BL ExecuteBasicFunction
      MOV R1, #8        // Expected
      MOV R2, #3        //Test number 3
      BL AssertR0eqR1
//
      LDR R0, 0x444     //'Or' token
      MOV R4, #0xA
      MOV R5, #0xD
      BL ExecuteBasicFunction
      MOV R1, #0xF      // Expected
      MOV R2, #4        //Test number 4
      BL AssertR0eqR1
//
      LDR R0, 0x458     //'Xor' token
      MOV R4, #0xA
      MOV R5, #0xD
      BL ExecuteBasicFunction
      MOV R1, #0x7      // Expected
      MOV R2, #5        //Test number 5
      BL AssertR0eqR1
//
      LDR R0, 0x46c     //'!' token
      MOV R4, #0xA
      BL ExecuteBasicFunction
      MVN R1, #0xA      // Expected
      MOV R2, #6        //Test number 6
      BL AssertR0eqR1
//
      LDR R0, 0x480     //'<<' token
      MOV R4, #0xA
      MOV R5, #1
      BL ExecuteBasicFunction
      Mov R1, #0x14     // Expected
      MOV R2, #7        //Test number 7
      BL AssertR0eqR1
//
      LDR R0, 0x494     //'<<' token
      MOV R4, #0xA
      MOV R5, #1
      BL ExecuteBasicFunction
      Mov R1, #5        // Expected
      MOV R2, #8        //Test number 8
      BL AssertR0eqR1
//
      LDR R0, 0x4a8     //'>' token
      MOV R4, #9
      MOV R5, #7
      BL ExecuteBasicFunction
      MOV R1, #1        // Expected
      MOV R2, #9        //Test number 9
      BL AssertR0eqR1
//
      LDR R0, 0x4c8     //'<' token
      MOV R4, #9
      MOV R5, #7
      BL ExecuteBasicFunction
      MOV R1, #0
      MOV R2, #10       //Test number 10
      BL AssertR0eqR1
//
      LDR R0, 0x508     //'!=' token
      MOV R4, #9
      MOV R5, #7
      BL ExecuteBasicFunction
      MOV R1, #1        // Expected
      MOV R2, #11       //Test number 11
      BL AssertR0eqR1
//
      LDR R0, 0x508     //'!=' token
      MOV R4, #9
      MOV R5, #9
      BL ExecuteBasicFunction
      MOV R1, #0
      MOV R2, #12       //Test number
      BL AssertR0eqR1
//
      B AllTestsPassed
//
// Input: Function token in R0
ExecuteBasicFunction:
      AND R1, R0, #0x0F000000
      LSR R1, R1, #24   //R1 now holds num params
      MOV R2, #0xFFFF   //Mask for address 
      AND R2, R0,R2     //R2 holds address of function impl
      PUSH {LR}
      MOV LR, PC        //Set up computer branch to R2
      MOV PC, R2
      POP {LR}
      RET
//
//Test framework
AssertR0eqR1:
      CMP R0, R1
      BNE .+2
      RET
      MOV R3, #failed
      STR R3, .WriteString
      STR R2, .WriteUnsignedNum
      MOV R3, #expected
      STR R3, .WriteString
      STR R1,. WriteUnsignedNum
      MOV R3, #actual
      STR R3, .WriteString
      STR R0,. WriteUnsignedNum
      HLT
failed: .ASCIZ "Failed test No:"
expected: .ASCIZ "Expected:"
actual: .ASCIZ "Actual value:"
AllTestsPassed:
      MOV R0, #passedMsg
      STR R0, .WriteString
      HLT
passedMsg: 
      .ASCIZ "Passed all tests"
//
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
      .Word 0x0000213d  // Name: '!='
      .Word 0x520       // Link or zero for end
      .Word 0xB200050c  // Token
      MOV R0, #1        // Compiled impl
      CMP R4,R5
      BNE .+2
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
