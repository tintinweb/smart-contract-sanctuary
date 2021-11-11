/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

contract GasFee {
    uint256 current;
    string public name;
    constructor() {
        name = "Test Deploy";
        current = 1000;
    }
    
    function pay() public payable{
        current -= msg.value;
    }
    
    function deposit(uint256 value) public returns(uint256)
    {
        current += value;
    }
    
    function getCurrent() public view returns(uint256)
    {
        return current;
    }
    
    function showFee() public view returns(uint256)
    {
        return gasleft() * tx.gasprice;
    }
}