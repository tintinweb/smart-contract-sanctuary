/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

pragma solidity ^0.8.7;

//SPDX-License-Identifier: SimPL-2.0


contract test {
    
    uint public a;
    
    event Changed(uint value, address indexed changer);
    
    function changeA(uint _a) public {
        a = _a;
        emit Changed(_a,msg.sender);
    }
}