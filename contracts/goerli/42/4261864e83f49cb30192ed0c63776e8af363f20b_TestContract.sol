/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract TestContract {
    string public str;
    
    function setVar(string memory input) public {
        str = input;
    }

    constructor() {
        str = "aaa";
    }
}