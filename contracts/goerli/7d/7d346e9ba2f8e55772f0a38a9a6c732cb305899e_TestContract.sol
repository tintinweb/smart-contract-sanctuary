/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract TestContract {
    uint public variable;
    address public owner;
    
    function set_variable(uint num) public {
        require(msg.sender == owner);
        variable = num;
    }

    constructor() {
        owner = msg.sender;
    }
}