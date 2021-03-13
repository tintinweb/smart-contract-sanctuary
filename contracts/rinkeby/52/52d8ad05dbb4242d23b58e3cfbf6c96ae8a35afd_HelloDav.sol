/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

pragma solidity ^0.4.24;

contract HelloDav {
    string public name;
    
    constructor() public {
        name = "我是一個智能合約！";
    }
    
    function setName(string _name) public {
        name = string(abi.encodePacked(name, _name));
    }
}