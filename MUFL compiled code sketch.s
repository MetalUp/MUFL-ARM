// Evaluate: 5 + 6
    MOV R0, #5
    MOV R1, #6
    ADD R0,R0,R1

// Evaluate: (5 + 6) – (3 + 4) => 4
//(5+6)
    PUSH {R0-R3} //Because expression is in brackets
    //Set up params
    MOV R0, #5 
    MOV R1, #6
//Begin Operator call - just inline the appropriate instruction, working on R0-R3 as params
    ADD R0,R0,R1 
//End Operator call
    MOV R12, R0
    POP {R0-R3} 
    MOV R0, R12  //1st param of next level up
//  (3+4)
    PUSH {R0-R3}
    MOV R0, #3
    MOV R1, #4 
//Begin Operator call - just inline the appropriate instruction, working on R0-R3 as params
    ADD R0,R0,R1 
//End Operator call
    MOV R12, R0 
    POP {R0-R3}
    MOV R1, R12 //2nd param of next level up
//(...) - (...)
    SUB R0,R0,R1   //Result is now in R0

// Evaluate: Max(5, 6) – Max(3, 4)
// Max(5, 6)
    PUSH {R0-R3}
    MOV R0, #5
    MOV R1, #6
//  Begin Function call
    PUSH {R4-R7} //could optimise this and next 4 instructions down to number of variables used
    MOV R4,R0 
    MOV R5,R1
    MOV R6,R2 
    MOV R7,R3
    BL Max  //Result back in R0
    POP {R4-R7} //Restore variables from next level up
//  End Function call
    MOV R12, R0
    POP {R0-R3}
    MOV R0, R12  //1st param of next level up
// Max(3, 4)
    PUSH {R0-R3}
    MOV R0, #3
    MOV R1, #4
//  Begin Function call
    PUSH {R4-R5} //Only pushes number of variables used
    //Copy params to variables registers
    MOV R4,R0
    MOV R5,R1
    BL Max  //Result back in R0 (Max must store LR)
    POP {R4-R5} //Restore variables from next level up
//  End Function call
    MOV R12, R0
    POP {R0-R3}
    MOV R1, R12  /2nd param of next level up
//R0 - R1
    SUB R0,R0,R1  //Result is now in R0


// Evaluate: Max(5 + 6, 3 + 4)
//(5+6)
    PUSH {R0-R3}
    MOV R0, #5
    MOV R1, #6
//Begin Operator call - just inline the appropriate instruction, working on R0-R3 as params
    ADD  R12,R0,R1
//End Operator call
    MOV R12, R0
    POP {R0-R3}
    MOV R0, R12  //1st param of next level up
//  (3+4)
    PUSH {R0-R3}
    MOV R0, #5
    MOV R1, #6
//Begin Operator call - just inline the appropriate instruction, working on R0-R3 as params
    ADD  R12,R0,R1
//End Operator call
    MOV R12, R0
    POP {R0-R3}
    MOV R1, R12 //2nd param of next level up
//Max(R0, R1)
//  Begin Function call
    PUSH {R4-R5} //Only pushes number of variables used
    //Copy params to variables registers
    MOV R4,R0
    MOV R5,R1
    BL Max  //Result back in R0 (Max must store LR)
    POP {R4-R5} //Restore variables from next level up
//  End Function call
   
//Evaluate expression 3 > 4
    MOV R0, #3
    MOV R1, #4
    CMP R0, R1
    MOV R0, #1
    BGT +2 //end
    MOV R0, #0
//end

//Evaluate expression 5 if 3 > 4 else 6  -  or  3 > 4 ? 5 : 6
//  3 > 4 
    //set up params
    MOV R0, #3
    MOV R1, #4
    //boilerplate
    CMP R0, R1
    MOV R0, #1
    BGT +2
    MOV R0, #0
// if
    CMP R0, #0
    BEQ //else
//then clause
    MOV R0, #5
    B //end
//else clause
    MOV R0, #6
//end

//Compiled implementation of Max(a,b) => a if a > b else b
//  a > b
    //No need to push, as no sub calls, and no registers above R3 altered 
    //set up params 
    MOV R0, R4
    MOV R1, R5
    //boilerplate
    CMP R0, R1
    MOV R0, 1
    BGT +2
    MOV R0, 0
// if
    CMP R0, 0
    BEQ //else
//then clause
    MOV R0, R4
    B //end
//else clause
    MOV R0, R5
    RET
//end

//Compiled implementation of Max(a,b,c) => Max(a, Max(b,c))
