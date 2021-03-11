/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

pragma solidity 0.8.0;

contract lastOne {
    string public name;
    uint8 public decimals;
    uint public totalSupply;
    
    constructor(uint _supply, uint8 _decimals, string memory _name) {
        name = _name;
        decimals = _decimals;
        totalSupply = _supply;
    }
}