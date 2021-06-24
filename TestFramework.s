test1:                  //Tests the test methods
      MOV R0, #7
      MOV R1, #7
      MOV R2, #1
      BL AssertAreEqual
      B AllTestsPassed
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
testFailedMsg: .ASCIZ "Failed #"
testExpectedMsg: .ASCIZ "Expected:"
testActualMsg: .ASCIZ "Actual:"
AllTestsPassed:         // Writes message to console and halts
      MOV R0, #testPassedMsg
      STR R0, .WriteString
      STR R2, .WriteUnsignedNum
      HLT
testPassedMsg: .ASCIZ "Passed tests: "
