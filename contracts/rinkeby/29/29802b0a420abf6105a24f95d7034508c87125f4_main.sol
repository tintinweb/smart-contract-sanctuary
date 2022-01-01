/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


contract main {
    constractA _a;

    constructor(address _v) {
        _a = constractA(_v);
    }

    function call() public view{
        _a.get();
    }
}

contract constractA {
    function get() public pure returns(uint){
        return 0;
    }
}


contract constractB {
    function get() public pure returns(uint){
        return 1;
    }
}