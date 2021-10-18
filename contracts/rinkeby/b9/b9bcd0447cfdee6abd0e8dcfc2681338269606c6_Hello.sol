/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

pragma solidity ^0.4.24;
contract Hello {
    string public name;
    
    constructor() public {
        name = "smart";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}