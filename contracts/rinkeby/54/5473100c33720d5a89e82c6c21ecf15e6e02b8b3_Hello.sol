/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;
contract Hello {
    string name;
    
    constructor() 
    {
        name = "I am a Smart Contract";
    }
    
    function setName(string memory _name) public {
        name = _name;
    }
}