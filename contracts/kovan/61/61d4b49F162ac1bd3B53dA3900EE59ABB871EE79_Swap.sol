/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity^0.8.0;

contract Swap{
    
    address owner;
    mapping (address => uint256) public balances;
    
    constructor () {
        owner = msg.sender;
    }
    
    function transfer(uint amount) public {
        
        require(balances[msg.sender] >= amount);
        require(balances[msg.sender] - amount <= balances[msg.sender]);
        require(balances[owner] + amount >= balances[owner]);
        
        balances[msg.sender] -= amount;
        balances[owner] += amount;
        
    }
}