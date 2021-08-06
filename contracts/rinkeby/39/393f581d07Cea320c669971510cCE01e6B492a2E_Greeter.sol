/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

error GreeterError();

contract Greeter {
    string public greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function throwError() external {
        greeting = "Error";
        revert GreeterError();
    }
}