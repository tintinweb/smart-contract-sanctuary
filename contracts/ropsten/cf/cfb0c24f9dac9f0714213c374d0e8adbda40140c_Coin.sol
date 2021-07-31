/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Coin {
    
    address public minter;
    mapping(address => uint) public balances;
    
    error InsufficientBalance(uint requested, uint available);
    event Sent(address indexed from , address indexed to , uint indexed amount);
    
    constructor() {
        minter = msg.sender;
    }
    
    modifier onlyOwner {
        require(minter == msg.sender, 'Minter should be owner!');
        _;    
    }
    
    function mint(address receiver, uint _amount) onlyOwner public {
        balances[receiver] += _amount;
    }
    
    function send(address receiver, uint _amount) public {
        if(_amount > balances[msg.sender]) {
            revert InsufficientBalance({requested: _amount, available: balances[msg.sender]});
        }
         balances[msg.sender] -= _amount;
         balances[receiver] += _amount;
         emit Sent(msg.sender, receiver, _amount);
    }
    
  
}