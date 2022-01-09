/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Test{
    uint256 public totalSupply = 10000;
    string public _name = 'Test';
    
    constructor (string memory name){
        _name = name;

    }
    function mint() public payable{
        
        
    }
    function setName(string memory name) public{
        _name = name;
    }
}