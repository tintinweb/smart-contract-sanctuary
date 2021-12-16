/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

pragma solidity ^0.4.24;
contract Hello {
    string public name;
    
    constructor() public {
        name = "我是一個智能合約123456！";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}