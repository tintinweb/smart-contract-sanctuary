/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: UNLICENSED;

pragma solidity ^0.8.0;


contract MyContract {
   uint a;
   uint b;

    function Setval(uint _a, uint _b) public{
        a = _a;
        b = _b;
    }
        

    function  getValue() public view returns(uint) {
            
            return a + b;
    }

}