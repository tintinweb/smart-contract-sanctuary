/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

pragma solidity ^0.4.24;
contract Hello {
    string public name;
    
    constructor() public {
        name = "106403523 ! ";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}