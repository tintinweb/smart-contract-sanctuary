/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

pragma solidity ^0.4.26;
contract Hello {
    string public name;
    
    constructor() public {
        name = "我是一個智能合約！";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}