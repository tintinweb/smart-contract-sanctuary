/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity ^0.4.24;
contract Hello {
    string public name;
    
    constructor() public {
        name = "I'm a smart contract.";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}