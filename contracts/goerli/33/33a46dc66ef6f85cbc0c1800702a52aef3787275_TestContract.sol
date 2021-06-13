/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract TestContract {
    uint public variable;
    address public owner;
    
    event VarSet(uint from, uint to);

    function set_variable(uint num) public {
        require(msg.sender == owner);
        emit VarSet(variable, num);
        variable = num;
    }

    constructor() {
        owner = msg.sender;
    }
}