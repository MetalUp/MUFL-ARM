RunTests: B Test20
EvaluateExpression:     //In: R1 Token ptr Out: R0 result, R1 token ptr updated
      PUSH {LR}
      LDR R0, [R1]
      ADD R1, R1, #4    //Increment token pointer TODO: here or later?
      CMP R0, #0
      BLT .+2           //Indicates that token is not a number
      B end_EvaluateExpression 
      AND R2, R0, #0xF0000000 //Mask for token type
      CMP R2, #0xE0000000 //Test for function (0xE.. basic function, 0xF.. UDF)
      BLT .+3
      BL EvaluateParamsAndExecuteFunction
      B end_EvaluateExpression 
      MOV R12, #1       //Error No.
end_EvaluateExpression: 
      POP {LR}
      RET
EvaluateParamsAndExecuteFunction: //In: R0 function token, R1 Next token ptr Out: R0 result, R1 Updated next token ptr
      PUSH {LR, R4-R11}
      AND R2, R0, #0x0f000000 //Mask for num params
      LSR R2, R2, #22   //R2 now holds num params (0 - 4) x 4
      MOV R3, #0
startLoop:
      CMP R3, R2        //StartOfLoop for each parameter
      BEQ allParamsProcessed //To: AllParamsProcessed
      PUSH {R0}
      PUSH {R2, R3}
      BL EvaluateExpression //Result is in R0, R1 us updated
      POP {R2, R3}
      PUSH {R8-R11}     //Transfer R0 to the appropriate parameter-holding-pen register (R8-R11)
      STR R0, [SP + R3]
      POP {R8-R11}
      POP {R0}
      ADD R3, R3, #4    //Next param
      B startLoop       //To StartOfLoop 
allParamsProcessed: 
      MOV R4, R8        //AllParamsProcessed:  Transfer R8-R11 to R4-R7
      MOV R5, R9        //Note reversal of order because R2 will be counting down.
      MOV R6, R10
      MOV R7, R11
      BL ExecuteBasicFunction //TODO: different call for UDF
      POP {LR, R4-R11}
      RET               //Result in R0
ErrorHandler:           // In: R0 Error number
      PUSH {R12}
      LSL R12, R12, #2  // x 4
      ADD R12, R12, #4  //Offset to start of error message pointers
      LDR R12, [PC + R12]
      STR R12, .WriteString
      POP {R12}
      RET
      .Word error1      //Each error message must be added here
error1: .ASCIZ "Error Type 1"
GetFunctionToken:       // In: R0 function name (up to 4 chars). Out: R0 has func token or -1 if not found.
      MOV R1, #Add
      LDR R2, [R1]
      CMP R2, #0        //End of functions indicator
      BEQ .+9           //Not Found
      CMP R0,R2
      BEQ .+4           //Found
      ADD R1, R1, #4    //Advance 1 word
      LDR R1, [R1]      //Get next addr
      B .-7             //Repeat search
      ADD R1, R1, #8    //Found: Advance two words
      LDR R0, [R1]      //Get token
      RET
      MVN R0, #0        //Not Found: return -1
      RET
ExecuteBasicFunction:   // Given func token in R0, and params set up in R4+, returns result in R0
      PUSH {LR}
      MOV R2, #0xFFFF   //Mask for address 
      AND R2, R0,R2     //R2 holds address of function impl
      MOV LR, PC        //Set up computer branch to R2
      MOV PC, R2
      POP {LR}
      RET
      .Align 1024
//Basic Functions
Add:
      .Word 0x0000002b  // Name: '+'
      .Word 0x414       // Link
      .Word 0xE200040c  // Token
      ADD R0,R4,R5      // Compiled impl
      RET
Sub:
      .Word 0x0000002d  // Name: '-'
      .Word 0x428       // Link
      .Word 0xE2000420  // Token
      SUB R0,R4,R5      // Compiled impl
      RET
And:
      .Word 0x00000026  // Name: '&'
      .Word 0x43c       // Link
      .Word 0xE2000434  // Token
      AND R0,R4,R5      // Compiled impl
      RET
Or:
      .Word 0x00004F72  // Name: 'Or'
      .Word 0x450       // Link
      .Word 0xE2000448  // Token
      ORR R0,R4,R5      // Compiled impl
      RET
Xor:
      .Word 0x00586F72  // Name: 'Xor'
      .Word 0x464       // Link
      .Word 0xE200045c  // Token
      XOR R0,R4,R5      // Compiled impl
      RET
Not:
      .Word 0x00000021  // Name: '!'
      .Word 0x478       // Link or zero for end
      .Word 0xE2000470  // Token
      MVN R0,R4         // Compiled impl
      RET
