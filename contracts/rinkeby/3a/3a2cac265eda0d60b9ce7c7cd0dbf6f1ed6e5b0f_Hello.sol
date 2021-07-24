/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

pragma solidity ^0.4.24;
contract Hello {
    string public name;
    
    constructor() public {
        name = "Hello world 智能合約！";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}