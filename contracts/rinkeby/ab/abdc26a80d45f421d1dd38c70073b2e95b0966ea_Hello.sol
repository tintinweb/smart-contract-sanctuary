/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.4.24;
contract Hello {
    string public name;
    
    constructor() public {
        name = "我是一個智能合約！";
    }
    
    function setName(string _name) public {
        name = _name;
    }

    event SetNumber(string _from);
    
     function finction3 (string x) public returns(string){
        name = x;
        emit SetNumber(name);
        return name;
    }
}