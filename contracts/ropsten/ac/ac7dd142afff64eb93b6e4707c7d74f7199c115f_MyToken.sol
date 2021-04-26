/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


contract MyToken {
    
    mapping (address => uint256) private balances;
    
    function getBalance(address _account) public returns (uint256) {
        return balances[_account];
    }

    function Token(uint256 _initialSupply) public {
        balances[msg.sender] = _initialSupply;
    }
    function transfer(address _to, uint256 _value) public {
        require(balances[msg.sender] >= _value);            // Check sufficient amount
        require(balances[_to] + _value >= balances[_to]);   // Avoid overflows
        balances[msg.sender] -= _value;
        balances[_to] += _value;
    }
}