Lsl:
      .Word 0x00003c3c  // Name: '<<'
      .Word 0x48c       // Link or zero for end
      .Word 0xE2000484  // Token
      LSL R0,R4,R5      // Compiled impl
      RET
Lsr:
      .Word 0x00003e3e  // Name: '>>'
      .Word 0x4a0       // Link or zero for end
      .Word 0xE2000498  // Token
      LSR R0,R4,R5      // Compiled impl
      RET
Gt:
      .Word 0x0000003e  // Name: '>'
      .Word 0x4c0       // Link or zero for end
      .Word 0xE20004ac  // Token
      MOV R0, #1        // Compiled impl
      CMP R4,R5
      BGT .+2
      MOV R0, #0
      RET
Lt:
      .Word 0x0000003c  // Name: '<'
      .Word 0x4e0       // Link or zero for end
      .Word 0xE20004cc  // Token
      MOV R0, #1        // Compiled impl
      CMP R4,R5
      BLT .+2
      MOV R0, #0
      RET
Eq:
      .Word 0x00003d3d  // Name: '=='
      .Word 0x500       // Link or zero for end
      .Word 0xE20004ec  // Token
      MOV R0, #1        // Compiled impl
      CMP R4,R5
      BEQ .+2
      MOV R0, #0
      RET
Ne:
      .Word 0x0000213d  // Name: '!='
      .Word 0x520       // Link or zero for end
      .Word 0xE200050c  // Token
      MOV R0, #1        // Compiled impl
      CMP R4,R5
      BNE .+2
      MOV R0, #0
      RET
//TESTS
      .Align 1024
Test0:                  //Tests the test method only
      MOV R0, #7
      MOV R1, #7
      MOV R2, #0
      BL AssertAreEqual
Test1:                  // +
      LDR R0, 0x408 
      MOV R4, #3
      MOV R5, #4
      BL ExecuteBasicFunction
      MOV R1, #7        // Expected
      MOV R2, #1        //Test number
      BL AssertAreEqual
Test2:                  // -
      LDR R0, 0x41c 
      MOV R4, #9
      MOV R5, #7
      BL ExecuteBasicFunction
      MOV R1, #2        // Expected
      MOV R2, #2        //Test number
      BL AssertAreEqual
Test3:                  // & 
      LDR R0, 0x430 
      MOV R4, #0xA
      MOV R5, #0xD
      BL ExecuteBasicFunction
      MOV R1, #8        // Expected
      MOV R2, #3        //Test number
      BL AssertAreEqual
Test4:                  // Or
      LDR R0, 0x444 
      MOV R4, #0xA
      MOV R5, #0xD
      BL ExecuteBasicFunction
      MOV R1, #0xF      // Expected
      MOV R2, #4        //Test number
      BL AssertAreEqual
Test5:                  // Xor
      LDR R0, 0x458 
      MOV R4, #0xA
      MOV R5, #0xD
      BL ExecuteBasicFunction
      MOV R1, #0x7      // Expected
      MOV R2, #5        //Test number
      BL AssertAreEqual
Test6:                  // Not
      LDR R0, 0x46c     //'!' token
      MOV R4, #0xA
      BL ExecuteBasicFunction
      MVN R1, #0xA      // Expected
      MOV R2, #6        //Test number
      BL AssertAreEqual
Test7:                  // Lsl
      LDR R0, 0x480     //'<<' token
      MOV R4, #0xA
      MOV R5, #1
      BL ExecuteBasicFunction
      Mov R1, #0x14     // Expected
      MOV R2, #7        //Test number
      BL AssertAreEqual
Test8:                  // Lsr
      LDR R0, 0x494     //'>>' token
      MOV R4, #0xA
      MOV R5, #1
      BL ExecuteBasicFunction
      Mov R1, #5        // Expected
      MOV R2, #8        //Test number
      BL AssertAreEqual
Test9:                  // Gt
      LDR R0, 0x4a8     //'>' token
      MOV R4, #9
      MOV R5, #7
      BL ExecuteBasicFunction
      MOV R1, #1        // Expected
      MOV R2, #9        //Test number
      BL AssertAreEqual
Test10:                 // Lt
      LDR R0, 0x4c8     //'<' token
      MOV R4, #9
      MOV R5, #7
      BL ExecuteBasicFunction
      MOV R1, #0
      MOV R2, #10       //Test number
      BL AssertAreEqual
