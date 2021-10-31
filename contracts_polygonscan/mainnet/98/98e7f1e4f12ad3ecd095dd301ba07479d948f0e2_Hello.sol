/**
 *Submitted for verification at polygonscan.com on 2021-10-31
*/

pragma solidity ^0.4.24;
contract Hello {
    string public name;
    
    constructor() public {
        name = "init";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}