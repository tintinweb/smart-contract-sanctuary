/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

pragma solidity ^0.4.24;
contract Hello {
    string public name;
    
    constructor() public {
        name = "I love you three thousand！";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}