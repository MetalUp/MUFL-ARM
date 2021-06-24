//Evaluate a simple (non-nested) tokenised expression 
//
      MOV R0, #TestExpr1
      BL EvaluateExpression
      MOV R1, #7        //Expected
      MOV R2, #1        //Test number 1
      BL AssertR0eqR1
//
      MOV R0, #TestExpr2
      BL EvaluateExpression
      MOV R0, R12       //Test the error message No.
      MOV R1, #0        //Expected
      MOV R2, #2        //Test number 2
      BL AssertR0eqR1
//
      MOV R0, #TestExpr3
      BL EvaluateExpression
      MOV R1, #11       //Expected error message
      MOV R2, #3        //Test number 3
      BL AssertR0eqR1
//
      B AllTestsPassed
//
TestExpr1:
      .Word 7           // Literal value
TestExpr2:
      .Word 0xD000002b  // 'Invalid token
TestExpr3:
      .Word 0xb000002b  // '+'
      .Word 5
      .Word 6

EvaluateExpression:
 //
 //Input:  R0 pointer to starting token
 //Output: R0 holds result
      PUSH {LR}
      LDR R1, [R0]
      ADD R0, R0, #1
      CMP R1, #0
      BLT .+3           //Indicates that it is not a number
      MOV R0, R1        // Number token is result
      B endEvaluateExpression 
      AND R2, R1, #0xF0000000 //Mask for token type
      CMP R2, #0xB0000000 //Test for basic function
      BNE .+3
      BL EvaluateParamsAndExecuteBasicFunction
      B endEvaluateExpression 
      MOV R12, #0       //Error No.
      BL Error
endEvaluateExpression: 
      POP {LR}
      RET
//
EvaluateParamsAndExecuteBasicFunction:
      RET
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
//Will halt if R0 != R1 and print message to console. If all OK will return.
// Input: R0 Actual value
//        R1 Expected value
//        R2 Test number
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
failed: .ASCIZ "Failed #"
expected: .ASCIZ "Expected:"
actual: .ASCIZ "Actual:"
AllTestsPassed:
      MOV R0, #passedMsg
      STR R0, .WriteString
      STR R2, .WriteUnsignedNum
      HLT
passedMsg: 
      .ASCIZ "Passed tests up to:"
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
//
// Input: R0 Error message number
Error: PUSH {R12}
      LSL R12, R12, #2  // x 4
      LDR R12, [R12 + errorMessages]
      STR R12, .WriteString
      POP {R12}
      RET
errorMessages:
      .Word error0
error0: .ASCIZ "Unrecognised Token Type in R1. \n"
      .Align 1024
Functions:
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
