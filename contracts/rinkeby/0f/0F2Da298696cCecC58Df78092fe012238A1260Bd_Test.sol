/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {
    
    uint256 private _balance;
    
    constructor () {
        _balance = 0;
    }
    
    function checkBalance() public view returns(uint256) {
        return _balance;
    }
    
    function deposit(uint256 amount) public {
        require(amount > 0, "amount less than zero");
        
        _balance += amount;
    }
    
    function withdraw(uint256 amount) public {
        require(amount <= _balance, "balance is not enough");
        
        _balance -= amount;
    }
}