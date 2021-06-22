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
