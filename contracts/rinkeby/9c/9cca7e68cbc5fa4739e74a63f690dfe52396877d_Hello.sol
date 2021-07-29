/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity ^0.4.26;
contract Hello {
    string public name;
    
    constructor() public {
        name = "smart contract b！";
    }
    
    function setName(string _name) public {
        name = _name;
    }
}