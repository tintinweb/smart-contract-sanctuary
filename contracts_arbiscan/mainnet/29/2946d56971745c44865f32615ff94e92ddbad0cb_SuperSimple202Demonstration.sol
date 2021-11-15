/**
 *Submitted for verification at arbiscan.io on 2021-11-15
*/

pragma solidity ^0.4.24;

contract SuperSimple202Demonstration {
    
    // two functions
    // one which returns false because we swap around the parameters
    // the other which returns true, since we do not apply SuperSimple202Demonstration
    
    
    // this one returns false, as in reality, 2, 1 is passed to executeAndReturnResult
    // it works something like: /*startu202e....../*end*/u202d
    function With202E() public pure returns (bool) {
        return executeAndReturnResult(/*start‮‮‮‮/*dne*/ 2,1 /*‭
                  /*additional comment here to escape comment block, not having this will comment the rest of the code*/);
    }							
							
    // this one returns true per normal
    function Without202E() public pure returns (bool) {
        return executeAndReturnResult(1, 2);
    }
    
    function executeAndReturnResult(int p, int n) internal pure returns (bool) {
        if (p == 1 && n == 2) {
            return true;
        } else if (p == 2 && n == 1) {
            return false;
        }
    }

}