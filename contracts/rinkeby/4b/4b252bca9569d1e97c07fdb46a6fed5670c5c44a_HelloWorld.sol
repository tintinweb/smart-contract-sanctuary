/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

pragma solidity ^0.4.24;
contract HelloWorld {
    string public name;
    
    constructor() public {
        name = "HelloWorld";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}