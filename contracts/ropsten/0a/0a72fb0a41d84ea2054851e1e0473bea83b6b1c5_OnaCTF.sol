/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; 


contract OnaCTF{
    bytes32 immutable public flag;
    uint16 f;
    uint16 l;
    uint16 a;
    uint16 g;
    
    
    constructor(){
        f++;
        l++;
        a++;
        g=f+l*l+a+g+a*f+a**l*l;
        flag = keccak256(abi.encodePacked(g));
    }
}