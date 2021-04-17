/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

pragma solidity 0.5.9;
// SPDX-License-Identifier: MIT
contract victim{
    uint public testVal;
    
     function subtractVal(uint x) payable external returns(uint){
        testVal -=  x;
        return testVal;
    }
    function addVal(uint x) payable external returns(uint){
        testVal += x;
        return testVal;
    }
}