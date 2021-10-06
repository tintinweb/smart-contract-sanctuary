/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract test{
    event ExecutionResult(bool indexed success, bytes indexed result);
    function foo(address target, bytes memory data) external {
        // Make the function call
        (bool success, bytes memory result) = target.call(data);
    
        // success is false if the call reverts, true otherwise
        require(success, "Call failed");
    
        // result contains whatever has returned the function
        emit ExecutionResult(success, result);
    }
}