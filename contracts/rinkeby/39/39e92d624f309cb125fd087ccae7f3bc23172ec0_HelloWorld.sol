/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

pragma solidity ^0.4.24;

contract HelloWorld {
    string public name;
    
    constructor() public {
        name = "Apple2";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}