Test11:                 // Eq
      LDR R0, 0x508     //'==' token
      MOV R4, #9
      MOV R5, #7
      BL ExecuteBasicFunction
      MOV R1, #1        // Expected
      MOV R2, #11       //Test number 11
      BL AssertAreEqual
Test12:                 // Ne
      LDR R0, 0x508     //'!=' token
      MOV R4, #9
      MOV R5, #9
      BL ExecuteBasicFunction
      MOV R1, #0
      MOV R2, #12       //Test number
      BL AssertAreEqual
Test13:                 // Get function token by function name, starting with +
      MOV R0, #0x2b     //+
      BL GetFunctionToken
      MOV R1, #Add      //because it is the first function
      ADD R1, R1, #8
      LDR R1, [R1]
      MOV R2, #13       //Test number
      BL AssertAreEqual
Test14:                 //Or
      MOV R0, #0x4F72   //Or
      BL GetFunctionToken
      MOV R1, #Or
      ADD R1, R1, #8
      LDR R1, [R1]
      MOV R2, #14       //Test number
      BL AssertAreEqual
Test15:                 // Ne
      MOV R0, #0x213d   //Ne
      BL GetFunctionToken
      MOV R1, #Ne
      ADD R1, R1, #8
      LDR R1, [R1]
      MOV R2, #15       //Test number
      BL AssertAreEqual
Test16:                 // Non-existant function Foo
      MOV R0, #0x466f6f //Foo
      BL GetFunctionToken
      MVN R1, #0        //-1
      MOV R2, #16       //Test number
      BL AssertAreEqual
//Expression evaluation
Test17:                 // '7'
      B .+2
      .Word 7 
      SUB R1, PC, #12
      BL EvaluateExpression
      MOV R1, #7        //Expected
      MOV R2, #17       //Test number
      BL AssertAreEqual
Test18:                 // Invalid token
      B .+2
      .Word 0xD000002b 
      SUB R1, PC, #12
      BL EvaluateExpression
      MOV R0, R12       //Test the error message No.
      MOV R1, #1        //Expected
      MOV R12, #0       //Reset error flag
      MOV R2, #18       //Test number
      BL AssertAreEqual
Test19:                 // '+5 6'
      B .+4
      .Word 0xE200040c  // Function '+'
      .Word 5
      .Word 6
      SUB R1, PC, #20
      BL EvaluateExpression
      MOV R1, #11       //Expected
      MOV R2, #19       //Test number
      BL AssertAreEqual
Test20:                 // Function '+ + 3 4 5'
      BL ClearRegisters0_12
      B .+6
      .Word 0xE200040c  // Function '+'
      .Word 0xE200040c  // Function '+'
      .Word 3
      .Word 4
      .Word 5
      SUB R1, PC, #28
      BL EvaluateExpression
      MOV R1, #12       //Expected
      MOV R2, #20       //Test number
      BL AssertAreEqual 
Test21:                 // Function '+ << 3 1 << 4 2'
      B .+7
      .Word 0xE200040c  // +
      .Word 0xE2000484  // <<
      .Word 3
      .Word 1
      .Word 0xE2000484  // <<
      .Word 4
      .Word 2
      SUB R1, PC, #36
      BL EvaluateExpression
      MOV R1, #22       //Expected
      MOV R2, #21       //Test number
      BL AssertAreEqual 
      B AllTestsPassed
ClearRegisters0_12:
      MOV R0, #0
      MOV R1, #0
      MOV R2, #0
      MOV R3, #0
      MOV R4, #0
      MOV R5, #0
      MOV R6, #0
      MOV R7, #0
      MOV R8, #0
      MOV R9, #0
      MOV R10, #0
      MOV R11, #0
      MOV R12, #0
      RET
AssertAreEqual:         // Compares R0 (actual) with R1 (expected). Returns if equal, otherwise halts with console message indicating test number (R2). 
      CMP R0, R1
      BNE .+2
      RET
      MOV R3, #testFailedMsg
      STR R3, .WriteString
      STR R2, .WriteUnsignedNum
      MOV R3, #testExpectedMsg
      STR R3, .WriteString
      STR R1,. WriteUnsignedNum
      MOV R3, #testActualMsg
      STR R3, .WriteString
      STR R0,. WriteUnsignedNum
      HLT
AllTestsPassed:         // Writes message to console and halts
      MOV R0, #testPassedMsg
      STR R0, .WriteString
      STR R2, .WriteUnsignedNum
      HLT
testFailedMsg: .ASCIZ "Failed #"
testExpectedMsg: .ASCIZ "Expected:"
testActualMsg: .ASCIZ "Actual:"
testPassedMsg: .ASCIZ "Passed tests: "
