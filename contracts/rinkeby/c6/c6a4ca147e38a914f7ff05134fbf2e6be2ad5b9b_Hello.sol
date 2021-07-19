/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity ^0.4.24;
contract Hello {
    string public name;
    
    constructor() public {
        name = "Eddie's first contract on rinkeby";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}