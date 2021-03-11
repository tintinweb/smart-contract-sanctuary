/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

pragma solidity ^0.4.24;

contract ABItest {
    string public name;
    uint8 public decimals;
    uint public totalSupply;
    
    constructor(uint _supply, uint8 _decimals, string _name) public {
        name = _name;
        decimals = _decimals;
        totalSupply = _supply;
    }
}